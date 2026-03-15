# ============================================================
# Build-Installer.ps1
# Gathers plugin files and compiles the Inno Setup installer
# Run from: C:\Projects\obs-bg-removal\installer\
# ============================================================

param(
    [switch]$GatherOnly,   # Just gather files, don't compile
    [switch]$SkipBuild     # Skip cmake build, just package
)

$ErrorActionPreference = 'Stop'

# ---- Paths ----
$ProjectRoot   = "C:\Projects\obs-bg-removal"
$InstallerDir  = "$ProjectRoot\installer"
$FilesDir      = "$InstallerDir\files"
$OutputDir     = "$InstallerDir\output"
$ISSFile       = "$InstallerDir\obs-bg-removal-setup.iss"

$BuildDir      = "$ProjectRoot\build_x64"
$PluginDLL     = "$BuildDir\Release\shads-obs-bg-removal.dll"
$OnnxDepsDir   = "C:\Projects\deps\onnxruntime\lib"

# DirectML onnxruntime.dll - check multiple locations
$DirectMLDLL   = @(
    "C:\Projects\deps\onnxruntime\lib\onnxruntime.dll",
    "C:\Program Files\obs-studio\obs-plugins\64bit\onnxruntime.dll",
    "C:\Users\Shad3ious\Downloads\DirectML_Extract\runtimes\win-x64\native\onnxruntime.dll"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $DirectMLDLL) {
    Write-Host "ERROR: Cannot find onnxruntime.dll (DirectML build)" -ForegroundColor Red
    exit 1
}

$DataDir       = "$ProjectRoot\data"

# Inno Setup compiler (auto-detect)
$ISCC = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 5\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

# ---- Banner ----
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  OBS Background Removal - Installer Build" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ---- Step 1: Build plugin (unless skipped) ----
if (-not $SkipBuild) {
    Write-Host "[1/4] Building plugin..." -ForegroundColor Yellow
    Push-Location $ProjectRoot
    cmake --build build_x64 --config Release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build failed!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
    Write-Host "  Build OK" -ForegroundColor Green
} else {
    Write-Host "[1/4] Skipping build (--SkipBuild)" -ForegroundColor DarkGray
}

# ---- Step 2: Verify source files exist ----
Write-Host "[2/4] Verifying source files..." -ForegroundColor Yellow

$RequiredFiles = @{
    "Plugin DLL"           = $PluginDLL
    "ONNX Runtime (DML)"   = $DirectMLDLL
    "ONNX Providers"       = "$OnnxDepsDir\onnxruntime_providers_shared.dll"
    "Shader"               = "$DataDir\effects\mask.effect"
    "AI Model"             = "$DataDir\models\rvm_mobilenetv3_fp32.onnx"
    "Inno Setup Script"    = $ISSFile
}

$Missing = @()
foreach ($item in $RequiredFiles.GetEnumerator()) {
    if (Test-Path $item.Value) {
        $size = (Get-Item $item.Value).Length
        $sizeStr = if ($size -gt 1MB) { "{0:N1} MB" -f ($size/1MB) }
                   elseif ($size -gt 1KB) { "{0:N0} KB" -f ($size/1KB) }
                   else { "$size bytes" }
        Write-Host ("  OK  {0,-25} ({1})" -f $item.Key, $sizeStr) -ForegroundColor Green
    } else {
        Write-Host ("  MISSING  {0}" -f $item.Key) -ForegroundColor Red
        Write-Host ("           Expected: {0}" -f $item.Value) -ForegroundColor DarkGray
        $Missing += $item.Key
    }
}

if ($Missing.Count -gt 0) {
    Write-Host ""
    Write-Host "ERROR: $($Missing.Count) file(s) missing. Cannot build installer." -ForegroundColor Red
    exit 1
}

# ---- Step 3: Gather files ----
Write-Host "[3/4] Gathering files..." -ForegroundColor Yellow

# Clean and create directories
if (Test-Path $FilesDir) { Remove-Item $FilesDir -Recurse -Force }
New-Item -ItemType Directory -Path $FilesDir -Force | Out-Null
New-Item -ItemType Directory -Path "$FilesDir\effects" -Force | Out-Null
New-Item -ItemType Directory -Path "$FilesDir\models" -Force | Out-Null
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Copy files
Copy-Item $PluginDLL                                        "$FilesDir\shads-obs-bg-removal.dll"
Copy-Item $DirectMLDLL                                      "$FilesDir\onnxruntime.dll"
Copy-Item "$OnnxDepsDir\onnxruntime_providers_shared.dll"   "$FilesDir\onnxruntime_providers_shared.dll"
Copy-Item "$DataDir\effects\mask.effect"                    "$FilesDir\effects\mask.effect"
Copy-Item "$DataDir\models\rvm_mobilenetv3_fp32.onnx"       "$FilesDir\models\rvm_mobilenetv3_fp32.onnx"

# Generate placeholder icon if missing
$IconPath = "$InstallerDir\icon.ico"
if (-not (Test-Path $IconPath)) {
    Write-Host "  NOTE: No custom icon (icon.ico), installer will use default" -ForegroundColor DarkYellow
}

# Calculate total size
$TotalSize = (Get-ChildItem $FilesDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
Write-Host ("  Gathered {0:N1} MB in files\" -f ($TotalSize/1MB)) -ForegroundColor Green

if ($GatherOnly) {
    Write-Host ""
    Write-Host "Files gathered to: $FilesDir" -ForegroundColor Cyan
    Write-Host "Run Inno Setup Compiler on: $ISSFile" -ForegroundColor Cyan
    exit 0
}

# ---- Step 4: Compile installer ----
Write-Host "[4/4] Compiling installer..." -ForegroundColor Yellow

if (-not $ISCC) {
    Write-Host ""
    Write-Host "Inno Setup Compiler (ISCC.exe) not found!" -ForegroundColor Red
    Write-Host "Download from: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Files are gathered in: $FilesDir" -ForegroundColor Cyan
    Write-Host "You can compile manually by opening the .iss file in Inno Setup." -ForegroundColor Cyan
    exit 1
}

Write-Host "  Using: $ISCC" -ForegroundColor DarkGray

# Run Inno Setup compiler
Push-Location $InstallerDir
& $ISCC $ISSFile
$ExitCode = $LASTEXITCODE
Pop-Location

if ($ExitCode -ne 0) {
    Write-Host "ERROR: Inno Setup compilation failed (exit code $ExitCode)" -ForegroundColor Red
    exit 1
}

# ---- Done ----
$InstallerExe = Get-ChildItem "$OutputDir\*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Installer built successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
if ($InstallerExe) {
    $ExeSize = "{0:N1} MB" -f ($InstallerExe.Length / 1MB)
    Write-Host "  Output: $($InstallerExe.FullName)" -ForegroundColor Cyan
    Write-Host "  Size:   $ExeSize" -ForegroundColor Cyan
}
Write-Host ""
