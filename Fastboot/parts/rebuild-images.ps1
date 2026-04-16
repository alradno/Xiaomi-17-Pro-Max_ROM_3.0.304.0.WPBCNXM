param(
    [string]$InputDir = $PSScriptRoot,
    [string]$OutputDir = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$manifestPath = Join-Path $InputDir "release-assets-manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Missing manifest: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$buffer = New-Object byte[] (8MB)

foreach ($file in $manifest.files) {
    $outputPath = Join-Path $OutputDir $file.source_name
    Write-Host ("Rebuilding {0}" -f $file.source_name)

    $outputStream = [System.IO.File]::Open($outputPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        foreach ($part in $file.parts) {
            $partPath = Join-Path $InputDir $part.name
            if (-not (Test-Path -LiteralPath $partPath)) {
                throw "Missing part: $partPath"
            }

            $inputStream = [System.IO.File]::Open($partPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
            try {
                while (($bytesRead = $inputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    $outputStream.Write($buffer, 0, $bytesRead)
                }
            }
            finally {
                $inputStream.Dispose()
            }
        }
    }
    finally {
        $outputStream.Dispose()
    }
}
