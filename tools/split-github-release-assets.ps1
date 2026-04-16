param(
    [string]$OutputDir = (Join-Path (Split-Path -Parent $PSScriptRoot) "Fastboot\parts"),
    [long]$ChunkSizeBytes = 104800000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceFiles = @(
    (Join-Path $repoRoot "Fastboot\images\super.img"),
    (Join-Path $repoRoot "Fastboot\images\userdata.img")
)

function Remove-ExistingParts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseName
    )

    Get-ChildItem -LiteralPath $OutputDir -Filter "$BaseName.part*-of-*" -ErrorAction SilentlyContinue |
        Remove-Item -Force
}

function Split-FileForRelease {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $file = Get-Item -LiteralPath $Path
    $baseName = $file.Name
    $totalParts = [int][Math]::Ceiling($file.Length / [double]$ChunkSizeBytes)
    $buffer = New-Object byte[] (8MB)
    $parts = New-Object System.Collections.Generic.List[object]

    Remove-ExistingParts -BaseName $baseName

    $sourceStream = [System.IO.File]::Open($file.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    try {
        for ($partIndex = 1; $partIndex -le $totalParts; $partIndex++) {
            $partName = "{0}.part{1:D3}-of-{2:D3}" -f $baseName, $partIndex, $totalParts
            $partPath = Join-Path $OutputDir $partName
            $bytesRemainingInPart = [long][Math]::Min($ChunkSizeBytes, $file.Length - $sourceStream.Position)

            Write-Host ("Creating {0}" -f $partName)

            $targetStream = [System.IO.File]::Open($partPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            try {
                while ($bytesRemainingInPart -gt 0) {
                    $bytesToRead = [int][Math]::Min($buffer.Length, $bytesRemainingInPart)
                    $bytesRead = $sourceStream.Read($buffer, 0, $bytesToRead)
                    if ($bytesRead -le 0) {
                        throw "Unexpected end of file while splitting $baseName."
                    }

                    $targetStream.Write($buffer, 0, $bytesRead)
                    $bytesRemainingInPart -= $bytesRead
                }
            }
            finally {
                $targetStream.Dispose()
            }

            $partFile = Get-Item -LiteralPath $partPath
            $parts.Add([PSCustomObject]@{
                name  = $partFile.Name
                bytes = $partFile.Length
            })
        }
    }
    finally {
        $sourceStream.Dispose()
    }

    return [PSCustomObject]@{
        source_name = $file.Name
        source_bytes = $file.Length
        total_parts = $totalParts
        parts = $parts
    }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$results = foreach ($sourceFile in $sourceFiles) {
    if (-not (Test-Path -LiteralPath $sourceFile)) {
        throw "Missing source file: $sourceFile"
    }

    Split-FileForRelease -Path $sourceFile
}

$manifest = [PSCustomObject]@{
    created_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    chunk_size_bytes = $ChunkSizeBytes
    files = $results
}

$manifestPath = Join-Path $OutputDir "release-assets-manifest.json"
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding ascii

$rebuildScript = @'
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
'@

$rebuildPath = Join-Path $OutputDir "rebuild-images.ps1"
Set-Content -LiteralPath $rebuildPath -Value $rebuildScript -Encoding ascii

$readme = @"
GitHub-ready tracked parts
==========================

These parts were generated below GitHub's normal 100 MiB file limit so they can
live in the repository as regular Git files.

Keep every file in this folder together.

To rebuild the original images after cloning the repository:

  powershell -ExecutionPolicy Bypass -File .\rebuild-images.ps1

The manifest file must stay next to the part files.
"@

$readmePath = Join-Path $OutputDir "README.txt"
Set-Content -LiteralPath $readmePath -Value $readme -Encoding ascii

Write-Host ""
Write-Host ("Done. Output folder: {0}" -f $OutputDir)
foreach ($result in $results) {
    Write-Host (" - {0}: {1} parts" -f $result.source_name, $result.total_parts)
}
