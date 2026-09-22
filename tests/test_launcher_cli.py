from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]


def run_cli(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-m", "criticalmaas_launcher.cli", *args],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )


def test_launcher_help_smoke() -> None:
    result = run_cli("--help")
    assert result.returncode == 0
    assert "Windows launcher" in result.stdout
    assert "pipeline" in result.stdout


def test_launcher_version_smoke() -> None:
    result = run_cli("--version")
    assert result.returncode == 0
    assert "criticalmaas-launcher 0.1.0" in result.stdout
