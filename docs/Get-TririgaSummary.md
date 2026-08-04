---
external help file: Tririga-Manage-Rest-help.xml
Module Name: Tririga-Manage-Rest
online version:
schema: 2.0.0
---

# Get-TririgaSummary

## SYNOPSIS
Gets basic information about a TRIRIGA instance

## SYNTAX

```
Get-TririgaSummary [-environment] <String> [-instance <String>] [-all] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Gets basic information about a TRIRIGA instance

Uses the /api/v1/admin/summary method

## EXAMPLES

### EXAMPLE 1
```
Get-Summary Local -Raw | Select-Object databaseConnection
databaseConnection
------------------
jdbc:oracle:thin:@localhost:1521/XEPDB1
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
If omitted, command will act on the first instance.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
