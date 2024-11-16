PowerShell Commands to Manage TRIRIGA
=====================================
PowerShell commands to manage TRIRIGA instances.

This project provides two modules:

* `Tririga-Manage`_: Commands to manage TRIRIGA installations on Windows
* `Tririga-Manage-Rest`_: Commands to manage TRIRIGA instances using the admin REST API

You can install each independently.

If ``Tririga-Manage-Rest`` is installed, the ``Upload-TririgaOmp`` and
``Import-TririgaOmp`` can use it to find the actual server running the
ObjectMigration agent.


.. pull-quote::

    **!NOTE**

    IBM and TRIRIGA are trademarks or registered trademarks of International
    Business Machines Corp.

    **This project is not affiliated with IBM.**

.. _Tririga-Manage: https://www.powershellgallery.com/packages/Tririga-Manage
.. _Tririga-Manage-Rest: https://www.powershellgallery.com/packages/Tririga-Manage-Rest

Features
--------
* Simple way to refer to environments and instances
* Operate on all instances in an evironment with a single command.
* Confirmation when working on production instances
* The outputs are PowerShell objects and the commands can be composed for
  advanced functionality.

**Tririga-Manage**

* Control TRIRIGA service remotely (``Start``, ``Stop``, ``Enable``,
  ``Disable``)
* ``Upload`` or ``Import`` ObjectMigration packages
* Tail or open TRIRIGA logs
* Tail or open WebSphere logs
* Open TRIRIGA installation folder
* Open WebSphere installation folder
* Launch database tool and connect to the environment
* Launch RDP to each instance
* Open PowerShell remote shell to each instance

**Tririga-Manage-Rest**

* Get list of Active Users
* Get list of Users with access to admin console
* Get Build Number, System Info and Summary Info
* Start or Stop Agents
* Enable or disable logging
* Get or set properties in TRIRIGAWEB.properties and other .properties files.
* Lock and Unlock TRIRIGA.
* Enable or Disable workflow instance recording.

Requirements
------------
* Windows Powershell 5.x or PowerShell 7.x
* For ``Tririga-Manage``: TRIRIGA servers must be running Windows
* For ``Tririga-Manage``: Your local Windows account must have access to the
  Windows server running TRIRIGA

Installation
------------
.. From PowerShell Gallery
   ~~~~~~~~~~~~~~~~~~~~~~~~

#. Enable script execution:

   .. code:: ps1

        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

#. Install the modules:

   .. code:: ps1

        Install-Module Tririga-Manage -Scope CurrentUser
        Install-Module Tririga-Manage-Rest -Scope CurrentUser

   If you are using *PowerShell 5.1*, some methods may not trigger automatic
   loading of the module. Manually import the module in your ``$Profile`` file
   to force module loading. Run in a PowerShell window:

   .. code:: ps1

       "Import-Module Tririga-Manage" | Out-file "$Profile" -append
       "Import-Module Tririga-Manage-Rest" | Out-file "$Profile" -append

#. Configure the environment as described in the `Configuration`_ section above.

..
    From Source
    ~~~~~~~~~~~
    #. Download the distibution zip file from the `releases page
    <https://github.com/nithinphilips/tririga-manage-ps1/releases/latest>`_.
    #. Open a PowerShell window in the same directory as the zip file
    #. Run::

            Unblock-File tririga-manage-ps1-4.6.0.zip
            Expand-Archive tririga-manage-ps1-4.6.0.zip -DestinationPath .
            .\tririga-manage-ps1\Install.ps1

    If you are using *PowerShell 5.1*, some methods may not trigger automatic loading
    of the module. Add this to your ``$Profile`` file to force module loading:

    .. code:: ps1

        "Import-Module Tririga-Manage" | Out-file "$Profile" -append
        "Import-Module Tririga-Manage-Rest" | Out-file "$Profile" -append

Commands
--------
The see a list of all commands, run:

.. code:: ps1

    Get-Command -Module Tririga-Manage*

To view detailed help for a command, run:

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

Tririga-Manage-Rest Module
^^^^^^^^^^^^^^^^^^^^^^^^^^
Let's start with getting information about the environment. Use
``Get-TririgaSummary`` command:

.. code:: ps1

    PS> Get-TririgaSummary LOCALTWO
    operatingSytem               : Linux amd64 null
    noofcpus                     : 4
    baseApplicationServer        : Liberty
    users                        : 55 users online
    ...
    environment                  : LOCALTWO
    instance                     : TWO

The output is an object that you can manipulate using `PowerShell object
commands
<https://learn.microsoft.com/en-us/powershell/scripting/learn/ps101/03-discovering-objects>`_.

For example, to get just the ``operatingSytem`` [sic] value, run:

.. code:: ps1

    PS> Get-TririgaSummary LOCALTWO | Select-Object operatingSytem
    operatingSytem
    --------------
    Linux amd64 null

This output is still an object. To get just the text value:

.. code:: ps1

    PS> Get-TririgaSummary LOCALTWO | %{ $_.operatingSytem }
    Linux amd64 null

If you want to run this against all your environments, you can run:

.. code:: ps1

    PS> @("LOCAL", "LOCALTWO") | %{ Get-TririgaSummary -All $_ } | Select-Object operatingSytem, environment, instance
    operatingSytem   environment instance
    --------------   ----------- --------
    Linux amd64 null LOCAL       ONE
    Linux amd64 null LOCALTWO    TWO
    Linux amd64 null LOCALTWO    ONE

----

To see all currently active sessions:

.. code:: ps1

    PS> Get-TririgaActiveUser LOCAL | Sort-Object userAccount -Unique
    userAccount fullName       email                    lastTouchDuration
    ----------- --------       -----                    -----------------
    system      System System                           00d:03h:17m:00s
    system      System System                           00d:03h:17m:00s
    system      System System                           00d:03h:17m:00s
    system      System System                           00d:03h:17m:00s

There are a few duplicate entires here. To get just the unique users:

.. code:: ps1

    PS> Get-TririgaActiveUser LOCAL | Sort-Object userAccount -Unique
    userAccount fullName       email                    lastTouchDuration
    ----------- --------       -----                    -----------------
    system      System System                           00d:03h:17m:00s

For convenience, the ``Get-TririgaActiveUser`` command also has a ``-Unique``
switch, which does the same thing:

.. code:: ps1

    PS> Get-TririgaActiveUser LOCAL -Unique
    userAccount fullName       email                    lastTouchDuration
    ----------- --------       -----                    -----------------
    system      System System                           00d:03h:17m:00s

Even if this switch was not present, using PowerShell you can filter and
manipulate the output to get exactly the format you need.

----

Some commands run against all instances in the environment by default. This is
done in cases where the output might be different from each instance

Let's run ``Get-TririgaBuildNumber``

.. code:: ps1

    PS> Get-TririgaBuildNumber LOCALTWO

    buildNumber         : 301221
    ...
    environment         : LOCALTWO
    instance            : TWO

    buildNumber         : 301221
    ...
    environment         : LOCALTWO
    instance            : ONE

You can see that it ran against both instances in the ``LOCALTWO`` environment
and returned two objects.

Suppose, you want to check if all the instances in your environment have
the same build number:

.. code:: ps1

    PS> Get-TririgaBuildNumber LOCALTWO | % { $_.buildNumber } | Sort-Object -Unique
    301221

By showing only unique build numbers, you can quickly verify that all instances
have the same build number.

----

Other commands run against only one instance in the environment by default.
This is done in cases where the output is the same no matter what instance you
query.

Let's check the status of all agents. You will get the same result no matter
what server you query:

.. code:: ps1

    PS> Get-TririgaAgent LOCAL
    ID  Agent                        Hostname  Status
    --  -----                        --------  ------
    210 SNMPAgent                              Not Running
    211 IncomingMailAgent            <ANY>     Running
    212 ObjectMigrationAgent         <ANY>     Running
    213 DataImportAgent              localhost Running
    202 WFAgent                      localhost Running
    203 ObjectPublishAgent           <ANY>     Running
    214 SchedulerAgent               localhost Running
    204 ReportQueueAgent             <ANY>     Running
    215 WFNotificationAgent          <ANY>     Running
    216 DataConnectAgent                       Not Running
    205 ReserveSMTPAgent                       Not Running
    206 PlatformMaintenanceScheduler <ANY>     Running
    207 ExtendedFormulaAgent         <ANY>     Running
    208 FormulaRecalcAgent           <ANY>     Running
    209 WFFutureAgent                <ANY>     Running

Again, we can apply an ad-hoc filter to see just the running ones:

.. code:: ps1

    PS> Get-TririgaAgent LOCAL | ? Status -eq Running
    ID  Agent                        Hostname  Status
    --  -----                        --------  ------
    211 IncomingMailAgent            <ANY>     Running
    212 ObjectMigrationAgent         <ANY>     Running
    213 DataImportAgent              localhost Running
    202 WFAgent                      localhost Running
    203 ObjectPublishAgent           <ANY>     Running
    214 SchedulerAgent               localhost Running
    204 ReportQueueAgent             <ANY>     Running
    215 WFNotificationAgent          <ANY>     Running
    206 PlatformMaintenanceScheduler <ANY>     Running
    207 ExtendedFormulaAgent         <ANY>     Running
    208 FormulaRecalcAgent           <ANY>     Running
    209 WFFutureAgent                <ANY>     Running

This is a common need, so you can use the convenience shortcut:

.. code:: ps1

    PS> Get-TririgaAgent LOCAL -Running

----

Operations that affect the system state all have a ``-WhatIf`` and ``-Confirm`` switches.

Use ``-WhatIf`` switch to preview the changes:

.. code:: ps1

    > Stop-TririgaAgent LOCAL WFAgent -WhatIf
    What if: Performing the operation "Stop" on target "WFAgent [202] on localhost".

Use ``-Confirm`` switch to review each change:

.. code:: ps1

    > Stop-TririgaAgent LOCAL WFAgent -Confirm

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Stop" on target "WFAgent [202] on localhost".
    [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): N

You will see one prompt for each change the the command is about to make. For
example, with Workflow Agents, you may have several agents. You will be asked
to confirm *Stop* on each of these agents.

----

Some commands can be chained together to perform complex operations.

For example, suppose you want to take the ``FRONT_END_SERVER`` setting on all
your instances (which may all have different values,) and change the protocol
to ``https`` while preserving the rest of the value. To do that, run:

.. code:: ps1


    PS> Get-TririgaProperty LOCAL FRONT_END_SERVER
    environment instance file       FRONT_END_SERVER
    ----------- -------- ----       ----------------
    LOCAL       ONE      TRIRIGAWEB http://localhost:9080/

    PS> Get-TririgaProperty LOCAL FRONT_END_SERVER `
        | %  { $_.FRONT_END_SERVER = $_.FRONT_END_SERVER.replace("http:", "https:"); $_ } `
        | Set-TririgaProperty
    environment instance file       FRONT_END_SERVER
    ----------- -------- ----       ----------------
    LOCAL       ONE      TRIRIGAWEB https://localhost:9080/


Available Commands
~~~~~~~~~~~~~~~~~~
Tririga-Manage Module
^^^^^^^^^^^^^^^^^^^^^
The Tririga-Manage module operates on TRIRIGA installation on a Windows server.

.. ##BEGIN TABLE TRIRIGA MANAGE
.. csv-table::
    :header-rows: 1
    :stub-columns: 1
 
    Name,Synopsis
    `Open-TririgaDatabase <docs/Open-TririgaDatabase.md>`_,Opens Dbeaver and connects to the TRIRIGA database
    `Get-TririgaEnvironment <docs/Get-TririgaEnvironment.md>`_,Gets all known environments
    `Open-TririgaFolder <docs/Open-TririgaFolder.md>`_,Opens a TRIRIGA installation directory path
    `Enter-TririgaHost <docs/Enter-TririgaHost.md>`_,Starts a remote powershell session to a TRIRIGA instance
    `Get-TririgaInstance <docs/Get-TririgaInstance.md>`_,Gets all known instances in a given environment
    `Get-TririgaLog <docs/Get-TririgaLog.md>`_,Tails a TRIRIGA log file
    `Open-TririgaLog <docs/Open-TririgaLog.md>`_,Opens a TRIRIGA log file
    `Upload-TririgaOmp <docs/Upload-TririgaOmp.md>`_,Uploads a local OMP zip file to TRIRIGA
    `Import-TririgaOmp <docs/Import-TririgaOmp.md>`_,Uploads and imports a local OMP zip file to TRIRIGA
    `Save-TririgaOmp <docs/Save-TririgaOmp.md>`_,Uploads a local OMP zip file to TRIRIGA
    `Open-TririgaRDP <docs/Open-TririgaRDP.md>`_,Opens an RDP client connection to the TRIRIGA server
    `Disable-TririgaService <docs/Disable-TririgaService.md>`_,Disables TRIRIGA service
    `Enable-TririgaService <docs/Enable-TririgaService.md>`_,Enables TRIRIGA service
    `Get-TririgaService <docs/Get-TririgaService.md>`_,Get the current status of TRIRIGA service
    `Restart-TririgaService <docs/Restart-TririgaService.md>`_,Restarts TRIRIGA service
    `Start-TririgaService <docs/Start-TririgaService.md>`_,Starts TRIRIGA service
    `Stop-TririgaService <docs/Stop-TririgaService.md>`_,Stops TRIRIGA service
    `Open-TririgaWasFolder <docs/Open-TririgaWasFolder.md>`_,Opens a WebSphere profile path
    `Get-TririgaWasLog <docs/Get-TririgaWasLog.md>`_,Tails a WebSphere log file
    `Open-TririgaWasLog <docs/Open-TririgaWasLog.md>`_,Opens a WebSphere log file
    `Open-TririgaWasWeb <docs/Open-TririgaWasWeb.md>`_,Opens the WebSphere Admin Console
    `Open-TririgaWeb <docs/Open-TririgaWeb.md>`_,Opens a TRIRIGA environment
.. ##END TABLE TRIRIGA MANAGE

Tririga-Manage-Rest Module
^^^^^^^^^^^^^^^^^^^^^^^^^^
The Tririga-Manage-Rest module operates on TRIRIGA using the management REST API.

.. ##BEGIN TABLE TRIRIGA MANAGE REST
.. csv-table::
    :header-rows: 1
    :stub-columns: 1
 
    Name,Synopsis
    `Get-TririgaActiveUser <docs/Get-TririgaActiveUser.md>`_,Gets a list of currently logged in users
    `Get-TririgaAdminUser <docs/Get-TririgaAdminUser.md>`_,Gets a list of users who can access the TRIRIGA Admin Console
    `Get-TririgaAgent <docs/Get-TririgaAgent.md>`_,Gets TRIRIGA Agents configuration
    `Start-TririgaAgent <docs/Start-TririgaAgent.md>`_,Starts a TRIRIGA agent
    `Stop-TririgaAgent <docs/Stop-TririgaAgent.md>`_,Stops a TRIRIGA agent
    `Get-TririgaAgentHost <docs/Get-TririgaAgentHost.md>`_,Gets the configured host(s) for the given agent
    `Get-TririgaBuildNumber <docs/Get-TririgaBuildNumber.md>`_,Gets TRIRIGA build number
    `Clear-TririgaBusinessObject <docs/Clear-TririgaBusinessObject.md>`_,"Clears Business Object Records, removes stale data (12 hrs and older)"
    `Clear-TririgaCache <docs/Clear-TririgaCache.md>`_,Clears a cache
    `Get-TririgaCacheHierarchyTree <docs/Get-TririgaCacheHierarchyTree.md>`_,Gets the hierarchy tree cache status details
    `Get-TririgaCacheMode <docs/Get-TririgaCacheMode.md>`_,Gets the cache processing mode
    `Set-TririgaCacheMode <docs/Set-TririgaCacheMode.md>`_,Sets the cache processing mode
    `Get-TririgaDatabase <docs/Get-TririgaDatabase.md>`_,Gets the database environment information
    `Clear-TririgaDatabaseAll <docs/Clear-TririgaDatabaseAll.md>`_,Runs a full database cleanup
    `Get-TririgaDatabaseSpace <docs/Get-TririgaDatabaseSpace.md>`_,Gets the database space information
    `Invoke-TririgaDatabaseTask <docs/Invoke-TririgaDatabaseTask.md>`_,Invokes a database task
    `Write-TririgaLogMessage <docs/Write-TririgaLogMessage.md>`_,Write a message to TRIRIGA Log file
    `Reload-TririgaPlatformLogging <docs/Reload-TririgaPlatformLogging.md>`_,Reload logging categories from disk
    `Disable-TririgaPlatformLogging <docs/Disable-TririgaPlatformLogging.md>`_,Disables TRIRIGA platform Logging for the given categories
    `Enable-TririgaPlatformLogging <docs/Enable-TririgaPlatformLogging.md>`_,Enables TRIRIGA platform Logging for the given categories
    `Get-TririgaPlatformLogging <docs/Get-TririgaPlatformLogging.md>`_,Gets information about TRIRIGA platform Logging
    `Sync-TririgaPlatformLogging <docs/Sync-TririgaPlatformLogging.md>`_,Reload logging categories from disk
    `Add-TririgaPlatformLoggingCategory <docs/Add-TririgaPlatformLoggingCategory.md>`_,Add a new platform logging category and level
    `Reset-TririgaPlatformLoggingDuplicates <docs/Reset-TririgaPlatformLoggingDuplicates.md>`_,Reset duplicate categories
    `Get-TririgaProperty <docs/Get-TririgaProperty.md>`_,Gets a setting in a TRIRIGA properties file
    `Set-TririgaProperty <docs/Set-TririgaProperty.md>`_,Sets settings in a TRIRIGA properties file
    `Clear-TririgaScheduledEvent <docs/Clear-TririgaScheduledEvent.md>`_,Clears Scheduled Events
    `Get-TririgaServerInformation <docs/Get-TririgaServerInformation.md>`_,Retrieves information about the TRIRIGA server.
    `Get-TririgaServerXml <docs/Get-TririgaServerXml.md>`_,Get the WebSphere Liberty server.xml file
    `Get-TririgaSummary <docs/Get-TririgaSummary.md>`_,Gets basic information about a TRIRIGA instance
    `Lock-TririgaSystem <docs/Lock-TririgaSystem.md>`_,Locks the TRIRIGA server
    `Unlock-TririgaSystem <docs/Unlock-TririgaSystem.md>`_,Unlocks the TRIRIGA server
    `Clear-TririgaWorkflowInstance <docs/Clear-TririgaWorkflowInstance.md>`_,Clears Workflow Instance data
    `Disable-TririgaWorkflowInstance <docs/Disable-TririgaWorkflowInstance.md>`_,Sets the workflow instance recording setting to ERRORS_ONLY
    `Enable-TririgaWorkflowInstance <docs/Enable-TririgaWorkflowInstance.md>`_,Sets the workflow instance recording setting to ALWAYS
    `Set-TririgaWorkflowInstance <docs/Set-TririgaWorkflowInstance.md>`_,Updates workflow instance recording setting
.. ##END TABLE TRIRIGA MANAGE REST

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
