---
external help file: Tririga-Manage-help.xml
Module Name: Tririga-Manage
online version: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enter-pssession
schema: 2.0.0
---

# Get-TririgaInstance

## SYNOPSIS
Gets all known instances in a given environment

## SYNTAX

```
Get-TririgaInstance [[-environment] <String>] [-raw] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets a list of all known instances in a given environment

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -environment
The TRIRIGA environment to use.
If omitted all environments and instances will be printed.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Env, E

Required: False
Position: 1
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
If set, the object is returned as-is.

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
