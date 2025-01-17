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
        #
        # Username and Password (non-SSO) for use with the REST api calls is
        # stored encrypted. Run ``Set-TririgaCredential`` command to store it.
        #
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
