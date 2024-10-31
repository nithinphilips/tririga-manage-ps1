Change Log
==========

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
