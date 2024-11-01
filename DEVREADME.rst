Developer README
================

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

To run tests:

.. code:: ps1

    Invoke-Pester

Check for script issues:

.. code:: ps1

    Invoke-ScriptAnalyzer -Recurse -Path Tririga-Manage | ft -AutoSize
    Invoke-ScriptAnalyzer -Recurse -Path Tririga-Manage-Rest | ft -AutoSize

Parameter Handling
------------------
We have commands that:

#. By default, operate on all instances in an environment, but can optionally
   operate on a single instance.

   .. code:: ps1

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
         ...
    )

#. If the command has other mandatory parameters, remove Position from ``$instance``.

   .. code:: ps1

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
         ...
         [Parameter(Mandatory, Position=1)]
         [string]$someArg
         ...
    )

   You may also want to remove Position from ``$instance`` to be consistent
   with same nouns. Eg: ``*-WorkflowInstance``

#. By default operate on the first instance in an environment, but can
   optionally operate on any specific instance.

   .. code:: ps1

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
