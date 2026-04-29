"""Conversion cache manager for deterministic file transformations."""

from __future__ import annotations

import hashlib
import json
import logging
import shutil
from pathlib import Path


class ConversionCache:
    """Per-workspace cache for deterministic conversion results."""

    def __init__(self, workspace: Path, cache_type: str = "conversions"):
        self.workspace = workspace
        self.cache_dir = workspace / ".cache" / cache_type
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    def cache_key(self, source_path: Path, target_format: str) -> str:
        """Generate deterministic key from source path and target format."""
        key_input = f"{source_path.resolve()}:{target_format}"
        return hashlib.sha256(key_input.encode("utf-8")).hexdigest()

    def _cache_paths(self, source_path: Path, target_format: str) -> tuple[Path, Path]:
        """Return cache result/meta paths for a source/target conversion."""
        key = self.cache_key(source_path, target_format)
        cache_file = self.cache_dir / f"{key}.result"
        meta_file = self.cache_dir / f"{key}.meta"
        return cache_file, meta_file

    def get(self, source_path: Path, target_format: str) -> Path | None:
        """Retrieve cached conversion result if metadata exists and is fresh."""
        cache_file, meta_file = self._cache_paths(source_path, target_format)

        if not source_path.exists() or not cache_file.exists() or not meta_file.exists():
            return None

        try:
            meta = json.loads(meta_file.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return None

        source_mtime = source_path.stat().st_mtime
        cached_source_mtime = float(meta.get("source_mtime", -1))

        if source_mtime > cached_source_mtime:
            return None

        if meta.get("target_format") != target_format:
            return None

        return cache_file

    def put(self, source_path: Path, target_format: str, result_path: Path):
        """Store conversion result and metadata in cache."""
        if not source_path.exists():
            raise FileNotFoundError(f"Source path not found: {source_path}")
        if not result_path.exists():
            raise FileNotFoundError(f"Result path not found: {result_path}")

        cache_file, meta_file = self._cache_paths(source_path, target_format)

        shutil.copy2(result_path, cache_file)

        meta = {
            "source_path": str(source_path.resolve()),
            "source_mtime": source_path.stat().st_mtime,
            "target_format": target_format,
            "cache_mtime": cache_file.stat().st_mtime,
        }
        meta_file.write_text(json.dumps(meta, indent=2), encoding="utf-8")

    def clear(self, source_path: Path | None = None):
        """Clear cache entries for a source path or wipe entire cache directory.

        Uses missing_ok=True for race-safe deletion and logs warnings for
        non-fatal filesystem errors.
        """
        if source_path is None:
            for path in self.cache_dir.glob("*"):
                if path.is_file():
                    try:
                        path.unlink(missing_ok=True)
                    except OSError as exc:
                        logging.warning("Failed to clear cache file %s: %s", path, exc)
            return

        source_str = str(source_path.resolve())
        for meta_file in self.cache_dir.glob("*.meta"):
            try:
                meta = json.loads(meta_file.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                continue

            if meta.get("source_path") != source_str:
                continue

            result_file = meta_file.with_suffix(".result")
            try:
                result_file.unlink(missing_ok=True)
                meta_file.unlink(missing_ok=True)
            except OSError as exc:
                logging.warning("Failed to clear cache for %s: %s", source_path, exc)
