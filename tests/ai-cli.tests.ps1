$ErrorActionPreference = 'Stop'

$script:Assertions = 0

function Assert-True {
    param(
        [bool] $Condition,
        [string] $Message
    )

    $script:Assertions++
    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

function Invoke-Ai {
    param(
        [string] $Repository,
        [string[]] $Arguments
    )

    $previousLocation = Get-Location
    $previousTestDate = $env:AI_TEST_DATE
    try {
        Set-Location -LiteralPath $Repository
        $env:AI_TEST_DATE = '2026-08-24'
        $output = & pwsh -NoProfile -File (Join-Path $Repository 'tools/ai/ai.ps1') @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        Set-Location -LiteralPath $previousLocation
        $env:AI_TEST_DATE = $previousTestDate
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = ($output | Out-String).Trim()
    }
}

function Invoke-AiInProcess {
    param(
        [string] $Repository,
        [string[]] $Arguments
    )

    $previousLocation = Get-Location
    $previousTestDate = $env:AI_TEST_DATE
    try {
        Set-Location -LiteralPath $Repository
        $env:AI_TEST_DATE = '2026-08-24'
        $output = & (Join-Path $Repository 'tools/ai/ai.ps1') @Arguments
    }
    finally {
        Set-Location -LiteralPath $previousLocation
        $env:AI_TEST_DATE = $previousTestDate
    }

    return ($output | Out-String).Trim()
}

function Invoke-AiWithClipboardFailure {
    param(
        [string] $Repository,
        [string] $WrapperPath,
        [string] $CliPath,
        [string] $Id
    )

    $output = & pwsh -NoProfile -File $WrapperPath -Repository $Repository -CliPath $CliPath -Id $Id 2>&1
    $exitCode = $LASTEXITCODE
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = ($output | Out-String).Trim()
    }
}

function global:Set-Clipboard {
    param([string] $Value)

    $global:AiCliTestClipboardValue = $Value
}

$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ai-cli-tests-" + [guid]::NewGuid().ToString('N'))
$sourceRoot = Split-Path -Parent $PSScriptRoot

try {
    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
    & git -C $testRoot init -q
    Assert-True ($LASTEXITCODE -eq 0) 'temporary Git repository initializes'

    $templateDestination = Join-Path $testRoot '.ai/templates'
    New-Item -ItemType Directory -Path $templateDestination -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $sourceRoot '.ai/templates/research-request.md') -Destination $templateDestination

    $sourceCli = Join-Path $sourceRoot 'tools/ai/ai.ps1'
    Assert-True (Test-Path -LiteralPath $sourceCli -PathType Leaf) 'CLI entrypoint exists before integration tests run'

    $cliDestination = Join-Path $testRoot 'tools/ai'
    New-Item -ItemType Directory -Path $cliDestination -Force | Out-Null
    Copy-Item -LiteralPath $sourceCli -Destination $cliDestination
    $clipboardFailureWrapper = Join-Path $testRoot 'clipboard-failure-wrapper.ps1'
    @'
param(
    [string] $Repository,
    [string] $CliPath,
    [string] $Id
)

function global:Set-Clipboard {
    param([string] $Value)

    throw 'simulated clipboard failure'
}

Set-Location -LiteralPath $Repository
& $CliPath research copy $Id
exit $LASTEXITCODE
'@ | Set-Content -LiteralPath $clipboardFailureWrapper -NoNewline -Encoding utf8

    $firstNew = Invoke-Ai -Repository $testRoot -Arguments @('research', 'new', 'Spring Security OAuth2')
    $firstRelativePath = '.ai/research/requests/RES-20260824-001-spring-security-oauth2.md'
    Assert-True ($firstNew.ExitCode -eq 0) 'first research request exits successfully'
    Assert-True ($firstNew.Output -eq $firstRelativePath) 'first research request prints its relative path'
    $resultDirectory = Join-Path $testRoot '.ai/research/results'
    Assert-True (Test-Path -LiteralPath $resultDirectory -PathType Container) 'research new creates the result directory immediately'

    $firstRequestPath = Join-Path $testRoot $firstRelativePath
    $firstRequest = Get-Content -LiteralPath $firstRequestPath -Raw
    Assert-True ($firstRequest -match '(?m)^RES-20260824-001\r?$') 'created request contains the generated ID'
    Assert-True ($firstRequest -match '(?m)^Spring Security OAuth2\r?$') 'created request contains the original topic'
    $normalizedFirstRequest = $firstRequest.Replace("`r`n", "`n")
    Assert-True ($normalizedFirstRequest.Contains("## 주제`nSpring Security OAuth2`n`n## 목표`n")) 'created request preserves the blank line between Topic and Goal'

    $waitingList = Invoke-Ai -Repository $testRoot -Arguments @('research', 'list')
    Assert-True ($waitingList.ExitCode -eq 0) 'research list exits successfully while a request waits'
    $waitingRows = @($waitingList.Output -split '\r?\n')
    Assert-True ($waitingRows.Count -eq 3) 'research list prints one header, separator, and data row for one waiting request'
    Assert-True ($waitingRows[2] -eq 'RES-20260824-001   WAITING  Spring Security OAuth2') 'research list prints exact ID, WAITING status, and single-line Topic fields'

    Set-Content -LiteralPath (Join-Path $resultDirectory 'RES-20260824-001-spring-security-oauth2.md') -Value '# Research Result' -NoNewline -Encoding utf8

    $doneList = Invoke-Ai -Repository $testRoot -Arguments @('research', 'list')
    Assert-True ($doneList.ExitCode -eq 0) 'research list exits successfully when a result exists'
    $doneRows = @($doneList.Output -split '\r?\n')
    Assert-True ($doneRows.Count -eq 3) 'research list prints one header, separator, and data row for one completed request'
    Assert-True ($doneRows[2] -eq 'RES-20260824-001   DONE     Spring Security OAuth2') 'research list prints exact ID, DONE status, and single-line Topic fields'

    $secondNew = Invoke-Ai -Repository $testRoot -Arguments @('research', 'new', 'Spring Security OAuth2')
    Assert-True ($secondNew.ExitCode -eq 0) 'second research request exits successfully'
    Assert-True ($secondNew.Output -eq '.ai/research/requests/RES-20260824-002-spring-security-oauth2.md') 'second request uses the next same-day sequence'

    $plansDirectory = Join-Path $testRoot '.ai/plans'
    New-Item -ItemType Directory -Path $plansDirectory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $plansDirectory 'PLAN-20260824-001-oauth.md') -Value '# Plan' -NoNewline -Encoding utf8
    $decisionsDirectory = Join-Path $testRoot '.ai/decisions'
    New-Item -ItemType Directory -Path $decisionsDirectory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $decisionsDirectory 'ADR-001-oauth.md') -Value '# Decision' -NoNewline -Encoding utf8

    $branch = (& git -C $testRoot branch --show-current).Trim()
    $status = Invoke-Ai -Repository $testRoot -Arguments @('status')
    Assert-True ($status.ExitCode -eq 0) 'status exits successfully'
    Assert-True ($status.Output -match [regex]::Escape("Repository: $(Split-Path -Leaf $testRoot)")) 'status prints the repository name'
    Assert-True ($status.Output -match [regex]::Escape("Branch: $branch")) 'status prints the current branch'
    Assert-True ($status.Output -match 'Research Pending: 1') 'status counts only waiting request files as pending research'
    Assert-True ($status.Output -match 'Research Done: 1') 'status counts only request files with matching results as done research'
    Assert-True ($status.Output -match 'Plans Total: 1') 'status counts plan markdown files without a status'
    Assert-True ($status.Output -match 'Decisions Total: 1') 'status counts ADR markdown files without a status'
    Assert-True ($status.Output -match 'Latest Waiting: RES-20260824-002 Spring Security OAuth2') 'status prints the newest waiting request ID and topic'

    $firstRequestText = Get-Content -LiteralPath $firstRequestPath -Raw
    $global:AiCliTestClipboardValue = $null
    $explicitCopyOutput = Invoke-AiInProcess -Repository $testRoot -Arguments @('research', 'copy', 'RES-20260824-001')
    Assert-True ($global:AiCliTestClipboardValue -eq $firstRequestText) 'research copy sends the explicitly selected request text to the in-process clipboard shim'
    Assert-True ($explicitCopyOutput -eq 'Copied RES-20260824-001.') 'research copy confirms the explicit request ID'

    $clipboardFailure = Invoke-AiWithClipboardFailure -Repository $testRoot -WrapperPath $clipboardFailureWrapper -CliPath (Join-Path $cliDestination 'ai.ps1') -Id 'RES-20260824-001'
    Assert-True ($clipboardFailure.ExitCode -ne 0) 'research copy exits nonzero when the clipboard is unavailable'
    Assert-True ($clipboardFailure.Output -eq 'ai: clipboard is unavailable.') 'research copy reports clipboard failure without raw PowerShell diagnostics'

    $secondRequestPath = Join-Path $testRoot '.ai/research/requests/RES-20260824-002-spring-security-oauth2.md'
    $secondRequestText = Get-Content -LiteralPath $secondRequestPath -Raw
    $global:AiCliTestClipboardValue = $null
    $defaultCopyOutput = Invoke-AiInProcess -Repository $testRoot -Arguments @('research', 'copy')
    Assert-True ($global:AiCliTestClipboardValue -eq $secondRequestText) 'research copy without an ID sends the newest waiting request text to the in-process clipboard shim'
    Assert-True ($defaultCopyOutput -eq 'Copied RES-20260824-002.') 'research copy confirms the newest waiting request ID'

    $koreanTopic = '한국어 조사 주제'
    $koreanNew = Invoke-Ai -Repository $testRoot -Arguments @('research', 'new', $koreanTopic)
    $koreanRelativePath = '.ai/research/requests/RES-20260824-003-research.md'
    Assert-True ($koreanNew.ExitCode -eq 0) 'research new accepts a non-ASCII-only topic'
    Assert-True ($koreanNew.Output -eq $koreanRelativePath) 'non-ASCII-only topic uses the research fallback slug'
    $koreanRequest = (Get-Content -LiteralPath (Join-Path $testRoot $koreanRelativePath) -Raw).Replace("`r`n", "`n")
    Assert-True ($koreanRequest.Contains("## 주제`n$koreanTopic`n`n## 목표`n")) 'non-ASCII-only topic is preserved in the Topic field'

    $punctuationTopic = '?! — ...'
    $punctuationNew = Invoke-Ai -Repository $testRoot -Arguments @('research', 'new', $punctuationTopic)
    $punctuationRelativePath = '.ai/research/requests/RES-20260824-004-research.md'
    Assert-True ($punctuationNew.ExitCode -eq 0) 'research new accepts a punctuation-only topic'
    Assert-True ($punctuationNew.Output -eq $punctuationRelativePath) 'punctuation-only topic uses the research fallback slug'
    $punctuationRequest = (Get-Content -LiteralPath (Join-Path $testRoot $punctuationRelativePath) -Raw).Replace("`r`n", "`n")
    Assert-True ($punctuationRequest.Contains("## 주제`n$punctuationTopic`n`n## 목표`n")) 'punctuation-only topic is preserved in the Topic field'

    Set-Content -LiteralPath (Join-Path $resultDirectory 'RES-20260824-999-orphan.md') -Value '# Orphan Research Result' -NoNewline -Encoding utf8
    $afterOrphanResult = Invoke-Ai -Repository $testRoot -Arguments @('research', 'new', 'Request IDs Ignore Results')
    Assert-True ($afterOrphanResult.ExitCode -eq 0) 'an orphan result does not exhaust or reserve request IDs'
    Assert-True ($afterOrphanResult.Output -eq '.ai/research/requests/RES-20260824-005-request-ids-ignore-results.md') 'request ID allocation scans request files only'

    $emptyTopic = Invoke-Ai -Repository $testRoot -Arguments @('research', 'new', '')
    Assert-True ($emptyTopic.ExitCode -ne 0) 'research new with an empty topic exits nonzero'
    Assert-True ($emptyTopic.Output -eq 'ai: research new requires a topic.') 'research new with an empty topic reports a concise error'

    $missingRequest = Invoke-Ai -Repository $testRoot -Arguments @('research', 'copy', 'RES-20260824-999')
    Assert-True ($missingRequest.ExitCode -ne 0) 'research copy with an unknown exact ID exits nonzero'
    Assert-True ($missingRequest.Output -eq "ai: request 'RES-20260824-999' was not found.") 'research copy with an unknown exact ID reports a concise error'

    $missingResearchCommand = Invoke-Ai -Repository $testRoot -Arguments @('research')
    Assert-True ($missingResearchCommand.ExitCode -ne 0) 'research without a subcommand exits nonzero'
    Assert-True ($missingResearchCommand.Output -eq 'ai: expected research new, research list, or research copy.') 'missing research subcommand lists every supported research command'

    $unknownCommand = Invoke-Ai -Repository $testRoot -Arguments @('unknown')
    Assert-True ($unknownCommand.ExitCode -ne 0) 'an unknown command exits nonzero'
    Assert-True ($unknownCommand.Output -eq 'ai: expected status or research command.') 'an unknown command reports a concise error'

    $requestsDirectory = Join-Path $testRoot '.ai/research/requests'
    Move-Item -LiteralPath $requestsDirectory -Destination (Join-Path $testRoot '.ai/research/requests-backup')
    Set-Content -LiteralPath $requestsDirectory -Value 'directory collision' -NoNewline -Encoding utf8
    $fileSystemFailure = Invoke-Ai -Repository $testRoot -Arguments @('research', 'new', 'Blocked Request Write')
    Assert-True ($fileSystemFailure.ExitCode -ne 0) 'research new exits nonzero when request directories cannot be created'
    Assert-True ($fileSystemFailure.Output -eq 'ai: could not create research request.') 'research new reports filesystem failure without raw PowerShell diagnostics'

    Write-Host "PASS: $script:Assertions assertions"
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
