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

<#
.SYNOPSIS
Stores credential in an encrypted file
.DESCRIPTION
Gets a list of all known environment
#>
function Set-Credential() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$environment,
        [Parameter(Mandatory, Position=1)]
        [string]$username,
        [Parameter(Mandatory, Position=2)]
        [string]$password
    )

    $PasswordDir = "$env:LocalAppData\Tririga-Manage"
    $PasswordFile = "$env:LocalAppData\Tririga-Manage\$environment.xml"

    New-Item -Type Directory -Path $PasswordDir -Force | Out-Null

    $credential = $null

    if($PSVersionTable.PSVersion.Major -gt 5) {
        $credential = Get-Credential -UserName $Username
    } else {
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $credential = [PSCredential]::New($username, $securePassword)
    }

    $securePasswordPath = $PasswordFile
    $credential |  Export-Clixml -Path $PasswordFile

    Write-Host "Success! Encrypted credentials are stored in $PasswordFile"
}

<#
.SYNOPSIS
Gets Credential from an encrypted file
.DESCRIPTION
Gets Credential from an encrypted file
#>
function _GetCredential() {
    [CmdletBinding()]
    param(
        [string]$environment
    )

    $PasswordFile = "$env:LocalAppData\Tririga-Manage\$environment.xml"

    If (!(Test-Path $PasswordFile)) {
        throw "No credentials found for $environment. Please enter them by running the 'Set-TririgaCredential $environment' command."
    }

    Write-Verbose "Read credential from $PasswordFile"

    Import-Clixml -Path $PasswordFile
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
        [Parameter(ValueFromPipeline)]
        [object]$apiBody,
        [Parameter(Mandatory)]
        [string]$username,
        [Parameter(Mandatory)]
        [string]$password,
        [boolean]$useProxy = $false,
        [string]$proxyUrl = "http://localhost:8080"
    )

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

    if($tririgaSessionTable) {
        Write-Verbose "Session Table found"
        $tririgaSession = $tririgaSessionTable[$serverUrlBase]
    } else {
        Write-Verbose "Initialize Session table"
        $sessionTable = @{}
        # This is now failing to persist!
        New-Variable -Name tririgaSessionTable -Value $sessionTable -Scope Script -Force -WhatIf:$false -Confirm:$false
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
            Write-Verbose "  with data [$($apiBody.GetType())]: $apiBody"
        }
    }

    try {
        $response = Invoke-RestMethod -Method $apiMethod -WebSession $tririgaSession -ContentType application/json -Uri $apiUrl @proxyProps -Body ($apiBody | ConvertTo-Json)
        return $response
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 401) {
            Write-Error "Got HTTP 401 (unauthorized) error. Your session for $serverUrlBase may have expired. It has been reset. Please Try again."
            $tririgaSessionTable[$serverUrlBase] = $null
            $tririgaSession = $null
        }
    }
}

function CallTririgaApi() {
    param(
        [Parameter(Mandatory)]
        [string]$environment,
        [string]$instance = $null,
        [string]$apiMethod = "GET",
        [Parameter(Mandatory)]
        [string]$apiPath,
        [Parameter(ValueFromPipeline)]
        [object]$apiBody,
        # When no $instance is set, runs on any one instance
        [switch]$onlyOnAnyOneInstance = $false,
        [switch]$noTag = $false,
        [string]$operationLabel,
        [string]$targetLabel,
        [switch]$doNotConfirm
    )

    $tririgaEnvironment = (GetConfiguration)[$environment]

    $tririgaCredential = _GetCredential $environment

    $passwordPlain = ""

    if($PSVersionTable.PSVersion.Major -gt 5) {
        $passwordPlain = (ConvertFrom-SecureString $tririgaCredential.password -AsPlainText)
    } else {
        $passwordPlain = ([System.Net.NetworkCredential]::new("", $tririgaCredential.password).Password)
    }

    if (!$tririgaEnvironment) {
        Write-Error "The environment `"$environment`" was not found."
        Write-Error "Possible values are: $(((GetConfiguration).keys) -join ', ')"
        return $null
    }

    #if (!$operationLabel) { $operationLabel = $apiPath }

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

        $targetLabelInst = "$environment/$inst"
        if ($targetLabel) { $targetLabelInst = "$environment/$inst/$targetLabel" }

        if($doNotConfirm -or $PSCmdlet.ShouldProcess($targetLabelInst, $operationLabel)){
            $result = CallTririgaApiRaw -serverUrlBase $hostUrl -apiMethod $apiMethod -apiPath $apiPath -apiBody $apiBody -username $tririgaCredential.username -password $passwordPlain

            # TODO: Only do this of the result is PSObject
            if (!$noTag) {
                $result = $result | Add-Member -PassThru environment $environment | Add-Member -PassThru instance $inst
            }

            # Yield Result
            $result
        }

        if (!$instance -and $onlyOnAnyOneInstance) {
            Write-Verbose "OnlyAnyOneInstance is set. Stop after the first one."
            break
        }
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
Retrieves information about the TRIRIGA server.
.DESCRIPTION
Retrieves information about the TRIRIGA server.

Uses the /api/p/v1/server/info method
#>
function Get-ServerInformation() {
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
        ApiPath = "/api/p/v1/server/info"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Locks the TRIRIGA server
.DESCRIPTION
Locks the TRIRIGA server. No new logins will be possible.

Uses the /api/v1/admin/systemInfo/lockSystem method
#>
function Lock-System() {
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

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "POST"
        ApiPath = "/api/v1/admin/systemInfo/lockSystem"
        OperationLabel = "Lock"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Unlocks the TRIRIGA server
.DESCRIPTION
Unlocks the TRIRIGA server. No new logins will be possible.

Uses the /api/v1/admin/systemInfo/unlockSystem method
#>
function Unlock-System() {
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

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "POST"
        ApiPath = "/api/v1/admin/systemInfo/unlockSystem"
        OperationLabel = "Unlock"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Get the WebSphere Liberty server.xml file
.DESCRIPTION
Get the WebSphere Liberty server.xml file

Uses the /api/v1/admin/systemInfo/properties/serverXml method
.EXAMPLE
PS> Get-TririgaServerXml LOCAL
<server>
    ...
</server>
PS> (Get-TririgaServerXml LOCAL -Raw).server
description    : IBM TRIRIGA Application Platform
#comment       : { Enable features ,  HTTP Session timeout is invalidationTimeout, default of 1800 seconds }
featureManager : featureManager
httpEndpoint   : httpEndpoint
...
#>
function Get-ServerXml() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will run on one instance. Set -All switch to run on all instances.
        [Alias("Inst", "I")]
        [Parameter(Position=1)]
        [string]$instance,
        # By default the XML response is printed as text. Set this switch to get a PSObject instead
        [switch]$raw,
        # By default only one instance is queried. Set this switch to query all instances.
        [switch]$all
    )

    $fileEscaped = [System.Net.WebUtility]::UrlEncode($file)

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/systemInfo/properties/serverXml"
        OnlyOnAnyOneInstance = !$all
        NoTag = $true
    }

    $instanceLabel = "[One]"
    if($instance) { $instanceLabel = $instance }

    $serverXml = CallTririgaApi @apiCall

    if ($raw) {
        $serverXml
    } else {
        $sw = New-Object System.IO.StringWriter
        $writer = New-Object System.Xml.XmlTextWriter($sw)
        $writer.Formatting = [System.Xml.Formatting]::Indented
        $serverXml.WriteContentTo($writer)
        $sw.ToString()
    }
}

<#
.SYNOPSIS
Gets a setting in a TRIRIGA properties file
.DESCRIPTION
Gets a setting in a TRIRIGA properties file

Uses the /api/v1/admin/systemInfo/properties/list method
.INPUTS
An array of property names

.OUTPUTS
A PSCustomObject with properties from file.

The object will also have these 3 properties: environment, instance, file.

These allow you to pipe the output into Set-Property.

.EXAMPLE
PS> Get-TririgaProperty LOCAL
Reserve                            : N
USE_AUTO_COMPLETE_IN_SMART_SECTION : Y
...
file                               : TRIRIGAWEB
environment                        : LOCAL
instance                           : ONE
...

.EXAMPLE
PS> Get-TririgaProperty LOCAL -Instance ONE
Reserve                            : N
USE_AUTO_COMPLETE_IN_SMART_SECTION : Y
...
file                               : TRIRIGAWEB
environment                        : LOCAL
instance                           : ONE

.EXAMPLE
PS> Get-TririgaProperty LOCAL SSO
SSO         : N
file        : TRIRIGAWEB
environment : LOCAL
instance    : ONE

.EXAMPLE
PS> Get-TririgaProperty LOCAL SSO, SSO_REMOTE_USER
environment     : LOCAL
instance        : ONE
file            : TRIRIGAWEB
SSO             : N
SSO_REMOTE_USER : Y

.EXAMPLE
PS> @("SSO", "SSO_REMOTE_USER") | Get-TririgaProperty LOCAL
environment     : LOCAL
instance        : ONE
file            : TRIRIGAWEB
SSO             : N
SSO_REMOTE_USER : Y

.EXAMPLE
PS> Get-TririgaProperty LOCAL FRONT_END_SERVER, SSO | %  { $_.FRONT_END_SERVER = $_.FRONT_END_SERVER.replace("http", "https"); $_ } | Set-TririgaProperty
environment      : LOCAL
instance         : ONE
file             : TRIRIGAWEB
FRONT_END_SERVER : https://localhost:9080/
SSO              : N


#>
function Get-Property() {
    [CmdletBinding()]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances
        [Alias("Inst", "I")]
        [Parameter()]
        [string]$instance,
        # The properties file to load (without the .properties extension)
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$file="TRIRIGAWEB",
        # Name of a single property to set
        [Parameter(Position=1, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$property
    )

    $fileEscaped = [System.Net.WebUtility]::UrlEncode($file)

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/systemInfo/properties/list?f=$fileEscaped"
    }

    $result = CallTririgaApi @apiCall | Add-Member -PassThru "file" $file

    if ($property) {
        $propertyFilter = @("environment", "instance", "file") + $property
        $result | Select-Object $propertyFilter
    } else {
        $result
    }
}

<#
.SYNOPSIS
Sets settings in a TRIRIGA properties file
.DESCRIPTION
Sets settings in a TRIRIGA properties file

Uses the /api/v1/admin/systemInfo/properties/update method
.INPUTS
A hashtable with the properties and values to set

A PSObject with the properties and values to set and environment, instance and file properties.
.OUTPUTS
A PSCustomObject with changed properties

The object will also have these 3 properties: environment, instance, file.

NOTE: In some platform versions, the output may not reflect the change you made
      until you restart the service.

.EXAMPLE
PS> Set-TririgaProperty LOCAL SSO N
environment instance file       SSO
----------- -------- ----       ---
LOCAL       ONE      TRIRIGAWEB N

.EXAMPLE
PS> @{ "SSO" = "N" } | Set-TririgaProperty LOCAL
environment     : LOCAL
instance        : ONE
file            : TRIRIGAWEB
SSO             : N

.EXAMPLE
PS> @{ "SSO" = "N"; "SSO_REMOTE_USER" = "Y" } | Set-TririgaProperty LOCAL
environment     : LOCAL
instance        : ONE
file            : TRIRIGAWEB
SSO_REMOTE_USER : Y
SSO             : N

.EXAMPLE
PS> Get-TririgaProperty LOCAL FRONT_END_SERVER, SSO | %  { $_.FRONT_END_SERVER = $_.FRONT_END_SERVER.replace("http", "https"); $_ } | Set-TririgaProperty
environment      : LOCAL
instance         : ONE
file             : TRIRIGAWEB
FRONT_END_SERVER : https://localhost:9080/
SSO              : N

.EXAMPLE
PS> [pscustomobject]@{ "environment"= "LOCAL"; "instance"= "ONE"; "file"= "TRIRIGAWEB"; "FRONT_END_SERVER"= "http://localhost:9080/"; "SSO"= "N"; } | Set-TririgaProperty
environment      : LOCAL
instance         : ONE
file             : TRIRIGAWEB
FRONT_END_SERVER : http://localhost:9080/
SSO              : N

#>
function Set-Property() {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The TRIRIGA environment to use.
        [Parameter(Position=0, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [Alias("Env", "E")]
        [string]$environment,
        # The TRIRIGA instance within the environment to use.
        # If omitted, command will act on all instances.
        [Alias("Inst", "I")]
        [Parameter(ValueFromPipelineByPropertyName )]
        [string]$instance,
        # The properties file to load (without the .properties extension)
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$file="TRIRIGAWEB",
        # Name of a single property to set
        [Parameter(ParameterSetName='SingleProperty', Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$property,
        # Value of a single property to set
        [Parameter(ParameterSetName='SingleProperty', Position=2)]
        [ValidateNotNullOrEmpty()]
        [string]$value,
        # An object with multiple properties
        [Parameter(ValueFromPipeline, ParameterSetName = 'PropertyObject')]
        [object]$propertyObject,
        # If set, the entire property file after the update is printed.
        # Otherwise, only the changes properties are printed
        [switch]$full
    )

    Process {

        $fileEscaped = [System.Net.WebUtility]::UrlEncode($file)

        if(!$propertyObject) {
            if(!$property -or !$value) {
            throw "You must set one of -Property and -Value OR -PropertyObject"
            }

            $propertyObject = @{
                "$property" = "$value"
            }

            #$MyJsonVariable = $MyJsonHashTable | ConvertTo-Json
            Write-Verbose "Construct propertyObject: $property = $value"
        } else {
            # Remove non TRIRIGA properties (not strictly required, tririga will ignore these, but do it anyways)
            # Works for hashtable and psobject
            $propertyObject = $propertyObject | Select-Object -Property * -ExcludeProperty environment, instance, file
            Write-Verbose "Remove environment, instance, file from propertyObject"
        }

        $properties = @()
        if($propertyObject -is [PSObject]) {
            $properties = $propertyObject.PSObject.Properties | ForEach-Object { $_.Name }
        } else {
            $properties = $propertyObject.keys | ForEach-Object { "$_" }
        }
        $propertyFilter = @("environment", "instance", "file") + $properties

        Write-Verbose "Using filter: $propertyFilter"

        $apiCall = @{
            Environment = $environment
            Instance = $instance
            ApiMethod = "PUT"
            ApiPath = "/api/v1/admin/systemInfo/properties/update?f=$fileEscaped"
            ApiBody = $propertyObject
            OperationLabel = "Set Property [$properties]"
        }

        CallTririgaApi @apiCall | Add-Member -PassThru "file" $file | Select-Object $propertyFilter
    }
}

function ResolveLogCategoryDescriptions() {
    [CmdletBinding()]
    param(
        [string]$environment,
        [string]$instance,
        [string[]]$category
    )

    # Lookup category name from the given description
    $lookupApiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/platformLogging/list"
        OnlyOnAnyOneInstance = $true
        DoNotConfirm = $true
    }

    $loggingCategories = CallTririgaApi @lookupApiCall

    #$loggingCategories

    $categoryIds = @()

    foreach($categoryItem in $category) {
        Write-Verbose "Search for $categoryItem"
        $categoryIds += ($loggingCategories | Where-Object -Property description -Eq $categoryItem)
    }

    return $categoryIds
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
        [string]$instance,
        # By default only one instance is queried. Set this switch to query all instances.
        [switch]$all
    )

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/summary"
        OnlyOnAnyOneInstance = !$all
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
        [switch]$raw,
        # If set, and not $raw, only print unique users no matter how many sessions they have
        [switch]$unique
    )

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/activeUsers/list"
    }

    $resultHash = (CallTririgaApi @apiCall).Replace('eMail', 'email1') | ConvertFrom-Json

    # If no -Instance value, then $resultHash is an array of array. Otherwise it is an array of objects.
    # Unroll array of arrays into an array of objects.
    if(!$instance) {
        $newResultHash = @()
        $resultHash | ForEach-Object { $newResultHash += $_ }
        $resultHash = $newResultHash
    }

    $now = Get-Date # -AsUTC Only in PS 7

    foreach($item in $resultHash)
    {
        # Only PS 7+
        #$item["lastTouch"] = (Get-Date -UnixTimeSeconds (([long]$item["lastTouchDateTime"]) / 1000) -AsUTC)

        $unixTime = (([long]$item.lastTouchDateTime) / 1000)
        $item | Add-Member lastTouch ((([System.DateTimeOffset]::FromUnixTimeSeconds($unixTime)).DateTime).ToString("s"))
        $item | Add-Member lastTouchDuration ("{0:dd}d:{0:hh}h:{0:mm}m:{0:ss}s" -f (New-TimeSpan -Start $item.lastTouch -End $now))
    }


    if($raw) {
        $resultHash
    } else {
        if ($unique) {
            $resultHash | Sort-Object -Property userAccount -Unique | Select-Object userAccount,fullName,email,lastTouchDuration
        } else {
            $resultHash | Select-Object userAccount,fullName,email,lastTouchDuration
        }
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
        DoNotConfirm = $true
    }

    # TODO: Avoid conversion. ConvertPSObjectToHashtable could infinite loop.
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

        $stopApiCall = @{
            Environment = $environment
            Instance = $instance
            ApiMethod = "POST"
            ApiPath = "/api/v1/admin/agent/stop?agent=$agent&startOnHost=$agentHost&runningOnHost=$agentHost&startupId=$agentId"
            OnlyOnAnyOneInstance = $true
            OperationLabel = "Stop Agent"
            TargetLabel = "$($thisAgent.agent) [$agent] on $agentHost"
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
        DoNotConfirm = $true
    }

    $agentInfo = CallTririgaApi @statusApiCall | ConvertPSObjectToHashtable

    ForEach($agent in $agentInfo.Keys) {
        $thisAgent = $agentInfo[$agent]

        $agentHost = $thisAgent.hostname
        $agentId = $agent

        if($agentHost -eq "<ANY>"){
            $agentHost = "localhost"
        }

        $startApiCall = @{
            Environment = $environment
            Instance = $instance
            ApiMethod = "POST"
            ApiPath = "/api/v1/admin/agent/start?agent=$agent&hostname=$agentHost&startupId=$agentId"
            OnlyOnAnyOneInstance = $true
            OperationLabel = "Start Agent"
            TargetLabel = "$($thisAgent.agent) [$agent] on $agentHost"
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
        OperationLabel = "Set WorkflowInstance=$value"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Sets the workflow instance recording setting to ALWAYS
.DESCRIPTION
Sets the workflow instance recording setting to ALWAYS

Uses the /api/v1/admin/workflowAgentInfo/workflowInstance/update method
#>
function Enable-WorkflowInstance() {
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
        [string]$instance
    )

    Set-WorkflowInstance -Environment $environment -Value "ERRORS_ONLY" -Instance $instance
}

<#
.SYNOPSIS
Write a message to TRIRIGA Log file
.DESCRIPTION
Write a message to TRIRIGA Log file

Uses the /api/v1/admin/platformLogging/write method
#>
function Write-LogMessage() {
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
        [Parameter(Mandatory, ValueFromPipeline, Position=1)]
        [string]$message
    )

    $messageEscaped = [System.Net.WebUtility]::UrlEncode($message)

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "POST"
        ApiPath = "/api/v1/admin/platformLogging/write?message=$messageEscaped"
        OperationLabel = "Write To Log"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Reload logging categories from disk
.DESCRIPTION
Reload logging categories from disk

Uses the /api/v1/admin/platformLogging/reload method
#>
function Sync-PlatformLogging() {
    [Alias("Reload-PlatformLogging")]
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
        [string]$instance
    )

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/platformLogging/reload"
        OperationLabel = "Sync Log Categories"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Reset duplicate categories
.DESCRIPTION
Reset duplicate categories

Uses the /api/v1/admin/platformLogging/resetDuplicates method
#>
function Reset-PlatformLoggingDuplicates() {
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
        [string]$instance
    )

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/platformLogging/resetDuplicates"
        OperationLabel = "Reset Log Duplicates"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Gets information about TRIRIGA platform Logging
.DESCRIPTION
Enables TRIRIGA platform Logging for the given categories

Uses the /api/v1/admin/platformLogging/list method
#>
function Get-PlatformLogging() {
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
        [string]$instance,
        # If set, only shows categories that have logging currently enabled
        [switch]$enabled,
        # The maximum level to show. Set to higher number (like 99) to see all levels.
        [int]$level = 1
    )

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/platformLogging/list"
        DoNotConfirm = $true
    }

    if ($enabled) {
        CallTririgaApi @apiCall | Where-Object -Property checkedStatus -eq "CHECKED" | Where-Object -Property level -le $level
    } else {
        CallTririgaApi @apiCall | Where-Object -Property level -le $level
    }
}

<#
.SYNOPSIS
Add a new platform logging category and level
.DESCRIPTION
Add a new platform logging category and level

Note: Not sure what this API does.

Uses the /api/v1/admin/platformLogging/debug/manual method
#>
function Add-PlatformLoggingCategory() {
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
        # One or more categories to enable
        [Parameter(Mandatory, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string[]]$category,
        # The log level to set for the category
        [string]$level
    )

    #TODO: THis has no effect. Not sure what the correct values to pass are
    #$categoryObjects = ResolveLogCategoryDescriptions -Environment $environment -Instance $instance -Category $category

    #foreach($categoryObject in $categoryObjects) {
    foreach($categoryName in $category) {

        #$categoryName = $categoryObject.Name.split(".")[-1]
        $categoryNameEscaped = [System.Net.WebUtility]::UrlEncode($categoryName)

        $apiCall  = @{
            Environment = $environment
            Instance = $instance
            ApiMethod = "POST"
            ApiPath = "/api/v1/admin/platformLogging/debug/manual?categoryPackage=$categoryNameEscaped&level=$level"
            OperationLabel = "Add Platform Logging Category"
        }

        #CallTririgaApi @apiCall | Add-Member -PassThru category $categoryObject.Description
        CallTririgaApi @apiCall
    }
}

<#
.SYNOPSIS
Enables TRIRIGA platform Logging for the given categories
.DESCRIPTION
Enables TRIRIGA platform Logging for the given categories

1. To see available log categories, run:
        Get-TririgaPlatformLogging <ENV> -Level 1 | Select-Object description
   Increase level to see sub categories
2. The -Category argument is the "description" of Get-TririgaPlatformLogging output .
   If you are looking in the TRIRIGA Admin Console, it is the name of the category that you see there.
3. Multiple categories can be given. See examples.
4. If the description matches multiple categories, all matches will be enabled.

Uses the /api/v1/admin/platformLogging/enable method
.EXAMPLE
PS> Enable-PlatformLogging LOCAL "SQL", "Workflow Logging", "Data Integrator (DataImport) Agent"
#>
function Enable-PlatformLogging() {
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
        # One or more categories to enable
        [Parameter(Mandatory, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string[]]$category
    )

    $categoryObjects = ResolveLogCategoryDescriptions -Environment $environment -Instance $instance -Category $category

    foreach($categoryObject in $categoryObjects) {

        $categoryName = $categoryObject.Name.split(".")[-1]
        $categoryNameEscaped = [System.Net.WebUtility]::UrlEncode($categoryName)

        $apiCall  = @{
            Environment = $environment
            Instance = $instance
            ApiMethod = "POST"
            ApiPath = "/api/v1/admin/platformLogging/enable?category=$categoryNameEscaped"
            OperationLabel = "Enable Logging"
        }

        CallTririgaApi @apiCall | Add-Member -PassThru category $categoryObject.Description
    }
}

<#
.SYNOPSIS
Disables TRIRIGA platform Logging for the given categories
.DESCRIPTION
Disables TRIRIGA platform Logging for the given categories

If no category is given, all currently enabled categories will be disabled.

1. To see available log categories, run:
        Get-TririgaPlatformLogging <ENV> -Level 1 | Select-Object description
   Increase level to see sub categories
2. The -Category argument is the "description" of Get-TririgaPlatformLogging output .
   If you are looking in the TRIRIGA Admin Console, it is the name of the category that you see there.
3. Multiple categories can be given. See examples.
4. If the description matches multiple categories, all matches will be enabled.

Uses the /api/v1/admin/platformLogging/enable method
.EXAMPLE
PS> Enable-PlatformLogging LOCAL "SQL", "Workflow Logging", "Data Integrator (DataImport) Agent"
#>
function Disable-PlatformLogging() {
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
        # One or more categories to enable
        [Parameter(Position=1)]
        [string[]]$category
    )

     $categoryObjects = @()

    if(!$category) {
        Write-Verbose "No categories specified. All enabled categories will be disabled."
        $categoryObjects = (Get-PlatformLogging -Environment $environment -Instance $instance -Enabled -Level 99 )
    } else {
         $categoryObjects = ResolveLogCategoryDescriptions -Environment $environment -Instance $instance -Category $category
    }

    foreach($categoryObject in $categoryObjects) {

        $categoryName = $categoryObject.Name.split(".")[-1]
        $categoryNameEscaped = [System.Net.WebUtility]::UrlEncode($categoryName)

        $apiCall  = @{
            Environment = $environment
            Instance = $instance
            ApiMethod = "POST"
            ApiPath = "/api/v1/admin/platformLogging/disable?category=$categoryNameEscaped"
            OperationLabel = "Disable Logging"
            TargetLabel = $categoryObject.Description
        }

        CallTririgaApi @apiCall | Add-Member -PassThru category $categoryObject.Description
    }
}

<#
.SYNOPSIS
Gets the hierarchy tree cache status details
.DESCRIPTION
Gets the hierarchy tree cache status details

Uses the /api/v1/admin/cache/hierarchyTree method
#>
function Get-CacheHierarchyTree() {
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
        ApiPath = "/api/v1/admin/cache/hierarchyTree"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Gets the cache processing mode
.DESCRIPTION
Gets the cache processing mode

Uses the /api/v1/admin/cache/mode/status method
#>
function Get-CacheMode() {
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

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/cache/mode/status"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Sets the cache processing mode
.DESCRIPTION
Sets the cache processing mode

Uses the /api/v1/admin/cache/mode method
#>
function Set-CacheMode() {
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
        # The cache processing mode to set
        [Parameter(Mandatory, Position=1)]
        [string]$mode
    )

    $modeEscaped = [System.Net.WebUtility]::UrlEncode($mode)

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "POST"
        ApiPath = "/api/v1/admin/cache/mode?mode=$modeEscaped"
        OperationLabel = "Set Cache Mode = $mode"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Clears a cache
.DESCRIPTION
Clears a cache. Clears all caches by default.

Uses the /api/v1/admin/cache/mode method
#>
function Clear-Cache() {
    [Alias("Flush-Cache")]
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
        # The cache to clear
        [Parameter(Position=1)]
        [string]$cache="ALLCACHESGLOBAL"
    )

    $cacheEscaped = [System.Net.WebUtility]::UrlEncode($cache)

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "POST"
        ApiPath = "/api/v1/admin/cache/refresh?cache=$cacheEscaped"
        OperationLabel = "Clear $cache Cache"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Gets the database environment information
.DESCRIPTION
Gets the database environment information

Uses the /api/v1/admin/databaseinfo method
#>
function Get-Database() {
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

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/databaseinfo"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Gets the database space information
.DESCRIPTION
Gets the database space information

Uses the /api/v1/admin/databaseinfo/space method
#>
function Get-DatabaseSpace() {
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

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "GET"
        ApiPath = "/api/v1/admin/databaseinfo/space"
    }

    CallTririgaApi @apiCall
}


<#
.SYNOPSIS
Invokes a database task
.DESCRIPTION
Invokes a database task

Uses the /api/v1/admin/databaseinfo/task method
#>
function Invoke-DatabaseTask() {
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
        # The cache to clear
        [Parameter(Mandatory,Position=1)]
        [string]$action
    )

    $actionEscaped = [System.Net.WebUtility]::UrlEncode($action)

    $apiCall = @{
        Environment = $environment
        Instance = $instance
        ApiMethod = "POST"
        ApiPath = "/api/v1/admin/databaseinfo/task?action=$actionEscaped"
        OperationLabel = "DatabaseTask/$action"
    }

    CallTririgaApi @apiCall
}

<#
.SYNOPSIS
Clears Workflow Instance data
.DESCRIPTION
Clears Workflow Instance data

Uses the /api/v1/admin/databaseinfo/task method
#>
function Clear-WorkflowInstance() {
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
        # Perform a truncate of workflow instances. This removes any workflows not running or waiting for user
        [switch]$truncate,
        # Do not ask for confirmation when truncating
        [switch]$force
    )

    $action = "cleanupwf"

    if ($truncate) {
        $action = "clearwfinstances"

        Write-Warning "This process will take awhile and MUST be done on very quiet system."
        Write-Warning "It is important to disable all workflow agents running against the database, and it is recommended you use the TRIRIGA System Lock to prevent people from logging in while the process executes."
        Write-Warning "Backup your database before executing this action, as it will permanently delete the data in these tables and if an error is occurs, the only recovery option is to restore from backup."
        Write-Warning "Review the server.log to ensure the command completes successfully before unsetting the System Lock and restarting the Workflow Agents."
        if ($force -or $PSCmdlet.ShouldContinue("Truncating workflows is a potentially destructive action. This MUST only be done in a quiet system as there is a chance for data loss if a deadlock occurs.", "Would you like to continue?") ) {
            Write-Warning "Performing workflow truncation"
        } else {
            return
        }
    }

    Invoke-DatabaseTask -Environment $environment -Instance $instance -Action $action
}

<#
.SYNOPSIS
Clears Business Object Records, removes stale data (12 hrs and older)
.DESCRIPTION
Clears Business Object Records, removes stale data (12 hrs and older)

Uses the /api/v1/admin/databaseinfo/task method
#>
function Clear-BusinessObject() {
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
        [string]$instance
    )

    Invoke-DatabaseTask -Environment $environment -Instance $instance -Action "cleanupbo"
}

<#
.SYNOPSIS
Clears Scheduled Events
.DESCRIPTION
Clears Scheduled Events

Uses the /api/v1/admin/databaseinfo/task method
#>
function Clear-ScheduledEvent() {
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
        [string]$instance
    )

    Invoke-DatabaseTask -Environment $environment -Instance $instance -Action "cleanupschedule"
}

<#
.SYNOPSIS
Runs a full database cleanup
.DESCRIPTION
Runs a full database cleanup

Uses the /api/v1/admin/databaseinfo/task method
#>
function Clear-DatabaseAll() {
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
        [string]$instance
    )

    Invoke-DatabaseTask -Environment $environment -Instance $instance -Action "allcleanup"
}
