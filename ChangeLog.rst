Change Log
==========

v4.7.0
------
* Support piping output of ``Get-TririgaProperty`` into ``Set-TririgaProperty``
* Add ``-All`` switch to ``Get-TririgaSummary`` and ``Get-TririgaServerXml`` to
  optionally run against all instances.
* Implement these new REST API methods

  * ``Get-CacheHierarchyTree``
  * ``Get-CacheMode``
  * ``Set-CacheMode``
  * ``Clear-Cache``
  * ``Get-Database``
  * ``Get-DatabaseSpace``
  * ``Invoke-DatabaseTask``
  * ``Clear-WorkflowInstance``
  * ``Clear-BusinessObject``
  * ``Clear-ScheduledEvent``
  * ``Clear-DatabaseAll``

* When running with ``-WhatIf`` or ``-Confirm``, confirmation is now done for
  each instance.

v4.6.0
------
* Implement these new REST API methods

  * ``Get-TririgaServerInformation``
  * ``Lock-TririgaSystem``
  * ``Unlock-TririgaSystem``
  * ``Get-TririgaProperty``
  * ``Set-TririgaProperty``
  * ``Add-TririgaPlatformLoggingCategory``
  * ``Get-TririgaServerXml``

v4.5.0
------
* Fix bug getting actual object migration agent in PS 5.1
* Improve output of ``Get-TririgaService``. It now has a ``-Raw`` switch.
* Document workaround for some functions not triggering module autoload in PS 5.1
* Implement ``Write-TririgaLogMessage``, ``Get-TririgaPlatformLogging``,
  ``Enable-TririgaPlatformLogging``, ``Disable-TririgaPlatformLogging``,
  ``Reset-TririgaPlatformLoggingDuplicates``
* Fix bug in peristing sessions

v4.4.0
------
* Fix bug in REST module returning results twice
* Implement ``-WhatIf`` flag in any commands that will make a change.
* Rename commands per PSScriptAnalyer recommendations:

  * Get-AdminUsers -> Get-AdminUser
  * Get-ActiveUsers -> Get-ActiveUser
  * Get-Agents -> Get-Agent

* Implement unit tests.
* Changes to production environments is now confirmed with a a Yes/No prompt,
  not a timer.

v4.3.0
------
* Bypasses secure cookies in WindowsPowerShell (previusly it was only possible in PS7)
* Update documentation for installation from PowerShell Gallery
* Configuration is now loaded as a `PowerShell Data file
  <https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_data_files>`_
* Better error handling when configuration is not found.

v4.2.0
------
* All Rest commands now output native powershell objects.
* ``Get-TririgaActiveUsers`` now works in PowerShell 5.1

v4.1.0
------
* Remove support for environment variables because the validation did not
  work 
* Rationalize ``Install.ps``

  * No arguments will install module to current profile and update profile
    file.
  * ``-UpdateModule`` switch will update module manifests (used with
    ``-NoInstallModule`` during dist)
  * ``-Publish`` switch will publish to Gitea

* ``make dist`` and ``make release`` will update module manifest
* ``make dist`` and ``make release`` will update readme
* Rename ``Upload-TririgaOmp`` to ``Save-TririgaOmp``. The ``Upload-`` verb is
  still available as an alias
* Rationalize command arguments.

  * ``-Environment`` is mandatory and can be given at position 0.
  * ``-Instance`` can be given at position 1, when command operates on all
    instances by default and has no other mandatory arguments.
  * In all other scenarios, ``-Instance`` must be named.

* Improved documentation

v4.0.0
------
* Rename all commands to align with `Approved Verbs for PowerShell Commands
  <https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.4>`__
* Environment argument can be set via environment variable
  ``$env:TRIRIGA_ENVIRONMENT``
* Instance argument can be set via environment variable
  ``$env:TRIRIGA_INSTANCE``
* ``Upload-TririgaOmp`` and ``Import-TririgaOmp`` can now find the server
  running the ObjectMigration agent using REST API.
* ``Upload-TririgaOmp`` and ``Import-TririgaOmp`` now correctly supports OMP
  file as wildcards or a list.
* ``Upload-TririgaOmp`` and ``Import-TririgaOmp`` will now ask the user to
  confirm if more than 5 OMPs are being processed.
* Functions are named in the module as ``Upload-Omp``, ``Import-Omp`` etc.
  A ``DefaultCommandPrefix`` value of *Tririga* is set, exposing the commands
  as ``Upload-TririgaOmp``, ``Import-TririgaOmp`` etc. Users can customize
  this alias if desired.
* Add more verbose level logging. You can enable it by passing the ``-Verbose``
  switch to any command or by setting ``$VerbosePreference = "Continue"`` to enable
  it globally.
* New packaging and distribution process.
* The environment configuration file is now loated in the same folder as the
  PowerShell ``$Profile``.
* The ``Install.ps1`` script will place a sample ``environment.ps1`` at the new 
  location if one already does not exist.

v3.0.0
------
* Reorganize as PowerShell modules
* Add new methods to use the TRIRIGA REST API

v2.0.0
------
* Split out environment configuration to a separate file
* Add a ``-install`` flag to source the file into profile without adding the
  entire content.

v1.0.0
------
* Initial release
