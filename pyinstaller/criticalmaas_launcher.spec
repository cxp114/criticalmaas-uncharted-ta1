# -*- mode: python ; coding: utf-8 -*-
from pathlib import Path
import os
project_root = Path(os.environ.get("CRITICALMAAS_PROJECT_ROOT", Path.cwd())).resolve()
bundle_mode = os.environ.get("CRITICALMAAS_BUNDLE_MODE", "onedir").lower()
name = "criticalmaas"

repo_datas = []
for directory in ["cdr", "cdr_writer", "data", "pipelines", "schema", "tasks", "util"]:
    source = project_root / directory
    if source.exists():
        repo_datas.append((str(source), f"repo/{directory}"))

extra_datas = [
    (str(project_root / "README.md"), "."),
    (str(project_root / "LICENSE"), "."),
] + repo_datas

hiddenimports = ["criticalmaas_launcher", "criticalmaas_launcher.cli"]


a = Analysis(
    [str(project_root / "criticalmaas_launcher" / "cli.py")],
    pathex=[str(project_root)],
    binaries=[],
    datas=extra_datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

if bundle_mode == "onefile":
    exe = EXE(
        pyz,
        a.scripts,
        a.binaries,
        a.zipfiles,
        a.datas,
        [],
        name=name,
        debug=False,
        bootloader_ignore_signals=False,
        strip=False,
        upx=False,
        console=True,
    )
else:
    exe = EXE(
        pyz,
        a.scripts,
        [],
        exclude_binaries=True,
        name=name,
        debug=False,
        bootloader_ignore_signals=False,
        strip=False,
        upx=False,
        console=True,
    )
    coll = COLLECT(
        exe,
        a.binaries,
        a.zipfiles,
        a.datas,
        strip=False,
        upx=False,
        name=name,
    )
