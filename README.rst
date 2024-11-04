PowerShell Scripts to Manage TRIRIGA Environments
=================================================
PowerShell commands to manage TRIRIGA instances.

There are command to manage installations on Windows Servers and some aspects
using the TRIRIGA REST management API.

Features
--------
* Simple way to refer to instances
* Where applicable, commands can operate on all instances in an environment at once
* Confirmation when working on production instances

Requirements
------------
* Windows Powershell 5.x or PowerShell 7.x
* TRIRIGA servers must be running Windows to use the ``Tririga-Manage`` module
* Your local Windows account must have access to the Windows server running
  TRIRIGA

Commands
--------
The see the latest help, run:

.. code:: ps1

    Get-Command -Module Tririga-Manage* | % {Get-Help $_.Name} | Select-Object Name,Synopsis | Format-Table

To see detailed help for a command, run:

.. code:: ps1

    Get-Help <command> -Detailed

Configuration
~~~~~~~~~~~~~
Before using the commands, you will need to set a configuration variable named
``$TririgaEnvironments`` with details about your environments.

If you wish to use the ``Open-TririgaDatabase`` command, you will also need to set
the ``$DBeaverBin`` variable with the path to the ``dbeaver.exe`` file.

#. To load the sample configuration, open a PowerShell window and paste the following:

   .. code:: ps1

        $EnvironmentSampleLocation = "https://raw.githubusercontent.com/nithinphilips/tririga-manage-ps1/refs/heads/main/environments.sample.psd1"

        $profileDir = Split-Path $Profile -Parent
        $environmentsFile = Join-Path $profileDir "environments.psd1"

        New-Item -Type Directory -Path $profileDir -Force | Out-Null

        If (!(Test-Path -Path "$Profile") -or !(Select-String -Path "$Profile" -pattern "TririgaEnvironments"))
        {
            if (!(Test-Path -Path $environmentsFile)) {
                (Invoke-WebRequest $EnvironmentSampleLocation).Content | Out-File $environmentsFile
                Write-Host "A sample environments file has been placed at $environmentsFile. Edit to customize"
            }

            Write-Host "Installing this script to your PowerShell profile $Profile"
            "`$TririgaEnvironments = (Import-PowerShellDataFile `"$environmentsFile`")" | Out-file "$Profile" -append
            "`$DBeaverBin=`"$($env:UserProfile)\AppData\Local\DBeaver\dbeaver.exe`"" | Out-file "$Profile" -append
        } else {
            echo "Profile already configured"
        }

   Note the location of the sample file.

#. Edit the sample file. Refer to the comments for instructions:

   .. ##BEGIN CONFIG SAMPLE
   .. code:: ps1
   
        # This file is a PowerShell Data file
        # Doc: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_data_files
        @{
            # The key is the unique name you want to use for this environment
            # This is used as the value for the -Environment argument
            "LOCAL" = @{
                # If $true, any actions that might modify the environment will require confirmation
                # Set this on Production environment.
                Warn = $False;
                # The DBeaver profile associated with this environment
                DbProfile = "Tririga Local";
                # Tririga Username and Password (non-SSO) for use with the REST api calls
                Username = "system";
                Password = "badadmin";
                # List of all your TRIRIGA servers/instances
                Servers = @{
                    # The key is the unique name you want to use for this instance
                    # This is used as the value for the -Instance argument
                    "ONE" = @{
                        # The hostname of this instance
                        Host = "localhost"
                        # The path where TRIRIGA is installed on the server
                        Tririga = "C:\IBM\Tririga1"
                        # The path where WebSphere profile is located on the server
                        WebSphere = "C:\Program Files\IBM\WebSphere\AppServer\profiles\AppSrv01\logs\server1"
                        # The Windows service that controls this TRIRIGA instance
                        Service = "TestService1"
                        # The URL to access this TRIRIGA instance
                        Url = "http://localhost:9080"
                        # Optional. Url that bypasses SSO (used when you use IIS auth).
                        # For SAML SSO, leave this out
                        ApiUrl = "http://localhost:9081"
                        # The URL to access this instance's WebSphere console
                        WasUrl = "http://localhost:9060/ibm/console"
                        # Optional. This should be either hostname or if set, the
                        # INSTANCE_NAME property in TRIRIGAWEB.properties This is used
                        # to match agent host information to an instance
                        InstanceName = "<ANY>"
                        # If you cannot use Rest API to identify the ObjectMigration
                        # server, indicate that this instance run the object migration
                        # agent.
                        ObjectMigrationAgent = $true
                    };
                    # Repeat for all other servers/instances
                    "TWO" = @{
                        # ...
                    };
                }
            };
            # Repeat for all other environments
            "REMOTE" = @{
                # ...
            };
        }
   .. ##END CONFIG SAMPLE

Usage
~~~~~
All commands accept a ``-Environment`` argument. For example, with the sample
configuration above, you can use either ``-Environment LOCAL`` or ``-Environment REMOTE``

Some commands require a ``-Instance`` argument or optionally accept it. When it
is optional and omitted, action will be performed on the first or all instances
in the environment, depending on the nature of the command. With the sample
configuration above, you can use either ``-Instance ONE`` or ``-Instance TWO``
with ``-Environment LOCAL``.

Available Commands
~~~~~~~~~~~~~~~~~~
.. ##BEGIN TABLE
.. csv-table::
    :header-rows: 1
    :stub-columns: 1

    Name,Synopsis
    Get-TririgaActiveUser,Gets a list of currently logged in users
    Get-TririgaAdminUser,Gets a list of users who can access the TRIRIGA Admin Console
    Get-TririgaAgent,Gets TRIRIGA Agents configuration
    Start-TririgaAgent,Starts a TRIRIGA agent
    Stop-TririgaAgent,Stops a TRIRIGA agent
    Get-TririgaAgentHost,Gets the configured host(s) for the given agent
    Get-TririgaBuildNumber,Gets TRIRIGA build number
    Open-TririgaDatabase,Opens Dbeaver and connects to the TRIRIGA database
    Get-TririgaEnvironment,Gets all known environments
    Open-TririgaFolder,Opens a TRIRIGA installation directory path
    Enter-TririgaHost,Starts a remote powershell session to a TRIRIGA instance
    Get-TririgaInstance,Gets all known instances in a given environment
    Get-TririgaLog,Tails a TRIRIGA log file
    Open-TririgaLog,Opens a TRIRIGA log file
    Upload-TririgaOmp,Uploads a local OMP zip file to TRIRIGA
    Import-TririgaOmp,Uploads and imports a local OMP zip file to TRIRIGA
    Save-TririgaOmp,Uploads a local OMP zip file to TRIRIGA
    Open-TririgaRDP,Opens an RDP client connection to the TRIRIGA server
    Disable-TririgaService,Disables TRIRIGA service
    Enable-TririgaService,Enables TRIRIGA service
    Get-TririgaService,Get the current status of TRIRIGA service
    Restart-TririgaService,Restarts TRIRIGA service
    Start-TririgaService,Starts TRIRIGA service
    Stop-TririgaService,Stops TRIRIGA service
    Get-TririgaSummary,Gets basic information about a TRIRIGA instance
    Open-TririgaWasFolder,Opens a WebSphere profile path
    Get-TririgaWasLog,Tails a WebSphere log file
    Open-TririgaWasLog,Opens a WebSphere log file
    Open-TririgaWasWeb,Opens the WebSphere Admin Console
    Open-TririgaWeb,Opens a TRIRIGA environment
    Disable-TririgaWorkflowInstance,Sets the workflow instance recording setting to ERRORS_ONLY
    Enable-TririgaWorkflowInstance,Sets the workflow instance recording setting to ALWAYS
    Set-TririgaWorkflowInstance,Updates workflow instance recording setting
.. ##END TABLE

Installation
------------
From PowerShell Gallery
~~~~~~~~~~~~~~~~~~~~~~~~
You may need to enable script execution:

.. code:: ps1

    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

Run:

.. code:: ps1

    Install-Module Tririga-Manage -Scope CurrentUser
    Install-Module Tririga-Manage-Rest -Scope CurrentUser

Configure the environment as described in the `Configuration`_ section above.

If you are using PowerShell 5.1, some methods may not trigger automatic loading
of the module. Add this to your ``$Profile`` file to force module loading:

.. code:: ps1

    "Import-Module Tririga-Manage" | Out-file "$Profile" -append
    "Import-Module Tririga-Manage-Rest" | Out-file "$Profile" -append

From Source
~~~~~~~~~~~
#. Open a PowerShell window in *this* directory.
#. Run::

        .\Install.ps1

If you are using PowerShell 5.1, some methods may not trigger automatic loading
of the module. Add this to your ``$Profile`` file to force module loading:

.. code:: ps1

    "Import-Module Tririga-Manage" | Out-file "$Profile" -append
    "Import-Module Tririga-Manage-Rest" | Out-file "$Profile" -append

License
-------
.. code::

    tririga-manage-ps1. PowerShell Modules to manage IBM TRIRIGA.
    Copyright (C) 2024 Nithin Philips

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
