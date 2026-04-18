#!/usr/bin/env python3
"""Importable wrapper for 4_dock2com_2.1.py utilities."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

_IMPL_PATH = Path(__file__).with_name("4_dock2com_2.1.py")
_SPEC = importlib.util.spec_from_file_location("scripts.dock._dock2com_2_1_impl", _IMPL_PATH)
if _SPEC is None or _SPEC.loader is None:
    raise ImportError(f"Unable to load implementation module: {_IMPL_PATH}")

_MODULE = importlib.util.module_from_spec(_SPEC)
sys.modules[_SPEC.name] = _MODULE
_SPEC.loader.exec_module(_MODULE)

parse_itp = _MODULE.parse_itp
parse_itp_section = _MODULE.parse_itp_section

__all__ = ["parse_itp", "parse_itp_section"]
