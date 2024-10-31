@{
    "LOCAL" = @{
        # If $true, any actions that might affect the environment will require confirmation
        Warn = $False;
        # The DBeaver profile associated with this environment
        DbProfile = "Tririga Local";
        # Tririga Username and Password (non-SSO) for use with the REST api calls
        Username = "system";
        Password = "badadmin";
        # List all your TRIRIGA servers/instances
        Servers = @{
            # The key is the unique name you want to use for this instance
            "ONE" = @{
                # The hostname of this instance
                Host = "192.168.50.167"
                # The path where TRIRIGA is installed on the server
                Tririga = "C:\IBM\Tririga1"
                # The path where WebSphere profile is located on the server
                WebSphere = "C:\Program Files\IBM\WebSphere\AppServer\profiles\AppSrv01\logs\server1"
                # The Windows service that controls this TRIRIGA instance
                Service = "TestService1"
                # The URL to access this TRIRIGA instance
                Url = "http://192.168.50.167:9080"
                # Optional. Url that bypasses SSO (used when you use IIS auth).
                # For SAML SSO, leave this out
                ApiUrl = "http://192.168.50.167:9080"
                # The URL to access this instance's WebSphere console
                WasUrl = "http://example:9060/ibm/console"
                # Optional. This should be either hostname or if set, the
                # INSTANCE_NAME property in TRIRIGAWEB.properties This is used
                # to match agent host information to an instance
                InstanceName = "<ANY>"
                # If you cannot use Rest API to identify the ObjectMigration
                # server, indicate that this instance run the object migration
                # agent.
                ObjectMigrationAgent = $true
            };
            # Repeat for all other servers
            "TWO" = @{
                Host = "192.168.50.167"
                Tririga = "C:\IBM\Tririga1"
                WebSphere = "C:\Program Files\IBM\WebSphere\AppServer\profiles\AppSrv01\logs\server1"
                Service = "TestService1"
                Url = "http://192.168.50.167:9080"
                ApiUrl = "http://192.168.50.167:9080"
                WasUrl = "http://example:9060/ibm/console"
            };
        }
    };
}
