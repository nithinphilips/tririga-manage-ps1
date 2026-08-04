---
external help file: Tririga-Manage-Rest-help.xml
Module Name: Tririga-Manage-Rest
online version:
schema: 2.0.0
---

# Get-TririgaServerXml

## SYNOPSIS
Get the WebSphere Liberty server.xml file

## SYNTAX

```
Get-TririgaServerXml [-environment] <String> [[-instance] <String>] [-raw] [-all]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get the WebSphere Liberty server.xml file

Uses the /api/v1/admin/systemInfo/properties/serverXml method

## EXAMPLES

### EXAMPLE 1
```
Get-TririgaServerXml LOCAL
<server>
    ...
</server>
PS> (Get-TririgaServerXml LOCAL -Raw).server
description    : IBM TRIRIGA Application Platform
#comment       : { Enable features ,  HTTP Session timeout is invalidationTimeout, default of 1800 seconds }
featureManager : featureManager
httpEndpoint   : httpEndpoint
...
```

## PARAMETERS

### -all
By default only one instance is queried.
Set this switch to query all instances.

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

### -instance
The TRIRIGA instance within the environment to use.
If omitted, command will run on one instance.
Set -All switch to run on all instances.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Inst, I

Required: False
Position: 2
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

### -raw
By default the XML response is printed as text.
Set this switch to get a PSObject instead

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
