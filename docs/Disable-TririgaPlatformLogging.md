---
external help file: Tririga-Manage-Rest-help.xml
Module Name: Tririga-Manage-Rest
online version:
schema: 2.0.0
---

# Disable-TririgaPlatformLogging

## SYNOPSIS
Disables TRIRIGA platform Logging for the given categories

## SYNTAX

```
Disable-TririgaPlatformLogging [-environment] <String> [-instance <String>] [[-category] <String[]>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Disables TRIRIGA platform Logging for the given categories

If no category is given, all currently enabled categories will be disabled.

1.
To see available log categories, run:
        Get-TririgaPlatformLogging \<ENV\> -Level 1 | Select-Object description
   Increase level to see sub categories
2.
The -Category argument is the "description" of Get-TririgaPlatformLogging output .
   If you are looking in the TRIRIGA Admin Console, it is the name of the category that you see there.
3.
Multiple categories can be given.
See examples.
4.
If the description matches multiple categories, all matches will be enabled.

Uses the /api/v1/admin/platformLogging/enable method

## EXAMPLES

### EXAMPLE 1
```
Enable-PlatformLogging LOCAL "SQL", "Workflow Logging", "Data Integrator (DataImport) Agent"
```

## PARAMETERS

### -category
One or more categories to enable

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
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
If omitted, command will act on all instances.

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

## OUTPUTS

## NOTES

## RELATED LINKS
