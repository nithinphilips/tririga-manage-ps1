#!/usr/bin/env pwsh
param(
    [string]$version="4.3.0",
    [switch]$updateModule,
    [switch]$noInstallModule,
    [switch]$publish,
    [switch]$PublishPSGallery,
    [string]$nuGetApiKey,
    [string]$releaseNoteFile
)

$modules = @("Tririga-Manage", "Tririga-Manage-Rest")

# Set active path to script-location:
$path = $MyInvocation.MyCommand.Path
if (!$path) {$path = $psISE.CurrentFile.Fullpath}
if ($path)  {$path = Split-Path $path -Parent}
Set-Location $path

# Check $Env:PSModulePath to see the default search locations
Function Update-ModuleManifestFilesForInstall() {
    param(
        [Parameter(Mandatory)]
        [string]$moduleName
    )

    $functionNames = Get-ChildItem $moduleName -Recurse | Where-Object { $_.Name -match ".*\.psm1" } -PipelineVariable file | ForEach-Object {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref] $null, [ref] $null)
        if ($ast.EndBlock.Statements.Name) {
            $ast.EndBlock.Statements.Name
        }
    }

    $functionNames = $functionNames | Where-Object { $_.Contains("-") }
    Write-Host "[$moduleName] Export functions: $functionNames"

    $modulePath = (Resolve-Path "$moduleName\$moduleName.psd1").Path

    $Params = @{
        Path = $modulePath
        FunctionsToExport = $functionNames
        ModuleVersion = $version
    }


    if($releaseNoteFile) {
        $Params["ReleaseNotes"] = (Get-Content $releaseNoteFile)
    }

    Update-ModuleManifest @Params
}

if($updateModule) {
    Write-Host "==> Update Module definition files"
    $modules | ForEach-Object { Update-ModuleManifestFilesForInstall $_ }
}

$profileDir = Split-Path $Profile -Parent
$moduleDir = Join-Path $profileDir "Modules"

if (!$noInstallModule) {
    Write-Host "==> Install Modules to $moduleDir"
    New-Item -Type Directory -Path $moduleDir -Force | Out-Null
    $modules | ForEach-Object { Copy-Item -Recurse -Force -Path $_ -Destination $moduleDir; Write-Host "Installed module $_" }

    Write-Host "==> Update Profile at $Profile"
    $environmentsFile = Join-Path $profileDir "environments.psd1"

    If (!(Test-Path -Path "$Profile") -or !(Select-String -Path "$Profile" -pattern "TririgaEnvironments"))
    {
        if (!(Test-Path -Path $environmentsFile)) {
            Copy-Item environments.sample.psd1 $environmentsFile
            Write-Host "A sample environments file has been placed at $environmentsFile. Edit to customize"
        }

        Write-Host "Installing this script to your PowerShell profile $Profile"
        "`$TririgaEnvironments = (Import-PowerShellDataFile `"$environmentsFile`")" | Out-file "$Profile" -append
        "`$DBeaverBin=`"$($env:UserProfile)\AppData\Local\DBeaver\dbeaver.exe`"" | Out-file "$Profile" -append
    } else {
        echo "Profile already configured"
    }
}

if ($publish) {
    if(!$nuGetApiKey) {
        Write-Error '-NugetApiKey is required when -Publish switch is set'
        exit 1
    }

    $modules | ForEach-Object { Publish-Module -Name $_\$_.psd1 -Repository Gitea -NuGetApiKey $nuGetApiKey; Write-Host "Published module $_" }
}


if ($publishPSgallery) {
    if(!$nuGetApiKey) {
        Write-Error '-NugetApiKey is required when -Publish switch is set'
        exit 1
    }

    $modules | ForEach-Object { Publish-Module -Name $_\$_.psd1 -NuGetApiKey $nuGetApiKey; Write-Host "Published module $_" }
}

