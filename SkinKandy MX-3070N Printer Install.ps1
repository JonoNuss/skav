# =============================
# Sharp MX-3070N Printer Install
# =============================

# Configuration
[string]$PortName    = "HR&Compliance"
[string]$PrinterIP   = "192.168.11.90"
[string]$PrinterName = "HR & Compliance Printer"
[string]$DriverName  = "SHARP MX-3070N PCL6"

# Paths
$driverZipUrl  = "https://github.com/JonoNuss/skav/raw/main/MX_D54_PCL6_PS_2102a_EnglishUS_64bit.zip"
$basePath      = "C:\SharpDrivers"
$localZipPath  = "$basePath\Sharp3070NDriver.zip"
$extractPath   = "$basePath\Extracted3070N"

# Create folder structure
if (!(Test-Path -Path $extractPath)) {
    New-Item -Path $extractPath -ItemType Directory -Force | Out-Null
}

# Download driver ZIP
Write-Host "Downloading driver package..."
Invoke-WebRequest -Uri $driverZipUrl -OutFile $localZipPath

# Extract the ZIP
Write-Host "Extracting driver package..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($localZipPath, $extractPath)

# Locate INF file
$infPath = Get-ChildItem -Path $extractPath -Recurse -Filter "su0emenu.inf" | Select-Object -First 1
if (-not $infPath) {
    Write-Host "ERROR: su0emenu.inf not found in extracted content."
    exit 1
}

# Stage driver into DriverStore
Write-Host "Staging driver using pnputil..."
pnputil.exe /add-driver "`"$($infPath.FullName)`"" /install

# Register driver to make it visible to Add-Printer
Write-Host "Registering driver using PrintUI..."
$installDriverCmd = "rundll32 printui.dll,PrintUIEntry /ia /m `"$DriverName`" /f `"$($infPath.FullName)`""
Invoke-Expression $installDriverCmd

# Add printer port if missing
if (-not (Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating printer port: $PortName ($PrinterIP)"
    Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP
}

# Add printer if not already installed
if (-not (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue)) {
    Write-Host "Adding printer: $PrinterName"
    Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName
}

# Optional: set printer as default
# Set-Printer -Name $PrinterName -IsDefault $true

# Clean up downloaded ZIP file (keep extracted folder for reuse/debug)
Write-Host "Cleaning up downloaded ZIP..."
Remove-Item -Path $localZipPath -Force

Write-Host "✅ Printer '$PrinterName' installation completed."
