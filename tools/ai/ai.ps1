$ErrorActionPreference = 'Stop'

function Write-CliError {
    param([string] $Message)

    [Console]::Error.WriteLine("ai: $Message")
    exit 1
}

function Get-GitRoot {
    param([string] $StartDirectory)

    $root = & git -C $StartDirectory rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($root | Out-String))) {
        Write-CliError 'run this command from inside a Git repository.'
    }

    return ($root | Select-Object -First 1).Trim()
}

function Get-AiPath {
    param(
        [string] $GitRoot,
        [string[]] $Parts
    )

    return Join-Path $GitRoot (Join-Path '.ai' ($Parts -join [System.IO.Path]::DirectorySeparatorChar))
}

function Test-ResearchId {
    param([string] $Id)

    return $Id -match '^RES-\d{8}-\d{3}$'
}

function Get-RequestDate {
    if ($env:AI_TEST_DATE) {
        if ($env:AI_TEST_DATE -notmatch '^\d{4}-\d{2}-\d{2}$') {
            Write-CliError 'AI_TEST_DATE must use YYYY-MM-DD.'
        }

        try {
            return [datetime]::ParseExact($env:AI_TEST_DATE, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture).ToString('yyyyMMdd')
        }
        catch {
            Write-CliError 'AI_TEST_DATE must be a valid calendar date.'
        }
    }

    return (Get-Date).ToString('yyyyMMdd')
}

function ConvertTo-TopicSlug {
    param([string] $Topic)

    $slug = [regex]::Replace($Topic.Trim().ToLowerInvariant(), '[^a-z0-9]+', '-')
    $slug = $slug.Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        return 'research'
    }

    return $slug
}

function Get-NextResearchSequence {
    param(
        [string] $RequestsPath,
        [string] $Date
    )

    $maximum = 0
    if (Test-Path -LiteralPath $RequestsPath -PathType Container) {
        foreach ($file in Get-ChildItem -LiteralPath $RequestsPath -File) {
            if ($file.Name -match "^RES-$Date-(?<sequence>\d{3})-.+\.md$") {
                $maximum = [math]::Max($maximum, [int]$Matches.sequence)
            }
        }
    }

    if ($maximum -ge 999) {
        Write-CliError "no request ID remains for $Date."
    }

    return $maximum + 1
}

function Get-ResearchTopic {
    param([string] $RequestPath)

    $content = Get-Content -LiteralPath $RequestPath -Raw
    $topicMatch = [regex]::Match($content, '(?ms)^## 주제\r?\n(?<topic>.*?)\r?\n\r?\n## ')
    if (-not $topicMatch.Success) {
        Write-CliError "request '$($RequestPath | Split-Path -Leaf)' does not contain a valid topic section."
    }

    return $topicMatch.Groups['topic'].Value.Trim()
}

function New-ResearchRequest {
    param(
        [string] $GitRoot,
        [string] $Topic
    )

    if ([string]::IsNullOrWhiteSpace($Topic)) {
        Write-CliError 'research new requires a topic.'
    }

    $requestsPath = Get-AiPath -GitRoot $GitRoot -Parts @('research', 'requests')
    $resultsPath = Get-AiPath -GitRoot $GitRoot -Parts @('research', 'results')
    $templatePath = Get-AiPath -GitRoot $GitRoot -Parts @('templates', 'research-request.md')
    if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
        Write-CliError 'research request template is missing.'
    }

    $date = Get-RequestDate
    $sequence = Get-NextResearchSequence -RequestsPath $requestsPath -Date $date
    $id = 'RES-{0}-{1:D3}' -f $date, $sequence
    if (-not (Test-ResearchId $id)) {
        Write-CliError 'generated an invalid research ID.'
    }

    $slug = ConvertTo-TopicSlug $Topic
    $template = Get-Content -LiteralPath $templatePath -Raw
    $newLine = if ($template.Contains("`r`n")) { "`r`n" } else { "`n" }
    $topicPlaceholder = "## 주제${newLine}${newLine}"
    if (-not $template.Contains('RES-YYYYMMDD-NNN') -or -not $template.Contains($topicPlaceholder)) {
        Write-CliError 'research request template has required placeholders missing.'
    }

    $document = $template.Replace('RES-YYYYMMDD-NNN', $id).Replace($topicPlaceholder, "## 주제${newLine}$Topic${newLine}${newLine}")
    try {
        New-Item -ItemType Directory -Path @($requestsPath, $resultsPath) -Force | Out-Null
    }
    catch {
        Write-CliError 'could not create research request.'
    }
    $requestName = "$id-$slug.md"
    $requestPath = Join-Path $requestsPath $requestName
    if (Test-Path -LiteralPath $requestPath) {
        Write-CliError "request '$requestName' already exists."
    }

    try {
        Set-Content -LiteralPath $requestPath -Value $document -NoNewline -Encoding utf8
    }
    catch {
        Write-CliError 'could not create research request.'
    }
    Write-Output (Join-Path '.ai/research/requests' $requestName).Replace('\', '/')
}

function Get-ResearchList {
    param([string] $GitRoot)

    $requestsPath = Get-AiPath -GitRoot $GitRoot -Parts @('research', 'requests')
    $resultsPath = Get-AiPath -GitRoot $GitRoot -Parts @('research', 'results')
    $resultIds = @{}
    if (Test-Path -LiteralPath $resultsPath -PathType Container) {
        foreach ($result in Get-ChildItem -LiteralPath $resultsPath -File) {
            if ($result.Name -match '^(?<id>RES-\d{8}-\d{3})-.+\.md$' -and (Test-ResearchId $Matches.id)) {
                $resultIds[$Matches.id] = $true
            }
        }
    }

    Write-Output 'ID                 STATUS   TOPIC'
    Write-Output '---------------------------------------------'
    if (-not (Test-Path -LiteralPath $requestsPath -PathType Container)) {
        return
    }

    foreach ($request in Get-ChildItem -LiteralPath $requestsPath -File | Sort-Object Name) {
        if ($request.Name -notmatch '^(?<id>RES-\d{8}-\d{3})-.+\.md$' -or -not (Test-ResearchId $Matches.id)) {
            continue
        }

        $id = $Matches.id
        $status = if ($resultIds.ContainsKey($id)) { 'DONE' } else { 'WAITING' }
        $topic = Get-ResearchTopic $request.FullName
        Write-Output ('{0,-18} {1,-8} {2}' -f $id, $status, $topic)
    }
}

function Get-ResearchRequests {
    param([string] $GitRoot)

    $requestsPath = Get-AiPath -GitRoot $GitRoot -Parts @('research', 'requests')
    if (-not (Test-Path -LiteralPath $requestsPath -PathType Container)) {
        return @()
    }

    return @(Get-ChildItem -LiteralPath $requestsPath -File | Where-Object {
        $_.Name -match '^(?<id>RES-\d{8}-\d{3})-.+\.md$' -and (Test-ResearchId $Matches.id)
    } | Sort-Object Name)
}

function Get-ResearchResultIds {
    param([string] $GitRoot)

    $resultIds = @{}
    $resultsPath = Get-AiPath -GitRoot $GitRoot -Parts @('research', 'results')
    if (Test-Path -LiteralPath $resultsPath -PathType Container) {
        foreach ($result in Get-ChildItem -LiteralPath $resultsPath -File) {
            if ($result.Name -match '^(?<id>RES-\d{8}-\d{3})-.+\.md$' -and (Test-ResearchId $Matches.id)) {
                $resultIds[$Matches.id] = $true
            }
        }
    }

    return $resultIds
}

function Get-MarkdownFileCount {
    param([string] $Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return 0
    }

    return @(Get-ChildItem -LiteralPath $Path -File -Filter '*.md' | Where-Object { $_.Name -notlike '_*' }).Count
}

function Show-Status {
    param([string] $GitRoot)

    $requests = Get-ResearchRequests -GitRoot $GitRoot
    $resultIds = Get-ResearchResultIds -GitRoot $GitRoot
    $waiting = @($requests | Where-Object {
        $_.Name -match '^(?<id>RES-\d{8}-\d{3})-' -and -not $resultIds.ContainsKey($Matches.id)
    })
    $done = $requests.Count - $waiting.Count
    $branch = (& git -C $GitRoot branch --show-current 2>$null | Select-Object -First 1).Trim()

    Write-Output "Repository: $(Split-Path -Leaf $GitRoot)"
    Write-Output "Branch: $branch"
    Write-Output "Research Pending: $($waiting.Count)"
    Write-Output "Research Done: $done"
    Write-Output "Plans Total: $(Get-MarkdownFileCount (Get-AiPath -GitRoot $GitRoot -Parts @('plans')))"
    Write-Output "Decisions Total: $(Get-MarkdownFileCount (Join-Path $GitRoot (Join-Path 'docs' 'decisions')))"
    if ($waiting.Count -gt 0) {
        $latest = $waiting[-1]
        $latestId = [regex]::Match($latest.Name, '^RES-\d{8}-\d{3}').Value
        Write-Output "Latest Waiting: $latestId $(Get-ResearchTopic $latest.FullName)"
    }
}

function Copy-ResearchRequest {
    param(
        [string] $GitRoot,
        [string] $Id
    )

    $requests = Get-ResearchRequests -GitRoot $GitRoot
    if ([string]::IsNullOrWhiteSpace($Id)) {
        $resultIds = Get-ResearchResultIds -GitRoot $GitRoot
        $request = @($requests | Where-Object {
            $_.Name -match '^(?<id>RES-\d{8}-\d{3})-' -and -not $resultIds.ContainsKey($Matches.id)
        } | Select-Object -Last 1)
        if ($request.Count -eq 0) {
            Write-CliError 'no waiting research request exists.'
        }
    }
    else {
        if (-not (Test-ResearchId $Id)) {
            Write-CliError 'research copy requires a RES-YYYYMMDD-NNN ID.'
        }

        $request = @($requests | Where-Object { $_.Name -match "^$([regex]::Escape($Id))-" } | Select-Object -First 1)
        if ($request.Count -eq 0) {
            Write-CliError "request '$Id' was not found."
        }
    }

    $requestText = Get-Content -LiteralPath $request[0].FullName -Raw
    try {
        Set-Clipboard -Value $requestText
    }
    catch {
        Write-CliError 'clipboard is unavailable.'
    }
    $requestId = [regex]::Match($request[0].Name, '^RES-\d{8}-\d{3}').Value
    Write-Output "Copied $requestId."
}

try {
    $gitRoot = Get-GitRoot -StartDirectory (Get-Location).Path
    if ($args.Count -eq 0) {
        Write-CliError 'expected status or research command.'
    }

    switch ($args[0]) {
        'research' {
            if ($args.Count -lt 2) {
                Write-CliError 'expected research new, research list, or research copy.'
            }

            switch ($args[1]) {
                'new' {
                    if ($args.Count -ne 3) {
                        Write-CliError 'usage: ai research new <topic>'
                    }

                    New-ResearchRequest -GitRoot $gitRoot -Topic $args[2]
                    break
                }
                'list' {
                    if ($args.Count -ne 2) {
                        Write-CliError 'usage: ai research list'
                    }

                    Get-ResearchList -GitRoot $gitRoot
                    break
                }
                'copy' {
                    if ($args.Count -gt 3) {
                        Write-CliError 'usage: ai research copy [RES-YYYYMMDD-NNN]'
                    }

                    $id = if ($args.Count -eq 3) { $args[2] } else { $null }
                    Copy-ResearchRequest -GitRoot $gitRoot -Id $id
                    break
                }
                default { Write-CliError 'expected research new, research list, or research copy.' }
            }
            break
        }
        'status' {
            if ($args.Count -ne 1) {
                Write-CliError 'usage: ai status'
            }

            Show-Status -GitRoot $gitRoot
            break
        }
        default { Write-CliError 'expected status or research command.' }
    }
}
catch {
    Write-CliError 'command failed.'
}
