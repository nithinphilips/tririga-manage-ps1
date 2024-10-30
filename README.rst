PowerShell Scripts to Manage TRIRIGA Environments
=================================================
PowerShell commands to manage TRIRIGA instances.

There are command to manage installations on Windows Servers and some aspects
using the TRIRIGA REST management API.

The commands allow you to refer to your instances by [Environment] [Instance] (eg: DEV NS1).

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

.. csv-table::
    :header-rows: 1
    :stub-columns: 1

    Name,Synopsis
    Tririga-Browse,Opens a TRIRIGA installation directory path
    Tririga-Db,Connects to the TRIRIGA database
    Tririga-Disable,Disables TRIRIGA service
    Tririga-Enable,Enables TRIRIGA service
    Tririga-Enter,Starts a remote powershell session to a server
    Tririga-Environments,Prints all known environments
    Tririga-Import-Omp,Uploads and imports a local OMP zip file to TRIRIGA
    Tririga-Instances,Prints all known instances in a given environment
    Tririga-Log,Tails a TRIRIGA log file
    Tririga-Log-Open,Opens a TRIRIGA log file
    Tririga-Open,Opens a TRIRIGA environment
    Tririga-RDP,Opens an RDP client connection to the TRIRIGA server
    Tririga-Restart,Restarts TRIRIGA service
    Tririga-Start,Starts TRIRIGA service
    Tririga-Status,Get the current status of TRIRIGA service
    Tririga-Stop,Stops TRIRIGA service
    Tririga-Upload-Omp,Uploads a local OMP zip file to TRIRIGA
    Was-Browse,Opens a WebSphere profile path
    Was-Log,Tails a WebSphere log file
    Was-Log-Open,Opens a WebSphere log file
    Was-Open,Opens the WebSphere Admin Console
    Enable-TririgaWorkflowInstance,Sets the workflow instance recording setting to ALWAYS
    Get-TririgaActiveUsers,Gets a list of currently logged in users
    Get-TririgaAdminUsers,Gets a list of users who can access the TRIRIGA Admin Console
    Get-TririgaAgentHost,Gets the configured host(s) for the given agent(s)
    Get-TririgaAgents,Gets TRIRIGA Agents configuration
    Get-TririgaBuildNumber,Gets TRIRIGA build number
    Get-TririgaSummary,Gets basic information about a TRIRIGA instance
    Set-TririgaWorkflowInstance,Updates workflow instance recording setting
    Start-TririgaAgent,Starts a TRIRIGA agent
    Stop-TririgaAgent,Stops a TRIRIGA agent


Features
--------
* Simple way to refer to instances
* Operate on all instances in an environment at once
* Warning and count down when working on production instances

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
To Install Module while developing::

    watchexec .\Install.ps1 -develop

To see debug log messages, set ``$VerbosePreference = "Continue"``

To Force reload of module in current session:

.. code:: ps1

    Import-Module Tririga-Manage-Rest -Force
    Import-Module Tririga-Manage -Force

Publish
-------
To publish the modules to Gitea, run::

    ./Install.ps1 -Version "3.0.1" -Publish -NuGetApiKey <gitea-personal-access-token>

