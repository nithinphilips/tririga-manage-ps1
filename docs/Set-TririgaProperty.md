---
external help file: Tririga-Manage-Rest-help.xml
Module Name: Tririga-Manage-Rest
online version:
schema: 2.0.0
---

# Set-TririgaProperty

## SYNOPSIS
Sets settings in a TRIRIGA properties file

## SYNTAX

### SingleProperty
```
Set-TririgaProperty [[-environment] <String>] [-instance <String>] [-file <String>] [[-property] <String>]
 [[-value] <String>] [-full] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PropertyObject
```
Set-TririgaProperty [[-environment] <String>] [-instance <String>] [-file <String>] [-propertyObject <Object>]
 [-full] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Sets settings in a TRIRIGA properties file

Uses the /api/v1/admin/systemInfo/properties/update method

## EXAMPLES

### EXAMPLE 1
```
Set-TririgaProperty LOCAL SSO N
environment instance file       SSO
----------- -------- ----       ---
LOCAL       ONE      TRIRIGAWEB N
```

### EXAMPLE 2
```
@{ "SSO" = "N" } | Set-TririgaProperty LOCAL
environment     : LOCAL
instance        : ONE
file            : TRIRIGAWEB
SSO             : N
```

### EXAMPLE 3
```
@{ "SSO" = "N"; "SSO_REMOTE_USER" = "Y" } | Set-TririgaProperty LOCAL
environment     : LOCAL
instance        : ONE
file            : TRIRIGAWEB
SSO_REMOTE_USER : Y
SSO             : N
```

### EXAMPLE 4
```
Get-TririgaProperty LOCAL FRONT_END_SERVER, SSO | %  { $_.FRONT_END_SERVER = $_.FRONT_END_SERVER.replace("http", "https"); $_ } | Set-TririgaProperty
environment      : LOCAL
instance         : ONE
file             : TRIRIGAWEB
FRONT_END_SERVER : https://localhost:9080/
SSO              : N
```

### EXAMPLE 5
```
[pscustomobject]@{ "environment"= "LOCAL"; "instance"= "ONE"; "file"= "TRIRIGAWEB"; "FRONT_END_SERVER"= "http://localhost:9080/"; "SSO"= "N"; } | Set-TririgaProperty
environment      : LOCAL
instance         : ONE
file             : TRIRIGAWEB
FRONT_END_SERVER : http://localhost:9080/
SSO              : N
```

## PARAMETERS

### -environment
The TRIRIGA environment to use.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Env, E

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -file
The properties file to load (without the .properties extension)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: TRIRIGAWEB
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -full
If set, the entire property file after the update is printed.
Otherwise, only the changes properties are printed

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -instance
The TRIRIGA instance within the environment to use.
If omitted, command will act on all instances.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Inst, I

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -property
Name of a single property to set

```yaml
Type: String
Parameter Sets: SingleProperty
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -propertyObject
An object with multiple properties

```yaml
Type: Object
Parameter Sets: PropertyObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -value
Value of a single property to set

```yaml
Type: String
Parameter Sets: SingleProperty
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### A hashtable with the properties and values to set
### A PSObject with the properties and values to set and environment, instance and file properties.
## OUTPUTS

### A PSCustomObject with changed properties
### The object will also have these 3 properties: environment, instance, file.
### NOTE: In some platform versions, the output may not reflect the change you made
###       until you restart the service.
## NOTES

## RELATED LINKS
