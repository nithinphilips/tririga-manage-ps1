#!/usr/bin/env pwsh
#
# PowerShell commands to manage TRIRIGA instances using the Admin REST API
#

$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = (Import-PowerShellDataFile -Path "$($script:ModuleRoot)\Tririga-Manage-Rest.psd1").ModuleVersion

function GetConfiguration() {
    if (!$TririgaEnvironments) {
        throw "Module is not configured. Visit https://github.com/nithinphilips/tririga-manage-ps1/blob/main/README.rst#configuration for instructions."
    }
    $TririgaEnvironments
}

# From https://stackoverflow.com/a/76555554/260740
function GetAllCookiesFromWebRequestSession
{
   <#
         .SYNOPSIS
         Get all cookies stored in the WebRequestSession variable from any Invoke-RestMethod and/or Invoke-WebRequest request

         .DESCRIPTION
         Get all cookies stored in the WebRequestSession variable from any Invoke-RestMethod and/or Invoke-WebRequest request
         The WebRequestSession stores useful info and it has something that some my know as CookieJar or http.cookiejar.

         .PARAMETER WebRequestSession
         Specifies a variable where Invoke-RestMethod and/or Invoke-WebRequest saves values.
         Must be a valid [Microsoft.PowerShell.Commands.WebRequestSession] object!

         .EXAMPLE
         PS C:\> $null = Invoke-WebRequest -UseBasicParsing -Uri 'http://jhochwald.com' -Method Get -SessionVariable WebSession -ErrorAction SilentlyContinue
         PS C:\> $WebSession | Get-AllCookiesFromWebRequestSession

         Get all cookies stored in the $WebSession variable from the request above.
         This page doesn't use or set any cookies, but the (awesome) CloudFlare service does.

           .EXAMPLE
         $null = Invoke-RestMethod -UseBasicParsing -Uri 'https://jsonplaceholder.typicode.com/todos/1' -Method Get -SessionVariable RestSession -ErrorAction SilentlyContinue
         $RestSession | Get-AllCookiesFromWebRequestSession

         Get all cookies stored in the $RestSession variable from the request above.
         Please do not abuse the free API service above!

         .NOTES
         I used something I had stolen from Chrissy LeMaire's TechNet Gallery entry a (very) long time ago.
         But I needed something more generic, independent from the URL! This can become handy, to find any cookie from a 3rd party site or another host.

         .LINK
         https://docs.python.org/3/library/http.cookiejar.html

         .LINK
         https://en.wikipedia.org/wiki/HTTP_cookie

         .LINK
         https://gallery.technet.microsoft.com/scriptcenter/Getting-Cookies-using-3c373c7e

         .LINK
         Invoke-RestMethod

         .LINK
         Invoke-WebRequest
   #>

   [CmdletBinding(ConfirmImpact = 'None')]
   param
   (
      [Parameter(Mandatory,
         ValueFromPipeline,
         ValueFromPipelineByPropertyName,
         Position = 0,
         HelpMessage = 'Specifies a variable where Invoke-RestMethod and/or Invoke-WebRequest saves values.')]
      [ValidateNotNull()]
      [Alias('Session', 'InputObject')]
      [Microsoft.PowerShell.Commands.WebRequestSession]
      $WebRequestSession
   )

   begin
   {
      # Do the housekeeping
      $CookieInfoObject = $null
   }

   process
   {
      try
      {
         # I know, this look very crappy, but it just work fine!
         [pscustomobject]$CookieInfoObject = ((($WebRequestSession).Cookies).GetType().InvokeMember('m_domainTable', [Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::GetField -bor [Reflection.BindingFlags]::Instance, $null, (($WebRequestSession).Cookies), @()))
      }
      catch
      {
         #region ErrorHandler
         # get error record
         [Management.Automation.ErrorRecord]$e = $_

         # retrieve information about runtime error
         $info = [PSCustomObject]@{
            Exception = $e.Exception.Message
            Reason    = $e.CategoryInfo.Reason
            Target    = $e.CategoryInfo.TargetName
            Script    = $e.InvocationInfo.ScriptName
            Line      = $e.InvocationInfo.ScriptLineNumber
            Column    = $e.InvocationInfo.OffsetInLine
         }

         # output information. Post-process collected info, and log info (optional)
         $info | Out-String | Write-Verbose

         $paramWriteError = @{
            Message      = $e.Exception.Message
            ErrorAction  = 'Stop'
            Exception    = $e.Exception
            TargetObject = $e.CategoryInfo.TargetName
         }
         Write-Error @paramWriteError

         # Only here to catch a global ErrorAction overwrite
         exit 1
         #endregion ErrorHandler
      }
   }

   end
   {
      # Dump the Cookies to the Console
      ((($CookieInfoObject).Values).Values)
   }
}

function ConvertPSObjectToHashtable
{
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) { ConvertPSObjectToHashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject])
        {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = (ConvertPSObjectToHashtable $property.Value).PSObject.BaseObject
            }

            $hash
        }
        else
        {
            $InputObject
        }
    }
}

function HasPager() {
    $oldPreference = $ErrorActionPreference;
    $ErrorActionPreference = "stop";
    try {
        if(Get-Command "bat"){
            return $true
        }
    }
    catch {
        return $false
    }
    finally {
        $ErrorActionPreference=$oldPreference;
    }
}

function CallTririgaApiRaw() {
    param(
        [Parameter(Mandatory)]
        [string]$serverUrlBase,
        [string]$apiMethod = "GET",
        [Parameter(Mandatory)]
        [string]$apiPath,
        $apiBody,
        [Parameter(Mandatory)]
        [string]$username,
        [Parameter(Mandatory)]
        [string]$password,

        [boolean]$useProxy = $false,
        [string]$proxyUrl = "http://localhost:8080"
    )

    if ($input) {
        $apiBody = $input
    }

    if ($useProxy) {
        $proxyProps = @{
            Proxy = $proxyUrl
            ProxyUseDefaultCredentials = $true
        }
        [System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy($proxyUri, $true)
        [System.Net.WebRequest]::DefaultWebProxy.BypassProxyOnLocal = $false
    } else {
        $proxyProps = @{}
    }

    $logonUrl = "$serverUrlBase/p/websignon/signon"
    $apiUrl = "$serverUrlBase$apiPath"

    $loginData = @{
        "userName"=$username;
        "password"=$password;
        "normal"="false";
        "api"="true";
    }

    $tririgaSession = $null

    if($sessionTable) {
        $tririgaSession = $tririgaSessionTable[$serverUrlBase]
    } else {
        $sessionTable = @{}
        New-Variable -Name tririgaSessionTable -Value $sessionTable -Scope Script -Force -WhatIf:$false
    }

    # TODO: The session might be stale, we need a way to check and invalidate $tririgaSession
    if(!$tririgaSession) {
        # https://thedavecarroll.com/powershell/how-i-implement-module-variables/
        $tririgaSession = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
        $tririgaSessionTable[$serverUrlBase] = $tririgaSession

        #$loginResponseHeaders = @{}

        Write-Verbose "No active sessions found. Send Login request to $logonUrl"
        $loginResponse = Invoke-RestMethod -Method POST `
                -WebSession $tririgaSession `
                @proxyProps `
                -ContentType application/json `
                -Body ($loginData | ConvertTo-Json) `
                -Uri $logonUrl

        Write-Verbose $loginResponse

        # -ResponseHeadersVariable loginResponseHeaders `
        # ResponseHeadersVariable param is not supported in PS 5:
        #Write-Verbose ($loginResponseHeaders | ConvertTo-Json)

        # Ignore cookie Secure and HttpOnly attributes
        # GetAllCookies is not supported in .net framework 4.0 (used by PS 5). It's only in .NET 6+
        #ForEach($cookie in $session.Cookies.GetAllCookies()) {

        if($PSVersionTable.PSVersion.Major -gt 5) {
            Write-Verbose "Modify Cookies"
            ForEach($cookie in $tririgaSession.Cookies.GetAllCookies()) {
                $cookie.Secure = $false
                $cookie.HttpOnly = $false
                Write-Verbose $cookie
            }
        } else {
            $cookies = GetAllCookiesFromWebRequestSession $tririgaSession
            foreach ($cookie in $cookies)
            {
                $cookie.Secure = $false
                $cookie.HttpOnly = $false
                Write-Verbose $cookie
            }
            Write-Verbose "Modify Cookies (PS v5 method)"
        }
    } else {
        Write-Verbose "Active session found. Not logging in again"
    }

    if ($VerbosePreference) {
        Write-Verbose "Send $apiMethod request to $apiUrl"
        if($apiBody) {
            Write-Verbose "  with data: $($apiBody | ConvertTo-Json)"
        }
    }

    try {
        $response = Invoke-RestMethod -Method $apiMethod -WebSession $tririgaSession -ContentType application/json -Uri $apiUrl @proxyProps -Body $apiBody
        return $response
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 401) {
            Write-Error "Got HTTP 401 (unauthorized) error. Your session for $serverUrlBase may have expired. It has been reset. Please Try again."
            $tririgaSessionTable[$serverUrlBase] = $null
        }
    }
}

function CallTririgaApi() {
    param(
        [Parameter(Mandatory)]
        [string]$environment,
        [string]$instance = $null,
        [string]$apiMethod = "GET",
        $apiBody,
        [Parameter(Mandatory)]
        [string]$apiPath,
        # When no $instance is set, runs on any one instance
        [switch]$onlyOnAnyOneInstance = $false,
        [switch]$noTag = $false
    )

    if ($input) {
        $apiBody = $input
    }

    $tririgaEnvironment = (GetConfiguration)[$environment]

    if (!$tririgaEnvironment) {
        Write-Error "The environment `"$environment`" was not found."
        Write-Error "Possible values are: $(((GetConfiguration).keys) -join ', ')"
        return $null
    }

    if ($tririgaEnvironment) {
        ForEach($inst in $tririgaEnvironment.Servers.keys) {
            Write-Verbose "CallTririgaApiRaw: On $environment.$inst."

            # If $instance is set, run only on the given instance
            if($instance -and !($instance -eq $inst)) {
                Write-Verbose "Wanted: $instance, Got: $inst. Skip to next"
                continue
            }

            $tririgaInstance = $tririgaEnvironment["Servers"][$inst]
            $hostUrl = $tririgaInstance["ApiUrl"]
            if (!$hostUrl){
                $hostUrl = $tririgaInstance["Url"]
            }

            if (!$hostUrl) {
                Write-Error "Neither 'ApiUrl' nor 'Url' not set correctly for $environment.$inst"
                return $null
            }

            if (!$tririgaEnvironment.username) {
                Write-Error "Username property is not set for $environment environment"
                return $null
            }

            if (!$tririgaEnvironment.password) {
                Write-Error "Password property is not set for $environment environment"
                return $null
            }

            $result = CallTririgaApiRaw -serverUrlBase $hostUrl -apiMethod $apiMethod -apiPath $apiPath -apiBody $apiBody -username $tririgaEnvironment.username -password $tririgaEnvironment.password


            # TODO: Only do this of the result is PSObject
            if (!$noTag) {
                $result = $result | Add-Member -PassThru environment $environment | Add-Member -PassThru instance $inst
            }
            # Tag with environment info
            #$result = $result | Add-Member -PassThru environment $environment
            #$result = $result | Add-Member -PassThru instance $inst

            $result

            if (!$instance -and $onlyOnAnyOneInstance) {
                Write-Verbose "OnlyAnyOneInstance is set. Stop after the first one."
                break
            }
        }
    } else {
        return $null
    }
}

#
#
# Public Methods
#
#

<#
.SYNOPSIS
Gets TRIRIGA build number
.DESCRIPTION
Gets TRIRIGA build number

Uses the /api/v1/admin/buildNumber method
#>
function Get-BuildNumber() {
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

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/buildNumber"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Gets basic information about a TRIRIGA instance
.DESCRIPTION
Gets basic information about a TRIRIGA instance

Uses the /api/v1/admin/summary method
.EXAMPLE
PS> Get-Summary Local -Raw | Select-Object databaseConnection
databaseConnection
------------------
jdbc:oracle:thin:@localhost:1521/XEPDB1
#>
function Get-Summary() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on the first instance.
        [Alias("Inst", "I")]
        [string]$instance
    )

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/summary"
        OnlyOnAnyOneInstance = $true
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Gets TRIRIGA Agents configuration
.DESCRIPTION
Gets TRIRIGA Agents configuration

Uses the /api/v1/admin/agent/status method
#>
function Get-Agent() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on the first instance.
        [Alias("Inst", "I")]
        [string]$instance,
        # If provided, only lists the given agent.
        [Parameter(Position=1)]
        [string]$agent,
        # If set, only list agents that are running
        [switch]$running,
        # If set, only list agents that are not running
        [switch]$notRunning
    )

    $agentArg = ""
    if($agent) {
        $agentArg = "?agent=$agent"
    }

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/agent/status$agentArg"
        OnlyOnAnyOneInstance = $true
        NoTag = $true
    }

    $result = CallTririgaApi @apiCall

    foreach ($property in $result.PSObject.Properties)
    {
        if($running -and $property.Value.Status -ne "Running") { continue }
        if($notRunning -and $property.Value.Status -ne "Not Running") { continue }

        New-Object PSObject -Property @{
            "ID" = $property.Value.startupId;
            "Agent" = $property.Value.agent;
            "Hostname" = $property.Value.hostname;
            "Status" = $property.Value.status;
        };
    }
}

<#
.SYNOPSIS
Gets the configured host(s) for the given agent
.DESCRIPTION
Gets the configured host(s) for the given agent

Uses the /api/v1/admin/agent/status method
.EXAMPLE
PS> Get-AgentHost -Environment LOCAL -Agent WFAgent | ForEach-Object { Write-Host "WFAgent is configured on $_" }
WFAgent is configured on localhost
WFAgent is configured on somewhere
.EXAMPLE
PS> Get-AgentHost -Environment LOCAL -Agent WFAgent | ForEach-Object { Write-Host "WFAgent is running on $_" }
WFAgent is running on localhost
#>
function Get-AgentHost() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on the first instance.
        [Alias("Inst", "I")]
        [string]$instance,
        # Set the type of agent to query. Run 'Get-Agent' to see a list of all possible agent types.
        [Parameter(Mandatory, Position=1)]
        [string]$agent,
        # If set, only list the host when the agent is running
        [switch]$running,
        # If set, only list the host when the aget is not running
        [switch]$notRunning
    )

    $agentCall = @{
        Environment = $environment
        Instance = $instance
        Agent = $agent
        Running = $running
        NotRunning = $notRunning
    }

    Get-Agent @agentCall | ForEach-Object { $_.Hostname }
}


<#
.SYNOPSIS
Gets a list of users who can access the TRIRIGA Admin Console
.DESCRIPTION
Gets a list of users with access to the TRIRIGA Admin Console

Not all listed users have active access. They are in the Admin group an can be granted access.

Uses /api/v1/admin/users/list method
.EXAMPLE
PS> Get-TririgaAdminUser LOCAL | Where-Object fullaccess -eq True
userId fullaccess username fullName
------ ---------- -------- --------
221931       True system   System System
#>
function Get-AdminUser() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on the first instance.
        [Alias("Inst", "I")]
        [string]$instance
    )

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/users/list"
        OnlyOnAnyOneInstance = $true
    }

    CallTririgaApi @apiCall `
    | ForEach-Object { $_ | Add-Member -PassThru "fullaccess" ( `
        $_.adminSummary -and $_.adminUsers -and $_.agents -and $_.buildNumber -and `
        $_.caches -and $_.databaseInfo -and $_.databaseQueryTool -and $_.dataConnect -and `
        $_.errorLogs -and $_.javaInfo -and $_.licenses -and $_.maintenanceSchedule -and `
        $_.metadataAnalysis -and $_.performanceMonitor -and $_.platformLogging -and `
        $_.schedulerInfo -and $_.systemInfo -and $_.threadSettings -and $_.usersLoggedIn `
        -and $_.workflowAgentInfo -and $_.workflowEvents -and $_.workflowExecuting `
        -and $_.mustGatherTool ) } `
    | ForEach-Object { New-Object PSObject -Property @{ "userId" = $_.userId; "fullName" = $_.fullName; "username" = $_.username; "fullaccess" = $_.fullaccess; }; }

}

<#
.SYNOPSIS
Gets a list of currently logged in users
.DESCRIPTION
Gets a list of currently logged in users
.EXAMPLE
PS> Get-TririgaActiveUser LOCAL | ft
#>
function Get-ActiveUser() {
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
        # If set, the response object is returned as-is. Otherwise it is printed as a table.
        [switch]$raw = $false
    )

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/activeUsers/list"
    }

    $resultHash = (CallTririgaApi @apiCall).Replace('eMail', 'email1') | ConvertFrom-Json

    $now = Get-Date # -AsUTC Only in PS 7

    foreach($item in $resultHash)
    {
        # Only PS 7+
        #$item["lastTouch"] = (Get-Date -UnixTimeSeconds (([long]$item["lastTouchDateTime"]) / 1000) -AsUTC)

        $unixTime = (([long]$item.lastTouchDateTime) / 1000)
        $item | Add-Member lastTouch ((([System.DateTimeOffset]::FromUnixTimeSeconds($unixTime)).DateTime).ToString("s"))
        $item | Add-Member lastTouchDuration ("{0:dd}d:{0:hh}h:{0:mm}m:{0:ss}s" -f (New-TimeSpan –Start $item.lastTouch –End $now))
    }


    if($raw) {
        $resultHash
    } else {
        $resultHash | Select-Object userAccount,fullName,email,lastTouchDuration
    }

}

<#
.SYNOPSIS
Stops a TRIRIGA agent
.DESCRIPTION
Stops a TRIRIGA agent

Uses the /api/v1/admin/agent/stop method
#>
function Stop-Agent() {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on the first instance.
        [Alias("Inst", "I")]
        [string]$instance,
        # The Agent to stop. All instances of the agent are stopped.
        [Parameter(Mandatory, Position=1)]
        [string]$agent
    )

    $statusApiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/agent/status?agent=$agent"
        OnlyOnAnyOneInstance = $true
        NoTag = $true
    }

    $agentInfo = CallTririgaApi @statusApiCall | ConvertPSObjectToHashtable

    ForEach($agent in $agentInfo.Keys) {
        $thisAgent = $agentInfo[$agent]

        $agentHost = $thisAgent.hostname
        $agentId = $agent

        # When the configuration is <ANY>, we can't tell what server is actually running the agent
        # Since it's usually seen with Vagrant, guess localhost
        if($agentHost -eq "<ANY>"){
            $agentHost = "localhost"
        }

        if($PSCmdlet.ShouldProcess("$($thisAgent.agent) [$agent] on $agentHost", "Stop")){
            $stopApiCall = @{
                Environment = $environment
                Instance = $instance
                ApiMethod = "POST"
                ApiPath = "/api/v1/admin/agent/stop?agent=$agent&startOnHost=$agentHost&runningOnHost=$agentHost&startupId=$agentId"
                OnlyOnAnyOneInstance = $true
            }

            $result = CallTririgaApi @stopApiCall

            # Some values are in single-item arrays. Flatten it and replace the values
            $result `
            | Add-Member -PassThru "agent" ($result.agent -Join ",") -Force `
            | Add-Member -PassThru "agentname" $agent -Force `
            | Add-Member -PassThru "hostname" ($result.hostname -Join ",") -Force `
            | Add-Member -PassThru "status" ($result.status -Join ",") -Force
        }


    }
}

<#
.SYNOPSIS
Starts a TRIRIGA agent
.DESCRIPTION
Starts a TRIRIGA agent

Uses the /api/v1/admin/agent/start method
#>
function Start-Agent() {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on the first instance.
        [Alias("Inst", "I")]
        [string]$instance,
        # The Agent to start. All instances of the agent are started.
        [Parameter(Mandatory, Position=1)]
        [string]$agent
    )

    $statusApiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/agent/status?agent=$agent"
        OnlyOnAnyOneInstance = $true
        NoTag = $true
    }

    $agentInfo = CallTririgaApi @statusApiCall | ConvertPSObjectToHashtable

    ForEach($agent in $agentInfo.Keys) {
        $thisAgent = $agentInfo[$agent]

        $agentHost = $thisAgent.hostname
        $agentId = $agent

        if($agentHost -eq "<ANY>"){
            $agentHost = "localhost"
        }

        if($PSCmdlet.ShouldProcess("$($thisAgent.agent) [$agent] on $agentHost", "Start")){
            $startApiCall = @{
                Environment = $environment
                Instance = $instance
                ApiMethod = "POST"
                ApiPath = "/api/v1/admin/agent/start?agent=$agent&hostname=$agentHost&startupId=$agentId"
                OnlyOnAnyOneInstance = $true
            }

            $result = CallTririgaApi @startApiCall

            # Some values are in single-item arrays. Flatten it and replace the values
            $result `
            | Add-Member -PassThru "agent" ($result.agent -Join ",") -Force `
            | Add-Member -PassThru "agentname" $agent -Force `
            | Add-Member -PassThru "hostname" ($result.hostname -Join ",") -Force `
            | Add-Member -PassThru "status" ($result.status -Join ",") -Force
        }

    }
}

<#
.SYNOPSIS
Updates workflow instance recording setting
.DESCRIPTION
Updates workflow instance recording setting

Uses the /api/v1/admin/workflowAgentInfo/workflowInstance/update method
#>
function Set-WorkflowInstance() {
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
        [Parameter()]
        [string]$instance,
        # The value to set.
        [ValidateSet("ALWAYS", "ERRORS_ONLY", "PER_WORKFLOW_ALWAYS", "PER_WORKFLOW_PRODUCTION", "DATA_LOAD")]
        [Parameter(Mandatory, Position=1)]
        [string]$value
    )


    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "POST"
        ApiPath = "/api/v1/admin/workflowAgentInfo/workflowInstance/update?instanceName=$value"
    }

    $instanceLabel = "[All]"
    if($instance) { $instanceLabel = $instance }

    if($PSCmdlet.ShouldProcess("$environment.$instanceLabel")){
        CallTririgaApi @apiCall
    }
}

<#
.SYNOPSIS
Sets the workflow instance recording setting to ALWAYS
.DESCRIPTION
Sets the workflow instance recording setting to ALWAYS

Uses the /api/v1/admin/workflowAgentInfo/workflowInstance/update method
#>
function Enable-WorkflowInstance() {
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
        [Parameter()]
        [string]$instance
    )

    Set-WorkflowInstance -Environment $environment -Value "ALWAYS" -Instance $instance
}

<#
.SYNOPSIS
Sets the workflow instance recording setting to ERRORS_ONLY
.DESCRIPTION
Sets the workflow instance recording setting to ERRORS_ONLY

Uses the /api/v1/admin/workflowAgentInfo/workflowInstance/update method
#>
function Disable-WorkflowInstance() {
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
        [Parameter()]
        [string]$instance
    )

    Set-WorkflowInstance -Environment $environment -Value "ERRORS_ONLY" -Instance $instance
}


