---
external help file: Tririga-Manage-Rest-help.xml
Module Name: Tririga-Manage-Rest
online version:
schema: 2.0.0
---

# Get-TririgaProperty

## SYNOPSIS
Gets a setting in a TRIRIGA properties file

## SYNTAX

```
Get-TririgaProperty [-environment] <String> [-instance <String>] [-file <String>] [[-property] <String[]>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets a setting in a TRIRIGA properties file

Uses the /api/v1/admin/systemInfo/properties/list method

## EXAMPLES

### EXAMPLE 1
```
Get-TririgaProperty LOCAL
Reserve                            : N
USE_AUTO_COMPLETE_IN_SMART_SECTION : Y
...
file                               : TRIRIGAWEB
environment                        : LOCAL
instance                           : ONE
...
```

### EXAMPLE 2
```
Get-TririgaProperty LOCAL -Instance ONE
Reserve                            : N
USE_AUTO_COMPLETE_IN_SMART_SECTION : Y
...
file                               : TRIRIGAWEB
environment                        : LOCAL
instance                           : ONE
```

### EXAMPLE 3
```
Get-TririgaProperty LOCAL SSO
SSO         : N
file        : TRIRIGAWEB
environment : LOCAL
instance    : ONE
```

### EXAMPLE 4
```
Get-TririgaProperty LOCAL SSO, SSO_REMOTE_USER
environment     : LOCAL
instance        : ONE
file            : TRIRIGAWEB
SSO             : N
SSO_REMOTE_USER : Y
```

### EXAMPLE 5
```
@("SSO", "SSO_REMOTE_USER") | Get-TririgaProperty LOCAL
environment     : LOCAL
instance        : ONE
file            : TRIRIGAWEB
SSO             : N
SSO_REMOTE_USER : Y
```

### EXAMPLE 6
```
Get-TririgaProperty LOCAL FRONT_END_SERVER, SSO | %  { $_.FRONT_END_SERVER = $_.FRONT_END_SERVER.replace("http", "https"); $_ } | Set-TririgaProperty
environment      : LOCAL
instance         : ONE
file             : TRIRIGAWEB
FRONT_END_SERVER : https://localhost:9080/
SSO              : N
```

## PARAMETERS

### -environment
The TRIRIGA environment to use.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Env, E

Required: True
Position: 1
Default value: None
Accept pipeline input: False
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
Accept pipeline input: False
Accept wildcard characters: False
```

### -instance
The TRIRIGA instance within the environment to use.
If omitted, command will act on all instances

```yaml
Type: String
Parameter Sets: (All)
Aliases: Inst, I

Required: False
Position: Named
Default value: None
Accept pipeline input: False
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
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### An array of property names
## OUTPUTS

### A PSCustomObject with properties from file.
### The object will also have these 3 properties: environment, instance, file.
### These allow you to pipe the output into Set-Property.
## NOTES

## RELATED LINKS
