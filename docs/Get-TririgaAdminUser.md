---
external help file: Tririga-Manage-Rest-help.xml
Module Name: Tririga-Manage-Rest
online version:
schema: 2.0.0
---

# Get-TririgaAdminUser

## SYNOPSIS
Gets a list of users who can access the TRIRIGA Admin Console

## SYNTAX

```
Get-TririgaAdminUser [-environment] <String> [-instance <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Gets a list of users with access to the TRIRIGA Admin Console

Not all listed users have active access.
They are in the Admin group an can be granted access.

Uses /api/v1/admin/users/list method

## EXAMPLES

### EXAMPLE 1
```
Get-TririgaAdminUser LOCAL | Where-Object fullaccess -eq True
userId fullaccess username fullName
------ ---------- -------- --------
221931       True system   System System
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
