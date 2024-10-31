Developer README
================

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
