---
external help file: Tririga-Manage-help.xml
Module Name: Tririga-Manage
online version: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enter-pssession
schema: 2.0.0
---

# Get-TririgaWasLog

## SYNOPSIS
Tails a WebSphere log file

## SYNTAX

```
Get-TririgaWasLog [-environment] <String> [[-instance] <String>] [-log <String>] [-tail <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Tails a WebSphere log file in the console

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

### -log
The log file to view.
Default is SystemOut.log.
Possible values are: out, err or the exact log file name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

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

### -tail
The initial number of lines to tail.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 10
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
