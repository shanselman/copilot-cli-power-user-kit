$ErrorActionPreference = 'Stop'

$guard = Join-Path $PSScriptRoot '..\.github\hooks\scripts\pre-tool-use-guard.ps1'
$cases = @(
    @{ Name = 'status allowed'; Command = 'git status --short'; Expected = 'allow' },
    @{ Name = 'tests allowed'; Command = 'npm test'; Expected = 'allow' },
    @{ Name = 'named output cleanup allowed'; Command = 'Remove-Item -Recurse -LiteralPath .\build'; Expected = 'allow' },
    @{ Name = 'hard reset blocked'; Command = 'git reset --hard HEAD~1'; Expected = 'deny' },
    @{ Name = 'forced clean blocked'; Command = 'git clean -fdx'; Expected = 'deny' },
    @{ Name = 'forced push blocked'; Command = 'git push --force-with-lease'; Expected = 'deny' },
    @{ Name = 'root deletion blocked'; Command = 'rm -rf /'; Expected = 'deny' },
    @{ Name = 'current directory deletion blocked'; Command = 'Remove-Item -Recurse -Force .'; Expected = 'deny' }
)

foreach ($case in $cases) {
    $payload = @{
        sessionId = 'test-session'
        timestamp = 0
        cwd = $PSScriptRoot
        toolName = 'powershell'
        toolArgs = @{ command = $case.Command }
    } | ConvertTo-Json -Compress

    $actual = $payload | & pwsh -NoProfile -File $guard | ConvertFrom-Json
    if ($actual.permissionDecision -ne $case.Expected) {
        throw "$($case.Name): expected $($case.Expected), got $($actual.permissionDecision)"
    }
}

$malformed = '{}' | & pwsh -NoProfile -File $guard | ConvertFrom-Json
if ($malformed.permissionDecision -ne 'deny') {
    throw 'Malformed payload must be denied.'
}

$env:COPILOT_GUARD_EXTRA_BLOCK_REGEX = '['
$payload = @{
    toolName = 'powershell'
    toolArgs = @{ command = 'git status' }
} | ConvertTo-Json -Compress
$invalidRegex = $payload | & pwsh -NoProfile -File $guard | ConvertFrom-Json
Remove-Item Env:\COPILOT_GUARD_EXTRA_BLOCK_REGEX
if ($invalidRegex.permissionDecision -ne 'deny') {
    throw 'Invalid custom regex must be denied.'
}

Write-Host "PowerShell guard: $($cases.Count + 2) cases passed."
