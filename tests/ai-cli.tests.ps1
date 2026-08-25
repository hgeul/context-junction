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

    $firstNew = Invoke-Ai -Repository $testRoot -Arguments @('research', 'new', 'Spring Security OAuth2')
    $firstRelativePath = '.ai/research/requests/RES-20260824-001-spring-security-oauth2.md'
    Assert-True ($firstNew.ExitCode -eq 0) 'first research request exits successfully'
    Assert-True ($firstNew.Output -eq $firstRelativePath) 'first research request prints its relative path'

    $firstRequestPath = Join-Path $testRoot $firstRelativePath
    $firstRequest = Get-Content -LiteralPath $firstRequestPath -Raw
    Assert-True ($firstRequest -match '(?m)^RES-20260824-001\r?$') 'created request contains the generated ID'
    Assert-True ($firstRequest -match '(?m)^Spring Security OAuth2\r?$') 'created request contains the original topic'

    $waitingList = Invoke-Ai -Repository $testRoot -Arguments @('research', 'list')
    Assert-True ($waitingList.ExitCode -eq 0) 'research list exits successfully while a request waits'
    Assert-True ($waitingList.Output -match 'RES-20260824-001\s+WAITING\s+Spring Security OAuth2') 'research list marks request without a result as WAITING'

    $resultDirectory = Join-Path $testRoot '.ai/research/results'
    New-Item -ItemType Directory -Path $resultDirectory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $resultDirectory 'RES-20260824-001-spring-security-oauth2.md') -Value '# Research Result' -NoNewline -Encoding utf8

    $doneList = Invoke-Ai -Repository $testRoot -Arguments @('research', 'list')
    Assert-True ($doneList.ExitCode -eq 0) 'research list exits successfully when a result exists'
    Assert-True ($doneList.Output -match 'RES-20260824-001\s+DONE\s+Spring Security OAuth2') 'research list marks matching request and result as DONE'

    $secondNew = Invoke-Ai -Repository $testRoot -Arguments @('research', 'new', 'Spring Security OAuth2')
    Assert-True ($secondNew.ExitCode -eq 0) 'second research request exits successfully'
    Assert-True ($secondNew.Output -eq '.ai/research/requests/RES-20260824-002-spring-security-oauth2.md') 'second request uses the next same-day sequence'

    Write-Host "PASS: $script:Assertions assertions"
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
