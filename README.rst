PowerShell Scripts to Manage TRIRIGA Environments
=================================================
PowerShell commands to manage TRIRIGA instances.

There are command to manage installations on Windows Servers and some aspects
using the TRIRIGA REST management API.

The commands allow you to refer to your instances by [Environment] [Instance] (eg: DEV NS1).

Features
--------
* Simple way to refer to instances
* Operate on all instances in an environment at once
* Warning and count down when working on production instances

Requirements
------------
* Windows Powershell 5.x or PowerShell 7.x
* TRIRIGA servers must be running Windows
* Your account must have access to TRIRIGA servers

Notice
------
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Commands
--------
The commands are self-documenting. The see the latest help, run:

.. code:: ps1

    Get-Command -Module Tririga-Manage | % {Get-Help $_.Name} | Select-Object Name,Synopsis | Format-Table
    Get-Command -Module Tririga-Manage-Rest | % {Get-Help $_.Name} | Select-Object Name,Synopsis | Format-Table

To see detailed help, run:

.. code:: ps1

    Get-Help <command> -Detailed


.. Get-Command -Module Tririga-Manage | % {Get-Help $_.Name} | Select-Object Name,Synopsis | Export-CSV tririga-manage.csv
.. Get-Command -Module Tririga-Manage-Rest | % {Get-Help $_.Name} | Select-Object Name,Synopsis | Export-CSV tririga-manage-rest.csv
.. mlr --icsv --ocsv cat then clean-whitespace tririga-manage.csv tririga-manage-rest.csv

.. ##BEGIN TABLE
.. csv-table::
    :header-rows: 1
    :stub-columns: 1

    Name,Synopsis
    Disable-TririgaService,Disables TRIRIGA service
    Disable-TririgaWorkflowInstance,Sets the workflow instance recording setting to ERRORS_ONLY
    Enable-TririgaService,Enables TRIRIGA service
    Enable-TririgaWorkflowInstance,Sets the workflow instance recording setting to ALWAYS
    Enter-TririgaHost,Starts a remote powershell session to a server
    Get-TririgaActiveUsers,Gets a list of currently logged in users
    Get-TririgaAdminUsers,Gets a list of users who can access the TRIRIGA Admin Console
    Get-TririgaAgentHost,Gets the configured host(s) for the given agent(s)
    Get-TririgaAgents,Gets TRIRIGA Agents configuration
    Get-TririgaBuildNumber,Gets TRIRIGA build number
    Get-TririgaEnvironments,Prints all known environments
    Get-TririgaInstances,Prints all known instances in a given environment
    Get-TririgaLog,Tails a TRIRIGA log file
    Get-TririgaStatus,Get the current status of TRIRIGA service
    Get-TririgaSummary,Gets basic information about a TRIRIGA instance
    Get-TririgaWasLog,Tails a WebSphere log file
    Import-TririgaOmp,Uploads and imports a local OMP zip file to TRIRIGA
    Open-TririgaDatabase,Connects to the TRIRIGA database
    Open-TririgaFolder,Opens a TRIRIGA installation directory path
    Open-TririgaLog,Opens a TRIRIGA log file
    Open-TririgaRDP,Opens an RDP client connection to the TRIRIGA server
    Open-TririgaWasFolder,Opens a WebSphere profile path
    Open-TririgaWasLog,Opens a WebSphere log file
    Open-TririgaWasWeb,Opens the WebSphere Admin Console
    Open-TririgaWeb,Opens a TRIRIGA environment
    Restart-TririgaService,Restarts TRIRIGA service
    Set-TririgaWorkflowInstance,Updates workflow instance recording setting
    Start-TririgaAgent,Starts a TRIRIGA agent
    Start-TririgaService,Starts TRIRIGA service
    Stop-TririgaAgent,Stops a TRIRIGA agent
    Stop-TririgaService,Stops TRIRIGA service
    Upload-TririgaOmp,Uploads a local OMP zip file to TRIRIGA
.. ##END TABLE

Usage
-----
All commands accept a ``-Environment`` argument. You can also set the
environment variable ``$env:TRIRIGA_ENVIRONMENT`` to provide it.

Some commands require a ``-Instance`` argument or optionally accept it. When it
is optional and omitted, action will be performed on all instances in the
environment.

If ``$env:TRIRIGA_INSTANCE`` environment variable is set it will be used.

Installation
------------
From Gitea
~~~~~~~~~~
Run:

.. code:: ps1

    Install-Module -Scope CurrentUser -Name Tririga-Manage -RequiredVersion 3.0.0
    Install-Module -Scope CurrentUser -Name Tririga-Manage-Rest -RequiredVersion 3.0.0

.. Note:: Due to limitations in the Gitea Nuget API, the version must be
          specified. Run ``Find-Module -Repository Gitea`` to see the latest versions.

From Source
~~~~~~~~~~~
#. Open a PowerShell window in *this* directory.
#. Run::

        .\Install.ps1

Development
-----------
To load the module from the current directory:

.. code:: ps1

    $env:PSModulePath = "$(Resolve-Path .)" + [IO.Path]::PathSeparator + $env:PSModulePath

To Install Module::

    .\Install.ps1

To see debug log messages, set:

.. code:: ps1

    $VerbosePreference = "Continue"

To Force reload of module in current session:

.. code:: ps1

    Import-Module Tririga-Manage-Rest -Force; Import-Module Tririga-Manage -Force

Publish
-------
To publish the modules to Gitea, run::

    ./Install.ps1 -Version "3.0.1" -Publish -NuGetApiKey <gitea-personal-access-token>

