---
external help file: Tririga-Manage-Rest-help.xml
Module Name: Tririga-Manage-Rest
online version:
schema: 2.0.0
---

# Get-TririgaActiveUser

## SYNOPSIS
Gets a list of currently logged in users

## SYNTAX

```
Get-TririgaActiveUser [-environment] <String> [[-instance] <String>] [-raw] [-unique]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets a list of currently logged in users

## EXAMPLES

### EXAMPLE 1
```
Get-TririgaActiveUser LOCAL | ft
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

### -instance
The TRIRIGA instance within the environment to use.
If omitted, command will act on all instances.

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
If set, the response object is returned as-is.
Otherwise it is printed as a table.

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

### -unique
If set, and not $raw, only print unique users no matter how many sessions they have

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
