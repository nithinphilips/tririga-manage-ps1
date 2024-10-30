param(
    [switch]$develop,
    [switch]$publish,
    [string]$version="3.0.0",
    [string]$nuGetApiKey
)

# Set active path to script-location:
$path = $MyInvocation.MyCommand.Path
if (!$path) {$path = $psISE.CurrentFile.Fullpath}
if ($path)  {$path = Split-Path $path -Parent}
Set-Location $path

# Check $Env:PSModulePath to see the default search locations

Function Update-Module() {
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
    Write-Host "Using functions: $functionNames"

    $modulePath = (Resolve-Path "$moduleName\$moduleName.psd1").Path

    $Params = @{
        Path = $modulePath
        FunctionsToExport = $functionNames
        ModuleVersion = $version
    }

    Update-ModuleManifest @Params
}

if ($develop -or $publish) {
    Write-Host "==> Update Module definition files"
    Update-Module "Tririga-Manage"
    Update-Module "Tririga-Manage-Rest"
}

$profileDir = Split-Path $Profile -Parent
$moduleDir = Join-Path $profileDir "Modules"

Write-Host "==> Install Modules to $moduleDir"
New-Item -Type Directory -Path $moduleDir -Force | Out-Null
Copy-Item -Recurse -Force -Path * -Destination $moduleDir

Write-Host "==> Update Profile at $Profile"
$thisFile = $MyInvocation.MyCommand.Path
if (!$thisFile) {$thisFile = $psISE.CurrentFile.Fullpath}
if ($thisFile)  {$path = Split-Path $thisFile -Parent}
$environmentsFile = Join-Path $path "environments.ps1"

# TODO: Copy environments.ps1 to profile dir (if not already one there) and source that.

If (!(Select-String -Path "$Profile" -pattern "TririgaEnvironments"))
{
    echo "Installing this script to your PowerShell profile $Profile"
    "`$TririgaEnvironments = (Get-Content `"$environmentsFile`" | Out-String | Invoke-Expression)" | Out-file "$Profile" -append
    "`$DBeaverBin=`"$($env:UserProfile)\AppData\Local\DBeaver\dbeaver.exe`"" | Out-file "$Profile" -append
} else {
    echo "Already configured"
}

if ($publish) {
    if(!$nuGetApiKey) {
        Write-Error '-NugetApiKey is required when -Publish switch is set'
        exit 1
    }

    Publish-Module -Name Tririga-Manage\Tririga-Manage.psd1 -Repository Gitea -Verbose -NuGetApiKey $nuGetApiKey
    Publish-Module -Name Tririga-Manage-Rest\Tririga-Manage-Rest.psd1 -Repository Gitea -Verbose -NuGetApiKey $nuGetApiKey
}

