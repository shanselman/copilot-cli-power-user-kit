$ErrorActionPreference = 'Stop'

function Write-Decision {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('allow', 'deny')]
        [string]$Decision,
        [string]$Reason
    )

    $output = [ordered]@{ permissionDecision = $Decision }
    if ($Decision -eq 'deny') {
        $output.permissionDecisionReason = $Reason
    }
    $output | ConvertTo-Json -Compress
    exit 0
}

try {
    $rawInput = [Console]::In.ReadToEnd()
    $payload = $rawInput | ConvertFrom-Json -ErrorAction Stop
    $toolName = if ($payload.toolName) { $payload.toolName } else { $payload.tool_name }
    $toolArgs = if ($null -ne $payload.toolArgs) { $payload.toolArgs } else { $payload.tool_input }

    if ([string]::IsNullOrWhiteSpace($toolName)) {
        Write-Decision -Decision deny -Reason 'Tool name could not be identified from the hook payload.'
    }

    if ($toolName -notin @('bash', 'powershell', 'Bash')) {
        Write-Decision -Decision allow
    }

    if ($toolArgs -is [string]) {
        try {
            $parsedArgs = $toolArgs | ConvertFrom-Json -ErrorAction Stop
            $command = if ($parsedArgs.command) { $parsedArgs.command } else { $parsedArgs.script }
        }
        catch {
            $command = $toolArgs
        }
    }
    else {
        $command = if ($toolArgs.command) { $toolArgs.command } else { $toolArgs.script }
    }

    if ([string]::IsNullOrWhiteSpace($command)) {
        Write-Decision -Decision deny -Reason 'Shell command could not be identified from the hook payload.'
    }

    $normalized = ($command -replace '\s+', ' ').Trim()
    $blockedPatterns = @(
        '(?i)(^|[;&|]\s*)git(\s+-C\s+\S+)?\s+reset\s+--hard(\s|$)',
        '(?i)(^|[;&|]\s*)git(\s+-C\s+\S+)?\s+clean(?=[^;&|]*(--force|\s-[a-z]*f))',
        '(?i)(^|[;&|]\s*)git(\s+-C\s+\S+)?\s+branch\s+-D(\s|$)',
        '(?i)(^|[;&|]\s*)git(\s+-C\s+\S+)?\s+push(?=[^;&|]*(--force-with-lease|--force|\s-[a-z]*f))',
        '(?i)(^|[;&|]\s*)git(\s+-C\s+\S+)?\s+checkout\s+--\s+(\.|\.\.|/|\*|\\)(\s|$)',
        '(?i)(^|[;&|]\s*)git(\s+-C\s+\S+)?\s+restore(?![^;&|]*--staged)(\s|$)',
        '(?i)(^|[;&|]\s*)rm\s+(?=[^;&|]*(--recursive|-[a-z]*r[a-z]*))(?=[^;&|]*(--force|-[a-z]*f[a-z]*))[^;&|]*\s(\.?\.?|/|\*|~|\$HOME|\$\{HOME\})([/\\*]?)(\s|$|[;&|])',
        '(?i)(^|[;&|]\s*)(Remove-Item|rm|ri)\s+(?=[^;&|]*-Recurse)[^;&|]*(\s|^)(\.|\.\.|[A-Z]:\\|\\\\[^\\]+\\[^\\]+\\?|\$HOME|\$env:USERPROFILE)([\\*]?)(\s|$|[;&|])'
    )

    foreach ($pattern in $blockedPatterns) {
        if ($normalized -match $pattern) {
            Write-Decision -Decision deny -Reason 'Blocked a recognized destructive Git operation or broad recursive deletion.'
        }
    }

    if ($env:COPILOT_GUARD_EXTRA_BLOCK_REGEX) {
        try {
            if ($normalized -match "(?i)$($env:COPILOT_GUARD_EXTRA_BLOCK_REGEX)") {
                Write-Decision -Decision deny -Reason 'Blocked by COPILOT_GUARD_EXTRA_BLOCK_REGEX.'
            }
        }
        catch {
            Write-Decision -Decision deny -Reason 'COPILOT_GUARD_EXTRA_BLOCK_REGEX is invalid.'
        }
    }

    Write-Decision -Decision allow
}
catch {
    Write-Decision -Decision deny -Reason 'The guard could not safely parse or evaluate the hook payload.'
}
