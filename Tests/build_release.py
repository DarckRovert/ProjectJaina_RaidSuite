#!/usr/bin/env python3
"""
Tests/build_release.py
WoWPeru_RaidSuite — Generador de ZIP para releases.

Uso:
    python Tests/build_release.py [VERSION]

Ejemplo:
    python Tests/build_release.py v1.0.0

Si VERSION se omite, usa "dev".
El ZIP se genera en el directorio de trabajo actual.
"""

import sys
import zipfile
import pathlib

VERSION = sys.argv[1] if len(sys.argv) > 1 else "dev"

# Raíz del addon (un nivel arriba de Tests/)
BASE = pathlib.Path(__file__).parent.parent.resolve()
ADDON_NAME = "WoWPeru_RaidSuite"
OUT = pathlib.Path(f"{ADDON_NAME}_{VERSION}.zip")

EXCLUDE_DIRS  = {".git", ".github", "__pycache__", "Tests"}
EXCLUDE_FILES = {".gitignore", ".DS_Store", "Thumbs.db", "desktop.ini"}
EXCLUDE_EXTS  = {".bak", ".orig", ".tmp", ".pyc"}
EXCLUDE_DOCS  = {
    "AGENTS.md", "CONTRIBUTING.md", "GOVERNANCE.md",
    "SECURITY.md", "CODE_OF_CONDUCT.md",
    "ECOSYSTEM_REGISTRY.md", "MODULES_EXTRA.md",
}

included = []
excluded = []

with zipfile.ZipFile(OUT, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for path in sorted(BASE.rglob("*")):
        rel   = path.relative_to(BASE)
        parts = rel.parts

        if any(p in EXCLUDE_DIRS for p in parts):
            excluded.append(str(rel))
            continue
        if path.is_dir():
            continue
        if path.name in EXCLUDE_FILES or path.suffix.lower() in EXCLUDE_EXTS:
            excluded.append(str(rel))
            continue
        if path.name in EXCLUDE_DOCS:
            excluded.append(str(rel))
            continue

        arc_path = pathlib.Path(ADDON_NAME) / rel
        zf.write(path, arc_path)
        included.append(str(rel))

size_kb = OUT.stat().st_size / 1024
print(f"ZIP: {OUT}  ({size_kb:.1f} KB)")
print(f"Incluidos: {len(included)} archivos | Excluidos: {len(excluded)} archivos")
