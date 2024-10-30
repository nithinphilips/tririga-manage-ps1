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
    :file: tririga-manage-ps1.csv


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

