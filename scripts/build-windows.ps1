[CmdletBinding()]
param(
    [string]$PythonExecutable = "python",
    [string]$VenvPath = ".venv",
    [string]$DistPath = "dist/windows-launcher",
    [string]$BuildPath = "build/windows-launcher",
    [ValidateSet("cpu", "gpu")]
    [string]$Runtime = "cpu",
    [ValidateSet("onedir", "onefile")]
    [string]$Bundle = "onedir",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$VenvFullPath = Join-Path $RepoRoot $VenvPath
$DistFullPath = Join-Path $RepoRoot $DistPath
$BuildFullPath = Join-Path $RepoRoot $BuildPath
$RequirementsFile = Join-Path $RepoRoot "requirements/windows-build.txt"
$SpecFile = Join-Path $RepoRoot "pyinstaller/criticalmaas_launcher.spec"

function Invoke-Python {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & $PythonExecutable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $PythonExecutable $($Arguments -join ' ')"
    }
}

function Invoke-VenvPython {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & $VenvPython @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $VenvPython $($Arguments -join ' ')"
    }
}

Write-Host "Repository root: $RepoRoot"
Write-Host "Requested runtime profile: $Runtime"
Write-Host "Requested bundle mode: $Bundle"

if ($Clean) {
    foreach ($PathToRemove in @($DistFullPath, $BuildFullPath)) {
        if (Test-Path -LiteralPath $PathToRemove) {
            Write-Host "Removing $PathToRemove"
            Remove-Item -LiteralPath $PathToRemove -Recurse -Force
        }
    }
}

if (-not (Test-Path -LiteralPath $VenvFullPath)) {
    Write-Host "Creating virtual environment at $VenvFullPath"
    Invoke-Python -Arguments @("-m", "venv", $VenvFullPath)
}
else {
    Write-Host "Reusing virtual environment at $VenvFullPath"
}

$VenvPython = Join-Path $VenvFullPath "Scripts/python.exe"
if (-not (Test-Path -LiteralPath $VenvPython)) {
    throw "Expected virtualenv interpreter not found: $VenvPython"
}

Invoke-VenvPython -Arguments @("-m", "pip", "install", "--upgrade", "-r", $RequirementsFile)

New-Item -ItemType Directory -Force -Path $DistFullPath | Out-Null
New-Item -ItemType Directory -Force -Path $BuildFullPath | Out-Null

$env:CRITICALMAAS_BUNDLE_MODE = $Bundle
try {
    Invoke-VenvPython -Arguments @(
        "-m", "PyInstaller",
        "--noconfirm",
        "--clean",
        "--distpath", $DistFullPath,
        "--workpath", $BuildFullPath,
        $SpecFile
    )
}
finally {
    Remove-Item Env:CRITICALMAAS_BUNDLE_MODE -ErrorAction SilentlyContinue
}

$LauncherPath = if ($Bundle -eq "onefile") {
    Join-Path $DistFullPath "criticalmaas.exe"
} else {
    Join-Path $DistFullPath "criticalmaas/criticalmaas.exe"
}

if (-not (Test-Path -LiteralPath $LauncherPath)) {
    throw "Launcher executable not produced at expected path: $LauncherPath"
}

Write-Host "Built launcher: $LauncherPath"
Write-Host "Note: this launcher does not bundle model weights or unsupported Windows-native runtime stacks."
Write-Host "Prepare a Python environment with pipeline dependencies, then pass --python or set CRITICALMAAS_PYTHON when running pipeline/server commands."
