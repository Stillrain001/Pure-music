[CmdletBinding()]
param(
    [switch]$Enforce
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$scanRoots = @(
    (Join-Path $projectRoot 'lib/page'),
    (Join-Path $projectRoot 'lib/component')
)

$rules = @(
    @{
        Name = 'direct Rust generated API import'
        Pattern = "package:pure_music/native/rust/api/"
    },
    @{
        Name = 'direct Dio client import'
        Pattern = "package:dio/dio.dart"
    },
    @{
        Name = 'direct HttpClient usage'
        Pattern = '\bHttpClient\b'
    }
)

$violations = [System.Collections.Generic.List[object]]::new()

foreach ($root in $scanRoots) {
    if (-not (Test-Path -LiteralPath $root)) {
        continue
    }

    Get-ChildItem -LiteralPath $root -Filter '*.dart' -File -Recurse |
        ForEach-Object {
            $path = $_.FullName
            $relativePath = $path.Substring($projectRoot.Length + 1)
            $lineNumber = 0

            Get-Content -LiteralPath $path -Encoding UTF8 |
                ForEach-Object {
                    $lineNumber++
                    $line = $_

                    foreach ($rule in $rules) {
                        if ($line -match $rule.Pattern) {
                            $violations.Add([pscustomobject]@{
                                File = $relativePath
                                Line = $lineNumber
                                Rule = $rule.Name
                                Text = $line.Trim()
                            })
                        }
                    }
                }
        }
}

if ($violations.Count -eq 0) {
    Write-Output 'Architecture boundary check passed.'
    exit 0
}

Write-Output "Found $($violations.Count) architecture boundary record(s):"
$violations |
    Sort-Object File, Line, Rule |
    ForEach-Object {
        Write-Output ("- {0}:{1} [{2}] {3}" -f $_.File, $_.Line, $_.Rule, $_.Text)
    }

if ($Enforce) {
    Write-Error 'Architecture boundary check failed.'
    exit 1
}

Write-Output 'Baseline report mode. Use -Enforce after migration to make violations blocking.'
exit 0
