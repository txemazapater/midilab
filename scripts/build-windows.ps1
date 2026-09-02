$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $projectRoot 'build/windows/x86_64'
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

if (-not (Get-Command lazbuild -ErrorAction SilentlyContinue)) {
    throw 'lazbuild was not found. Add the Lazarus directory to PATH.'
}

Push-Location $projectRoot
try {
    lazbuild --build-mode=Release 'src/app/midilab.lpi'
} finally {
    Pop-Location
}

Write-Host "Built $outputDir/MidiLab.exe"
