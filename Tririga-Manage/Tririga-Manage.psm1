#!/usr/bin/env pwsh
#
# PowerShell commands to manage TRIRIGA instances on Windows Servers
#

$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = (Import-PowerShellDataFile -Path "$($script:ModuleRoot)\Tririga-Manage.psd1").ModuleVersion

# Tririga-Manage-Rest is published with a prefix
# Re-import it in this context without a prefix
Import-Module Tririga-Manage-Rest -Prefix "" -ErrorAction 'SilentlyContinue'

#$DBeaverBin="C:\Users\Nithin\AppData\Local\DBeaver\dbeaver.exe"

function GetConfiguration() {
    if (!$TririgaEnvironments) {
        throw "Module is not configured. Visit https://github.com/nithinphilips/tririga-manage-ps1/blob/main/README.rst#configuration for instructions."
    }
    $TririgaEnvironments
}

function GetTririgaInstances([string]$environment, [string]$instance = $null, [boolean]$warn = $true) {

    Write-Verbose "Search for environment $environment"
    $tririgaEnvironment = (GetConfiguration)[$environment]

    if (!$tririgaEnvironment) {
        Write-Error "The environment `"$environment`" was not found."
        Write-Error "Possible values are: $(((GetConfiguration).keys) -join ', ')"
        return
    }

    if ($warn -and $tririgaEnvironment.Warn) {
        Write-Warning "WARNING: You are making a change to a Production environment. You have 10 seconds to hit CTRL + C to stop."
        for ($i = 0; $i -le 100; $i = $i + 10 ) {
            Write-Progress -Activity "This will affect a PROD env. Hit Ctrl + C to stop" -Status "$(10 - ($i / 10)) seconds remaining" -PercentComplete $i
            Start-Sleep -Seconds 1
        }
    }

    if ($instance) {
        Write-Verbose "An instance filter is present. Search for instance $instance in environment $environment"
        $tririgaInstance = $tririgaEnvironment["Servers"][$instance]

        if (!$tririgaInstance) {
            Write-Error "The instance `"$instance`" was not found in the `"$environment`" environment"
            Write-Error "Possible values are: $(($tririgaEnvironment.Servers.keys) -join ', ')"
            return $null
        }

        $tririgaInstance["Instance"] = $instance
        $tririgaInstance["Environment"] = $environment

        return Write-Output @($tririgaInstance) -NoEnumerate
    } else {
        Write-Verbose "No instance filter present. Selecting all instances in environment $environment"
        ForEach($inst in $tririgaEnvironment.Servers.keys) {
            $tririgaInstance = $tririgaEnvironment["Servers"][$inst]
            $tririgaInstance["Instance"] = $inst
            $tririgaInstance["Environment"] = $environment
        }
        return Write-Output $tririgaEnvironment.Servers.Values -NoEnumerate
    }
}

function GetTririgaObjectMigrationInstance([string]$environment, [boolean]$warn = $true) {

    $instances = (GetTririgaInstances -environment $environment -instance $null -warn $False)

    try {
        if(Get-Command -Module Tririga-Manage-Rest -Name Get-AgentHost -ErrorAction 'SilentlyContinue') {
            Write-Verbose "Get-AgentHost command available. Trying to find the actual ObjectMigrationAgent server"
            $realOmAgentHost = Get-AgentHost -Environment $environment -Agent ObjectMigrationAgent
            if ($realOmAgentHost) {
                ForEach($inst in $instances) {
                    Write-Verbose "Check: $($inst["InstanceName"]) or $($inst["Instance"]) -eq $realOmAgentHost = $($inst["InstanceName"] -eq $realOmAgentHost -or $inst["Instance"] -eq $realOmAgentHost)"
                    if ($inst["InstanceName"] -eq $realOmAgentHost -or $inst["Instance"] -eq $realOmAgentHost) {
                        Write-Verbose "ObjectMigration agent for $environment actually runs on $($inst["Instance"])"
                        return $inst
                    }
                }
            }
        }
    } catch {
        Write-Verbose "Get-TririgaAgentHost command is not available."
    }

    Write-Verbose "Fallback to hard-coded ObjectMigrationAgent flag"
    ForEach($inst in $instances) {

        if ($inst["ObjectMigrationAgent"]) {
            Write-Verbose "Configuration indicates ObjectMigration for $environment is on $($inst["Instance"])"
            return $inst
        }
    }


    return $null
}

function GetUncPath($server, $path) {
    $adminPath = $path -replace '(.):', '$1$$'
    return "\\$server\$adminPath"
}

# https://stackoverflow.com/a/61520508/260740
function GetServiceUptime
{
  param(
    [string]$tririgaHost,
    [string]$Name
  )

  # Prepare name filter for WQL
  $Name = $Name -replace "\\","\\" -replace "'","\'" -replace "\*","%"

  # Fetch service instance
  $Service = Get-CimInstance -ComputerName $tririgaHost -ClassName Win32_Service -Filter "Name LIKE '$Name'"

  # Use ProcessId to fetch corresponding process
  $Process = Get-CimInstance -ComputerName $tririgaHost -ClassName Win32_Process -Filter "ProcessId = $($Service.ProcessId)"

  # Calculate uptime and return
  return (Get-Date) - $Process.CreationDate
}

function GetTririgaLogName($log) {
    $LogLookup = @{
        ''            = "server.log";
        'server'      = "server.log";
        'om'          = "ObjectMigration.log";
        'omp'         = "ObjectMigration.log";
        'security'    = "security.log";
        'performance' = "performance.log";
        'ant'         = "..\ant.log";
        'was-ant'     = "..\was-ant.log";
    }

    if($LogLookup.ContainsKey($log)){
        return $LogLookup[$log]
    } else {
        return $log
    }
}

function GetWasLogName($log) {
    $LogLookup = @{
        ''    = "SystemOut.log";
        'out' = "SystemOut.log";
        'err' = "SystemErr.log";
    }

    if($LogLookup.ContainsKey($log)){
        return $LogLookup[$log]
    } else {
        return $log
    }
}

function HandleOmp() {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$environment,
        [ValidateNotNullOrEmpty()]
        [string[]]$ompfiles,
        [string]$destinationPath,
        [boolean]$force,
        [boolean]$tailLog
    )

    $ompfilesExpanded = Get-ChildItem $ompfiles
    $instance = (GetTririgaObjectMigrationInstance -environment $environment -warn $False)

    if (!$instance) {
        Write-Error "Unable to find the ObjectMigration agent instance for $environment."
        Write-Error "Ensure that the 'ObjectMigrationAgent' property is set correctly in the environment configuation"
        return
    }

    if ($ompfilesExpanded.Count -gt 1) {
        if ($force -or $PSCmdlet.ShouldContinue("You are trying to upload $($ompfilesExpanded.Count) files.", "Would you like to continue?") ) {
            Write-Warning "Continuing even when are more than 5 files in the OMP list: $($ompfilesExpanded.Count)"
        } else {
            return
        }
    }

    ForEach($ompfile in $ompfilesExpanded) {
        $ompFullPath=Resolve-Path $ompfile
        $ompName=Split-Path $ompFullPath -leaf
        $tririgaRoot = GetUncPath -server $instance["Host"] -path $instance["Tririga"]
        $remoteOmpfile = Join-Path -Path "$tririgaRoot" -ChildPath "$ompName"
        $ompFolder = Join-Path -Path "$tririgaRoot" -ChildPath $destinationPath
        if ($PSCmdlet.ShouldProcess("$ompName -> $($instance["Environment"]).$($instance["Instance"]) at $ompFolder", "Upload")) {
            Write-Output "Upload $ompName -> $($instance["Environment"]) $($instance["Instance"]) at $ompFolder"
            Copy-Item -Path "$ompFullPath" -Destination "$tririgaRoot"
            Move-Item -Path "$remoteOmpfile" -Destination "$ompFolder"
        }
    }

    if($tailLog) {
        Get-Log -environment $instance["Environment"] -instance $instance["Instance"] -log "omp"
    }
}

<#
.SYNOPSIS
Gets all known environments
.DESCRIPTION
Gets a list of all known environment
#>
function Get-Environment() {
    [CmdletBinding()]
    param(
        # If set, the object is returned as-is.
        [switch]$raw = $false
    )

    if($raw) {
        (GetConfiguration)
    } else {
        Write-Output "Known environments are: $(((GetConfiguration).keys) -join ', ')"
    }
}

<#
.SYNOPSIS
Gets all known instances in a given environment
.DESCRIPTION
Gets a list of all known instances in a given environment
#>
function Get-Instance() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        # If omitted all environments and instances will be printed.
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # If set, the object is returned as-is.
        [switch]$raw = $false
    )

    $tririgaEnvironment = (GetConfiguration)[$environment]

    if ($tririgaEnvironment) {
        if ($raw) {
            $tririgaEnvironment
        } else {
            Write-Output "$environment environment: $(($tririgaEnvironment.Servers.keys) -join ', ')"
        }
    } else {
        if($raw) {
            (GetConfiguration)
        } else {
            ForEach($env in (GetConfiguration).keys) {
                $envItem = (GetConfiguration)[$env]
                Write-Output "$env environment: $(($envItem.Servers.keys) -join ', ')"
            }
        }
    }
}

<#
.SYNOPSIS
Get the current status of TRIRIGA service
.DESCRIPTION
Get the current status of TRIRIGA Windows service
#>
function Get-Service() {
    [Alias("Get-Status")]
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance,
        # The number of lines to print from server.log.
        [int]$tail = 5,
        # Shows disk status
        [switch]$disk
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance -warn $False)

    if ($instances) {
        ForEach($inst in $instances) {
            $tririgaInstName = $inst["Instance"]
            $tririgaEnvName = $inst["Environment"]
            $tririgaHost = $inst["Host"]
            $service = $inst["Service"]

            Write-Output -ForegroundColor black -BackgroundColor green "$tririgaEnvName $tririgaInstName"

            Write-Output -ForegroundColor yellow "Service Status"
            Invoke-Command -ComputerName $tririgaHost -ScriptBlock { Microsoft.PowerShell.Management\Get-Service "$($using:service)" | Select-Object Name,DisplayName,Status,StartType | Format-List  }

            Write-Output -ForegroundColor yellow "Uptime"
            GetServiceUptime -TririgaHost $tririgaHost -Name $service

            if ($disk) {
                # Print free disk size
                Write-Output -ForegroundColor yellow "Disk Status"
                Invoke-Command -ComputerName $tririgaHost -ScriptBlock { Get-PSDrive -PSProvider FileSystem | Format-Table }
            }

            # Print $tail lines from server.log
            Write-Output -ForegroundColor yellow "Tririga Log (last $tail lines)"
            $tririgaRoot = GetUncPath -server $inst["Host"] -path $inst["Tririga"]
            $logRoot = Join-Path -Path $tririgaRoot -ChildPath "log"
            $logPath = Join-Path -Path $logRoot -ChildPath (GetTririgaLogName "server")
            Get-Content -Tail $tail $logPath
        }
    }
}

<#
.SYNOPSIS
Starts TRIRIGA service
.DESCRIPTION
Starts a single TRIRIGA instance or all instances in an environment

If you run this against a production environment, a warning will be shown. There is a 10 second wait.
#>
function Start-Service() {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance)

    if ($instances) {
        if ($instances.Count -gt 1) {
            Write-Warning "All $environment instances will be started"
        }
        ForEach($inst in $instances) {
            $tririgaInstName = $inst["Instance"]
            $tririgaEnvName = $inst["Environment"]
            $tririgaHost = $inst["Host"]
            $service = $inst["Service"]

            Write-Output "Starting $tririgaEnvName $tririgaInstName"
            sc.exe \\$tririgaHost start "$service"

            if ($instances.Count -eq 1) {
                Get-Log -environment $inst["Environment"] -instance $inst["Instance"] -log $null
            }
        }
    }
}

<#
.SYNOPSIS
Stops TRIRIGA service
.DESCRIPTION
Stops a single TRIRIGA instance or all instances in an environment

If you run this against a production environment, a warning will be shown. There is a 10 second wait.
#>
function Stop-Service() {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance)

    if ($instances) {
        if ($instances.Count -gt 1) {
            Write-Warning "All $environment instances will be stopped"
        }
        ForEach($inst in $instances) {
            $tririgaInstName = $inst["Instance"]
            $tririgaEnvName = $inst["Environment"]
            $tririgaHost = $inst["Host"]
            $service = $inst["Service"]

            Write-Output "Stopping $tririgaEnvName $tririgaInstName"
            sc.exe \\$tririgaHost stop "$service"
        }
    }
}

<#
.SYNOPSIS
Restarts TRIRIGA service
.DESCRIPTION
Restarts a single TRIRIGA instance or all instances in an environment

If you run this against a production environment, a warning will be shown. There is a 10 second wait.
#>
function Restart-Service() {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance)

    if ($instances) {
        if ($instances.Count -gt 1) {
            Write-Warning "All $environment instances will be restarted"
            Start-Sleep -Seconds 1
        }
        ForEach($inst in $instances) {
            $tririgaInstName = $inst["Instance"]
            $tririgaEnvName = $inst["Environment"]
            $tririgaHost = $inst["Host"]
            $service = $inst["Service"]

            Write-Output "Restarting $tririgaEnvName $tririgaInstName"
            sc.exe \\$tririgaHost stop "$service"
            Write-Output "Waiting 30 seconds for the service to stop"
            Start-Sleep -Seconds 30
            sc.exe \\$tririgaHost start "$service"

            if ($instances.Count -gt 1) {
                Start-Sleep -Seconds 2
            } else {
                Get-Log -environment $inst["Environment"] -instance $inst["Instance"] -log $null
            }
        }
    }
}

<#
.SYNOPSIS
Disables TRIRIGA service
.DESCRIPTION
Disables TRIRIGA services. Disabled services will not start on server reboot.

If you run this against a production environment, a warning will be shown. There is a 10 second wait.
#>
function Disable-Service() {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance)

    if ($instances) {
        if ($instances.Count -gt 1) {
            Write-Warning "All $environment instances will be disabled"
        }
        ForEach($inst in $instances) {
            $tririgaInstName = $inst["Instance"]
            $tririgaEnvName = $inst["Environment"]
            $tririgaHost = $inst["Host"]
            $service = $inst["Service"]

            sc.exe \\$tririgaHost config "$service" start= demand
        }
    }
}

<#
.SYNOPSIS
Enables TRIRIGA service
.DESCRIPTION
Enables TRIRIGA services. Enabled services will start automatically on server reboot.

If you run this against a production environment, a warning will be shown. There is a 10 second wait.
#>
function Enable-Service() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance)

    if ($instances) {
        if ($instances.Count -gt 1) {
            Write-Warning "All $environment instances will be enabled"
        }
        ForEach($inst in $instances) {
            $tririgaInstName = $inst["Instance"]
            $tririgaEnvName = $inst["Environment"]
            $tririgaHost = $inst["Host"]
            $service = $inst["Service"]

            sc.exe \\$tririgaHost config "$service" start= auto
        }
    }
}

<#
.SYNOPSIS
Opens Dbeaver and connects to the TRIRIGA database
.DESCRIPTION
Opens DBeaver and connects to the given environment's database

The database connection profile must already exist. This command will only
connect to it and opens a new SQL sheet.
#>
function Open-Database() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # One or more SQL file to open.
        # Wild cards are supported. Eg: *.sql
        # Separate multiple files with a comma: one.sql,two.sql
        [Parameter(Position=1)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$sqlfiles
    )

    $tririgaEnvironment = (GetConfiguration)[$environment]

    if (!$tririgaEnvironment) {
        Write-Error "The environment `"$environment`" was not found."
        Write-Error "Possible values are: $(((GetConfiguration).keys) -join ', ')"
        return
    }

    if ($sqlfiles) {
        ForEach($sqlfile in $sqlFiles) {
            $realPath = (Resolve-Path $sqlfile).Path
            & $DBeaverBin -con "name=`"$($tririgaEnvironment.dbProfile)`"|create=false" -f $realPath
        }
    } else {
        & $DBeaverBin -con "name=`"$($tririgaEnvironment.dbProfile)`"|create=false|openConsole=true"
    }
}

<#
.SYNOPSIS
Tails a TRIRIGA log file
.DESCRIPTION
Tails a TRIRIGA log file in the console
#>
function Get-Log() {
    [Alias("Tail-Log")]
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance,
        # The log file to view. Default is server.log. Possible values are:
        # server, om, security, performance or the exact log file name
        [Parameter(Position=2)]
        [string]$log = $null,
        # The initial number of lines to tail.
        [int]$tail = 10
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance -warn $False)

    if ($instances) {
        ForEach($inst in $instances) {
            $tririgaRoot = GetUncPath -server $inst["Host"] -path $inst["Tririga"]
            $logRoot = Join-Path -Path $tririgaRoot -ChildPath "log"
            $logPath = Join-Path -Path $logRoot -ChildPath (GetTririgaLogName $log)
            Write-Verbose "Tailing $logPath"
            Get-Content -Tail $tail -Wait $logPath
        }
    }
}

<#
.SYNOPSIS
Opens a TRIRIGA log file
.DESCRIPTION
Opens a TRIRIGA log file in the default viewer
#>
function Open-Log() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance,
        # The log file to view. Default is server.log. Possible values are:
        # server, om, security, performance or the exact log file name
        [Parameter(Position=2)]
        [string]$log = $null
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance -warn $False)

    if ($instances) {
        ForEach($inst in $instances) {
            $tririgaRoot = GetUncPath -server $inst["Host"] -path $inst["Tririga"]
            $logRoot = Join-Path -Path $tririgaRoot -ChildPath "log"
            $logPath = Join-Path -Path $logRoot -ChildPath (GetTririgaLogName $log)
            Invoke-Item $logPath
        }
    }
}

<#
.SYNOPSIS
Starts a remote powershell session to a TRIRIGA instance
.DESCRIPTION
Starts a remote powershell session to a TRIRIGA instance using the Enter-PSSession command.
.LINK
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enter-pssession
#>
function Enter-Host() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        [Alias("Inst", "I")]
        [Parameter(Mandatory, Position=1)]
        [string]$instance
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance)

    if ($instances) {
        ForEach($inst in $instances) {
            Enter-PSSession -ComputerName $inst["Host"]
        }
    }
}

<#
.SYNOPSIS
Opens a TRIRIGA environment
.DESCRIPTION
Opens the TRIRIGA environment URL in your default browser
#>
function Open-Web() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance -warn $False)

    if ($instances) {
        ForEach($inst in $instances) {
            START $inst.Url
        }
    }
}

<#
.SYNOPSIS
Opens an RDP client connection to the TRIRIGA server
.DESCRIPTION
Launches the Microsoft Remote Desktop Connection tool with the server name pre-filled.
#>
function Open-RDP() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance -warn $False)

    if ($instances) {
        ForEach($inst in $instances) {
            Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$($inst["Host"])"
        }
    }
}

<#
.SYNOPSIS
Opens a TRIRIGA installation directory path
.DESCRIPTION
Opens a TRIRIGA installation directory path in your default file browser application
#>
function Open-Folder() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance -warn $False)

    if ($instances) {
        ForEach($inst in $instances) {
            $tririgaRoot = GetUncPath -server $inst["Host"] -path $inst["Tririga"]
            Invoke-Item $tririgaRoot
        }
    }
}

<#
.SYNOPSIS
Uploads a local OMP zip file to TRIRIGA
.DESCRIPTION
Uploads a local OMP zip file to TRIRIGA
.EXAMPLE
PS> Save-Omp DEV one.zip,two.zip
.EXAMPLE
PS> Save-Omp DEV *.zip
#>
function Save-Omp() {
    [Alias("Upload-Omp")]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        [Parameter(Mandatory, Position=1)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$ompfiles,
        [switch]$force
    )

    HandleOmp -Environment $environment -OmpFiles $ompfiles -DestinationPath "userfiles\\ObjectMigration\\Uploads" -Force $force -TailLog $false
}

<#
.SYNOPSIS
Uploads and imports a local OMP zip file to TRIRIGA
.DESCRIPTION
Uploads and imports a local OMP zip file to TRIRIGA
#>
function Import-Omp() {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        [Parameter(Mandatory, Position=1)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$ompfiles,
        [switch]$force
    )

    HandleOmp -Environment $environment -OmpFiles $ompfiles -DestinationPath "userfiles\\ObjectMigration\\UploadsWithImport" -Force $force -TailLog $true
}

<#
.SYNOPSIS
Opens a WebSphere profile path
.DESCRIPTION
Opens a WebSphere profile path in your default file browser application
#>
function Open-WasFolder() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance -warn $False)

    if ($instances) {
        ForEach($inst in $instances) {
            $wasRoot = GetUncPath -server $inst["Host"] -path $inst["WebSphere"]
            Invoke-Item $wasRoot
        }
    }
}

<#
.SYNOPSIS
Opens the WebSphere Admin Console
.DESCRIPTION
Opens the WebSphere Admin Console for a TRIRIGA environment in your default browser
#>
function Open-WasWeb() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance -warn $False)

    if ($instances) {
        ForEach($inst in $instances) {
            START $inst.WasUrl
        }
    }
}

<#
.SYNOPSIS
Tails a WebSphere log file
.DESCRIPTION
Tails a WebSphere log file in the console
#>
function Get-WasLog() {
    [Alias("Tail-WasLog")]
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance,
        # The log file to view. Default is SystemOut.log. Possible values are: out, err or the exact log file name
        [string]$log = $null,
        # The initial number of lines to tail.
        [int]$tail = 10
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance -warn $False)

    if ($instances) {
        ForEach($inst in $instances) {
            $wasRoot = GetUncPath -server $inst["Host"] -path $inst["WebSphere"]
            $logPath = Join-Path -Path $wasRoot -ChildPath (GetWasLogName $log)
            Get-Content -Tail $tail -Wait $logPath
        }
    }
}

<#
.SYNOPSIS
Opens a WebSphere log file
.DESCRIPTION
Opens a WebSphere log file in the default viewer
#>
function Open-WasLog() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance,
        # The log file to view. Default is SystemOut.log. Possible values are: out, err or the exact log file name
        [string]$log = $null
    )

    $instances = (GetTririgaInstances -environment $environment -instance $instance -warn $False)

    if ($instances) {
        ForEach($inst in $instances) {
            $wasRoot = GetUncPath -server $inst["Host"] -path $inst["WebSphere"]
            $logPath = Join-Path -Path $wasRoot -ChildPath (GetWasLogName $log)
            Invoke-Item $logPath
        }
    }
}
