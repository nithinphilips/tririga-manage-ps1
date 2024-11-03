Developer README
================

Development
-----------
To load the module from the project directory:

.. code:: ps1

    . SetupDev.ps1

To see debug log messages, set:

.. code:: ps1

    $VerbosePreference = "Continue"

To run tests:

.. code:: ps1

    make check


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

        make git-tag

#. Push all changes::

        git push && git push --tags

#. Release::

        make release

PowerShell
----------
* https://learn.microsoft.com/en-us/powershell/gallery/concepts/publishing-guidelines
* https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands
* https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/required-development-guidelines
* https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/windows-powershell-cmdlet-concepts
* https://learn.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-module-manifest
* https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-shouldprocess
* https://learn.microsoft.com/en-us/powershell/scripting/samples/using-format-commands-to-change-output-view
* https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer
* https://pester.dev/docs/quick-start
