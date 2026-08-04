$path = $MyInvocation.MyCommand.Path
if (!$path) {$path = $psISE.CurrentFile.Fullpath}
if ($path)  {$path = Split-Path $path -Parent}
Set-Location $path

if (!$env:PSModulePath.Contains($path)) {
    Write-Output "==> Add to PSModulePath: $path"
    $env:PSModulePath = "$path" + [IO.Path]::PathSeparator + $env:PSModulePath
} else {
    Write-Output "==> PSModulePath already configured"
}
./Install.ps1 -UpdateModule -NoInstallModule

Write-Output "==> Import Module"
Import-Module Tririga-Manage-Rest -Force; Import-Module Tririga-Manage -Force
