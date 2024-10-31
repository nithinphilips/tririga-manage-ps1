PowerShell Scripts to Manage TRIRIGA Environments
=================================================
PowerShell commands to manage TRIRIGA instances.

There are command to manage installations on Windows Servers and some aspects
using the TRIRIGA REST management API.

Features
--------
* Simple way to refer to instances
* Where applicable, commands operate on all instances in an environment at once
* Confirmation when working on production instances

Requirements
------------
* Windows Powershell 5.x or PowerShell 7.x
* TRIRIGA servers must be running Windows
* Your local Windows account must have access to the Windows server running
  TRIRIGA

Notice
------
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Commands
--------
The commands are self-documenting. The see the latest help, run:

.. code:: ps1

    Get-Command -Module Tririga-Manage* | % {Get-Help $_.Name} | Select-Object Name,Synopsis | Format-Table

To see detailed help for a command, run:

.. code:: ps1

    Get-Help <command> -Detailed

Usage
~~~~~
Before using the commands, you will need to set a configuration variable named
``$TririgaEnvironments`` with details about your environments.

If you wish to use the ``Open-TririgaDatabase`` command, you will also need to set
the ``$DBeaverBin`` variable with the path to the ``dbeaver.exe`` file.

To configure, add this to your `PowerShell Profile
<https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles>`_
file. To keep things tidy, we are storing the environment information in a
separate file (``environments.ps1``)

.. code:: ps1

    $TririgaEnvironments = (Get-Content "$env:UserProfile\Documents\PowerShell\environments.ps1" | Out-String | Invoke-Expression)
    $DBeaverBin="$env:UserProfile\AppData\Local\DBeaver\dbeaver.exe"

When you install using the ``Install.ps1`` script, these lines are
automatically added to your PowerShell Profile file and a sample
``environments.ps1`` file is installed (if you don't already have one.)

.. include:: environments.sample.ps1
    :code: ps1

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
    Get-TririgaActiveUsers,Gets a list of currently logged in users
    Get-TririgaAdminUsers,Gets a list of users who can access the TRIRIGA Admin Console
    Start-TririgaAgent,Starts a TRIRIGA agent
    Stop-TririgaAgent,Stops a TRIRIGA agent
    Get-TririgaAgentHost,Gets the configured host(s) for the given agent
    Get-TririgaAgents,Gets TRIRIGA Agents configuration
    Get-TririgaBuildNumber,Gets TRIRIGA build number
    Open-TririgaDatabase,Opens Dbeaver and connects to the TRIRIGA database
    Get-TririgaEnvironments,Gets all known environments
    Open-TririgaFolder,Opens a TRIRIGA installation directory path
    Enter-TririgaHost,Starts a remote powershell session to a TRIRIGA instance
    Get-TririgaInstances,Gets all known instances in a given environment
    Get-TririgaLog,Tails a TRIRIGA log file
    Open-TririgaLog,Opens a TRIRIGA log file
    Upload-TririgaOmp,Uploads a local OMP zip file to TRIRIGA
    Import-TririgaOmp,Uploads and imports a local OMP zip file to TRIRIGA
    Save-TririgaOmp,Uploads a local OMP zip file to TRIRIGA
    Open-TririgaRDP,Opens an RDP client connection to the TRIRIGA server
    Disable-TririgaService,Disables TRIRIGA service
    Enable-TririgaService,Enables TRIRIGA service
    Restart-TririgaService,Restarts TRIRIGA service
    Start-TririgaService,Starts TRIRIGA service
    Stop-TririgaService,Stops TRIRIGA service
    Get-TririgaStatus,Get the current status of TRIRIGA service
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
From Gitea
~~~~~~~~~~
Run:

.. code:: ps1

    Install-Module -Scope CurrentUser -Name Tririga-Manage -RequiredVersion <version>
    Install-Module -Scope CurrentUser -Name Tririga-Manage-Rest -RequiredVersion <version>

.. Note:: Due to limitations in the Gitea Nuget API, the version must be
          specified. Run ``Find-Module -Repository Gitea`` to see the latest versions.

From Source
~~~~~~~~~~~
#. Open a PowerShell window in *this* directory.
#. Run::

        .\Install.ps1

Development
-----------
To load the module from the project directory:

.. code:: ps1

    $env:PSModulePath = "$(Resolve-Path .)" + [IO.Path]::PathSeparator + $env:PSModulePath
    ./Install.ps1 -UpdateModule -NoInstallModule
    Import-Module Tririga-Manage-Rest -Force; Import-Module Tririga-Manage -Force

Repeat the ``Import-Module`` commands to reload the module as you make changes.

To see debug log messages, set:

.. code:: ps1

    $VerbosePreference = "Continue"

Publish
-------
To publish the modules to Gitea

#. Edit ``install.ps1`` and update the version.
#. Build dist. This will update README and module definitions::

        make dist

#. Commmit changes
#. Create a tag::

        git tag v<version>

#. Push all changes::

        git push && git push --tags

#. Release::

        make release

