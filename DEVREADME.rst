Developer README
================

Development
-----------
To load the module from the project directory:

.. code:: ps1

    . SetupDev.ps1

Repeat the command to reload module.

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

   Use this model for changes that can be uniquely set on each server, such as
   a Property ``Get-Property`` and ``Set-Property``)

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
   with same nouns. Eg: ``Set-WorkflowInstance`` and ``Get-WorkflowInstance``
   must have the same semantics.

#. By default operate on the first instance in an environment, but can
   optionally operate on any specific instance or all instances with the
   ``-All`` switch (only where it makes sense).

   Use this models for commands that are ultimately database bound, such
   as ``Get-Agent`` or ``Start-Agent``.

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
           # By default only one instance is queried. Set this switch to query all instances.
           [switch]$all

       ...

       $apiCall = @{
            ...
            OnlyOnAnyOneInstance = !$all
            ...
       }

#. Any commands that will modify the system must implement the SupportsShouldProcess interface:

   .. code:: ps1

       [CmdletBinding(SupportsShouldProcess)]
       param(
            ...

   In most cases, all you need to do is pass ``OperationLabel`` to
   ``CallTririgaApi`` to activate confirmation. User will be asked to confirm
   change to each instance.

Publish
-------
To publish the modules to Gitea

#. Make sure all tests pass::

        make check

#. Edit ``install.ps1`` and update the version.
#. Build dist. This will update README and module definitions::

        make dist

#. Commmit changes
#. Create a tag::

        make git-tag

#. Push all changes::

        git push && git push --tags
        git push gitea && git push gitea --tags

#. Check for issues::

        make release-check

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
