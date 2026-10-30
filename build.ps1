# Build dist\FigureTweak.exe (one file, no console window).
#   pwsh -File build.ps1 [-Python <python with pyinstaller and pillow>]
# CI (.github/workflows/release.yml) runs the same command on windows-latest.
param([string]$Python = "python")
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$src = "figuretweak"
$data = "figure_tweak.html", "figure_hub.html", "figure_hub_inject.js", "tweak.py", "figure_papers.json", "figure_hub.ico" |
    ForEach-Object { "--add-data"; "$src\$_;." }
$data += "--add-data", "$src\templates;templates"          # chart templates, their sample data and thumbnails
& $Python -m PyInstaller --noconfirm --clean --onefile --windowed --name FigureTweak `
    --icon "$src\figure_hub.ico" --paths $src @data `
    --exclude-module numpy --exclude-module matplotlib --exclude-module pandas `
    "$src\figure_hub.py"
if ($LASTEXITCODE) { exit $LASTEXITCODE }
Get-Item dist\FigureTweak.exe | Select-Object FullName, @{n = "MB"; e = { [math]::Round($_.Length / 1MB, 1) } }
