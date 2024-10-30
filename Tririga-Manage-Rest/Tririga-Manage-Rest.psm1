#!/usr/bin/env pwsh
#
# PowerShell commands to manage TRIRIGA instances using the Admin REST API
#
# The commands allow you to refer to your instances by [Environment] [Instance] (eg: DEV NS1).
#
# Version: 1.0

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

function DumpJson() {
    param(
       [boolean]$raw = $false
    )

    Write-Verbose "Return as raw object"

    if ($raw) {
        return $input
    } else {
        if(HasPager) {
            Write-Verbose "Json to pager"
            $input | ConvertTo-Json -Depth 100 | bat --style plain --language json
        } else {
            Write-Verbose "Just print json"
            $input | ConvertTo-Json -Depth 100 | Out-Host
        }
    }
}

function DumpCsv() {
    param(
       [boolean]$raw = $false
    )

    Write-Verbose "Return as raw object"

    if ($raw) {
        return $input
    } else {
        if(HasPager) {
            Write-Verbose "CSV to pager"
            $input | ConvertTo-Csv | bat --style plain --language csv
        } else {
            Write-Verbose "Just print CSV"
            $input | ConvertTo-Csv | Out-Host
        }
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
        New-Variable -Name tririgaSessionTable -Value $sessionTable -Scope Script -Force
    }

    # TODO: The session might be stale, we need a way to check and invalidate $tririgaSession
    if(!$tririgaSession) {
        # https://thedavecarroll.com/powershell/how-i-implement-module-variables/
        $tririgaSession = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
        $tririgaSessionTable[$serverUrlBase] = $tririgaSession

        $loginResponseHeaders = @{}

        Write-Verbose "No active sessions found. Send Login request to $logonUrl"
        $loginResponse = Invoke-RestMethod -Method POST `
                -WebSession $tririgaSession `
                @proxyProps `
                -ContentType application/json `
                -Body ($loginData | ConvertTo-Json) `
                -Uri $logonUrl

        # -ResponseHeadersVariable loginResponseHeaders `
        # ResponseHeadersVariable param is not supported in PS 5:
        Write-Verbose ($loginResponseHeaders | ConvertTo-Json)

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
            Write-Verbose "Can't modify Cookies."
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

    $tririgaEnvironment = $TririgaEnvironments[$environment]

    if (!$tririgaEnvironment) {
        Write-Error "The environment `"$environment`" was not found."
        Write-Error "Possible values are: $(($TririgaEnvironments.keys) -join ', ')"
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

            $currentEnv = @{
                "Environment" = $environment
                "Instance" = $inst
            }

            # TODO: Only do this of the result is PSObject
            if (!$noTag) {
                $result = $result | Add-Member -PassThru tririgaEnvironment $currentEnv
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
function Get-TririgaBuildNumber() {
    param(
        # The TRIRIGA environment to use.
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$environment = $env:TRIRIGA_ENVIRONMENT,
        # The TRIRIGA instance within the environment to use. If omitted, all instanced will be queried.
        [Parameter(ValueFromPipelineByPropertyName=$true, Position=2)]
        [string]$instance = $env:TRIRIGA_INSTANCE,
        # If set, the response object is returned as-is. Otherwise it is converted to JSON text.
        [switch]$raw = $false
    )

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/buildNumber"
    }

    CallTririgaApi @apiCall | DumpJson -Raw $raw
}

<#
.SYNOPSIS
Gets basic information about a TRIRIGA instance
.DESCRIPTION
Gets basic information about a TRIRIGA instance

Uses the /api/v1/admin/summary method
.EXAMPLE
PS> Get-Tririga-Summary Local -Raw | Select-Object databaseConnection
databaseConnection
------------------
jdbc:oracle:thin:@localhost:1521/XEPDB1
#>
function Get-TririgaSummary() {
    param(
        # The TRIRIGA environment to use.
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$environment = $env:TRIRIGA_ENVIRONMENT,
        # The TRIRIGA instance within the environment to use. If omitted, all instanced will be queried.
        [Parameter(ValueFromPipelineByPropertyName=$true, Position=2)]
        [string]$instance = $env:TRIRIGA_INSTANCE,
        # If set, the response object is returned as-is. Otherwise it is converted to JSON text.
        [switch]$raw = $false
    )

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/summary"
        OnlyOnAnyOneInstance = $true
    }

    CallTririgaApi @apiCall | DumpJson -Raw $raw
}

<#
.SYNOPSIS
Gets TRIRIGA Agents configuration
.DESCRIPTION
Gets TRIRIGA Agents configuration

Uses the /api/v1/admin/agent/status method
#>
function Get-TririgaAgents() {
    param(
        # The TRIRIGA environment to use.
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$environment = $env:TRIRIGA_ENVIRONMENT,
        # If provided, only lists the given agent.
        [string]$agent,
        # If set, the response object is returned as-is. Otherwise it is converted to JSON text.
        [switch]$raw = $false
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

    CallTririgaApi @apiCall | DumpJson -Raw $raw
}

<#
.SYNOPSIS
Gets the configured host(s) for the given agent(s)
.DESCRIPTION
Gets the configured host(s) for the given agent(s)

Uses the /api/v1/admin/agent/status method
.EXAMPLE
PS> Get-Tririga-Agent-Host -Environment LOCAL -Agent WFAgent | ForEach-Object { Write-Host "WFAgent is configured on $_" }
WFAgent is configured on localhost
WFAgent is configured on somewhere
.EXAMPLE
PS> Get-Tririga-Agent-Host -Environment LOCAL -Agent WFAgent | ForEach-Object { Write-Host "WFAgent is running on $_" }
WFAgent is running on localhost
#>
function Get-TririgaAgentHost() {
    param(
        # The TRIRIGA environment to use.
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$environment = $env:TRIRIGA_ENVIRONMENT,
        # If provided, only lists the given agent.
        [Parameter(Mandatory)]
        [string]$agent,
        # Set the type of agent to query. Run 'Get-Tririga-Agents' to see a list of all possible agent types.
        [switch]$running
    )

    $agents = Get-TririgaAgents -Environment $environment -Agent $agent -Raw

    foreach ($property in $agents.PSObject.Properties)
    {
        if($running -and $property.Value.Status -ne "Running") { continue }
        $property.Value.hostname
    }
}


<#
.SYNOPSIS
Gets a list of users who can access the TRIRIGA Admin Console
.DESCRIPTION
Gets a list of users with access to the TRIRIGA Admin Console

Not all listed users have active access. They are in the Admin group an can be granted access.

Uses /api/v1/admin/users/list method
.EXAMPLE
PS> Get-Tririga-AdminUsers LOCAL -Active -Raw | Format-Table
userId fullName       username adminSummary
------ --------       -------- ------------
221931 System System  system           True
#>
function Get-TririgaAdminUsers() {
    param(
        # The TRIRIGA environment to use.
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$environment = $env:TRIRIGA_ENVIRONMENT,
        # If set, only show users with active access
        [switch]$active = $false,
        # If set, the response object is returned as-is. Otherwise it is converted to JSON text.
        [switch]$raw = $false
    )

    $apiCall = @{
        Environment = $environment
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/users/list"
        OnlyOnAnyOneInstance = $true
    }

    # TODO: Check all access attributes and create a new "allAccess" attribute

    if ($active) {
        CallTririgaApi @apiCall | Where-Object { $_.adminSummary -eq "True" } | select-object userId,fullName,username,adminSummary | DumpCsv -Raw $raw
    } else {
        CallTririgaApi @apiCall | select-object userId,fullName,username,adminSummary | DumpCsv -Raw $raw
    }
}

<#
.SYNOPSIS
Gets a list of currently logged in users
.DESCRIPTION
Gets a list of currently logged in users
#>
function Get-TririgaActiveUsers() {
    param(
        # The TRIRIGA environment to use.
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$environment = $env:TRIRIGA_ENVIRONMENT,
        # The TRIRIGA instance within the environment to use. If omitted, all instanced will be queried.
        [Parameter(ValueFromPipelineByPropertyName=$true, Position=2)]
        [string]$instance = $env:TRIRIGA_INSTANCE,
        # If set, the response object is returned as-is. Otherwise it is printed as a table.
        [switch]$raw = $false
    )

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/activeUsers/list"
    }

    $resultHash = (CallTririgaApi @apiCall | ConvertFrom-Json -AsHashTable)

    foreach($item in $resultHash)
    {
        # Only PS 7+
        #$item["lastTouch"] = (Get-Date -UnixTimeSeconds (([long]$item["lastTouchDateTime"]) / 1000) -AsUTC)

        $unixTime = (([long]$item["lastTouchDateTime"]) / 1000)
        $item["lastTouch"] = (([System.DateTimeOffset]::FromUnixTimeSeconds($unixTime)).DateTime).ToString("s")
    }

    if ($raw) {
        $resultHash
    } else {
        $resultHash `
        | Select-object userId,fullName,userAccount,loggedIn,ipAddress,lastTouch `
        | Format-Table
    }

}

<#
.SYNOPSIS
Stops a TRIRIGA agent
.DESCRIPTION
Stops a TRIRIGA agent

Uses the /api/v1/admin/agent/stop method
#>
function Stop-TririgaAgent() {
    param(
        # The TRIRIGA environment to use.
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$environment = $env:TRIRIGA_ENVIRONMENT,
        # The Agent to stop. All instances of the agent are stopped.
        [Parameter(Mandatory)]
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

        Write-Verbose "Operating on Agent: $agent ($agentHost) [$thisAgent]"

        # When the configuration is <ANY>, we can't tell what server is actually running the agent
        # Since it's usually seen with Vagrant, guess localhost
        if($agentHost -eq "<ANY>"){
            $agentHost = "localhost"
        }

        $stopApiCall = @{
            Environment = $environment
            Instance = $instance
            ApiMethod = "POST"
            ApiPath = "/api/v1/admin/agent/stop?agent=$agent&startOnHost=$agentHost&runningOnHost=$agentHost&startupId=$agentId"
            OnlyOnAnyOneInstance = $true
        }

        CallTririgaApi @stopApiCall | DumpJson
    }
}

<#
.SYNOPSIS
Starts a TRIRIGA agent
.DESCRIPTION
Starts a TRIRIGA agent

Uses the /api/v1/admin/agent/start method
#>
function Start-TririgaAgent() {
    param(
        # The TRIRIGA environment to use.
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$environment = $env:TRIRIGA_ENVIRONMENT,
        # The Agent to start. All instances of the agent are started.
        [Parameter(Mandatory)]
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

        Write-Verbose "Operating on Agent: $agent ($agentHost) [$agentId]"

        if($agentHost -eq "<ANY>"){
            $agentHost = "localhost"
        }

        $stopApiCall = @{
            Environment = $environment
            Instance = $instance
            ApiMethod = "POST"
            ApiPath = "/api/v1/admin/agent/start?agent=$agent&hostname=$agentHost&startupId=$agentId"
            OnlyOnAnyOneInstance = $true
        }

        CallTririgaApi @stopApiCall | DumpJson
    }
}

<#
.SYNOPSIS
Updates workflow instance recording setting
.DESCRIPTION
Updates workflow instance recording setting

Uses the /api/v1/admin/workflowAgentInfo/workflowInstance/update method
#>
function Set-TririgaWorkflowInstance() {
    param(
        # The TRIRIGA environment to use.
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$environment = $env:TRIRIGA_ENVIRONMENT,
        # The value to set. One of: ALWAYS, ERRORS_ONLY, PER_WORKFLOW_ALWAYS, PER_WORKFLOW_PRODUCTION, DATA_LOAD
        [Parameter(Mandatory)]
        [string]$value,
        # The instance to update. If omitted, all instances are updated.
        [string]$instance = $env:TRIRIGA_INSTANCE,
        # If set, the response object is returned as-is. Otherwise it is converted to JSON text.
        [boolean]$raw = $false
    )


    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "POST"
        ApiPath = "/api/v1/admin/workflowAgentInfo/workflowInstance/update?instanceName=$value"
    }

    CallTririgaApi @apiCall | DumpJson -Raw $raw

}

<#
.SYNOPSIS
Sets the workflow instance recording setting to ALWAYS
.DESCRIPTION
Sets the workflow instance recording setting to ALWAYS

Uses the /api/v1/admin/workflowAgentInfo/workflowInstance/update method
#>
function Enable-TririgaWorkflowInstance() {
    param(
        # The TRIRIGA environment to use.
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$environment = $env:TRIRIGA_ENVIRONMENT,
        # The instance to update. If omitted, all instances are updated.
        [string]$instance = $env:TRIRIGA_INSTANCE,
        # If set, the response object is returned as-is. Otherwise it is converted to JSON text.
        [switch]$raw = $false
    )

    Set-TririgaWorkflowInstance -Environment $environment -Value "ALWAYS" -Instance $instance -Raw $raw
}

<#
.SYNOPSIS
Sets the workflow instance recording setting to ERRORS_ONLY
.DESCRIPTION
Sets the workflow instance recording setting to ERRORS_ONLY

Uses the /api/v1/admin/workflowAgentInfo/workflowInstance/update method
#>
function Disable-TririgaWorkflowInstance() {
    param(
        # The TRIRIGA environment to use.
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [Parameter(Mandatory)]
        [string]$environment,
        # The instance to update. If omitted, all instances are updated.
        [string]$instance = $env:TRIRIGA_INSTANCE,
        # If set, the response object is returned as-is. Otherwise it is converted to JSON text.
        [switch]$raw = $false
    )

    Set-TririgaWorkflowInstance -Environment $environment -Value "ERRORS_ONLY" -Instance $instance -Raw $raw

}
