[CmdletBinding()]
param(
    [switch]$Strict,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Paths
)

$ErrorActionPreference = 'Stop'
$root = (git rev-parse --show-toplevel 2>$null)
if (-not $root) { $root = (Get-Location).Path }
Set-Location -LiteralPath $root

$documents = if ($Paths) {
    foreach ($path in $Paths) {
        if (Test-Path -LiteralPath $path -PathType Leaf) { Get-Item -LiteralPath $path }
    }
} else {
    Get-ChildItem -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }
}

$checked = 0
$drift = 0
foreach ($document in $documents | Sort-Object FullName -Unique) {
    $lines = @(Get-Content -LiteralPath $document.FullName)
    for ($index = 0; $index -lt $lines.Count; $index++) {
        foreach ($match in [regex]::Matches($lines[$index], '\]\((?<path>[^)#]+\.md):(?<line>\d+)\)')) {
            $checked++
            $relative = $match.Groups['path'].Value
            $resolved = [IO.Path]::GetFullPath((Join-Path $document.DirectoryName $relative))
            if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
                Write-Output ('DRIFT(missing-file) ' + $document.FullName + ' -> ' + $relative)
                $drift++
            } elseif ([int]$match.Groups['line'].Value -gt (Get-Content -LiteralPath $resolved).Count) {
                Write-Output ('DRIFT(line-oob) ' + $document.FullName + ' -> ' + $relative)
                $drift++
            }
        }
    }
}
Write-Output ('anchors_checked=' + $checked + ' drift=' + $drift)
if ($Strict -and $drift -gt 0) { exit 1 }
