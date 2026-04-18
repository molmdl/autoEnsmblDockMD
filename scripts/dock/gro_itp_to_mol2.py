#!/usr/bin/env python3
"""Importable wrapper for 0_gro_itp_to_mol2.py.

This module exists to provide a clean import path:
    from scripts.dock.gro_itp_to_mol2 import convert
"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

_IMPL_PATH = Path(__file__).with_name("0_gro_itp_to_mol2.py")
_SPEC = importlib.util.spec_from_file_location("scripts.dock._gro_itp_to_mol2_impl", _IMPL_PATH)
if _SPEC is None or _SPEC.loader is None:
    raise ImportError(f"Unable to load converter implementation: {_IMPL_PATH}")

_MODULE = importlib.util.module_from_spec(_SPEC)
sys.modules[_SPEC.name] = _MODULE
_SPEC.loader.exec_module(_MODULE)

convert = _MODULE.convert

__all__ = ["convert"]
