---
external help file: Tririga-Manage-help.xml
Module Name: Tririga-Manage
online version: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enter-pssession
schema: 2.0.0
---

# Enter-TririgaHost

## SYNOPSIS
Starts a remote powershell session to a TRIRIGA instance

## SYNTAX

```
Enter-TririgaHost [-environment] <String> [-instance] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Starts a remote powershell session to a TRIRIGA instance using the Enter-PSSession command.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

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

```yaml
Type: String
Parameter Sets: (All)
Aliases: Inst, I

Required: True
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enter-pssession](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enter-pssession)
