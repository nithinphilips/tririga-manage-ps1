---
external help file: Tririga-Manage-Rest-help.xml
Module Name: Tririga-Manage-Rest
online version:
schema: 2.0.0
---

# Get-TririgaAgentHost

## SYNOPSIS
Gets the configured host(s) for the given agent

## SYNTAX

```
Get-TririgaAgentHost [-environment] <String> [-instance <String>] [-agent] <String> [-running] [-notRunning]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets the configured host(s) for the given agent

Uses the /api/v1/admin/agent/status method

## EXAMPLES

### EXAMPLE 1
```
Get-AgentHost -Environment LOCAL -Agent WFAgent | ForEach-Object { Write-Host "WFAgent is configured on $_" }
WFAgent is configured on localhost
WFAgent is configured on somewhere
```

### EXAMPLE 2
```
Get-AgentHost -Environment LOCAL -Agent WFAgent | ForEach-Object { Write-Host "WFAgent is running on $_" }
WFAgent is running on localhost
```

## PARAMETERS

### -agent
Set the type of agent to query.
Run 'Get-Agent' to see a list of all possible agent types.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
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

### -notRunning
If set, only list the host when the aget is not running

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

### -running
If set, only list the host when the agent is running

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
