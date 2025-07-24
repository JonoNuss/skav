Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

$path = Join-Path $env:userprofile "CPAPbackground"

if (!(Test-Path $path)) {
    New-Item -ItemType Directory -Force -Path $path
}

$url = "https://i.ibb.co/Tj73Dds/Desktop-Wallpaper-2-1.jpg"
$output = Join-Path $path "background.jpg"

Start-BitsTransfer -Source $url -Destination $output

Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -Name Wallpaper -Value $output

$SPI_SETDESKWALLPAPER = 20
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDCHANGE = 0x02

[Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $output, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
