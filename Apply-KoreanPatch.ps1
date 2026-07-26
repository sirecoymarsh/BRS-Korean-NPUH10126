[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$SourceIso,

    [Parameter(Position = 1)]
    [string]$OutputIso = '',

    [string]$PatchFile = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

# Windows PowerShell 5.1에는 ZLibStream과 Adler-32 구현이 없으므로,
# DeflateStream으로 해제한 바이트를 검증할 최소 체크섬 도우미만 로드한다.
if (-not ('BrsPatchChecksums' -as [type])) {
    Add-Type -TypeDefinition @'
public static class BrsPatchChecksums
{
    public static uint Adler32(byte[] data)
    {
        const uint ModAdler = 65521;
        uint a = 1;
        uint b = 0;
        int index = 0;
        while (index < data.Length)
        {
            int end = System.Math.Min(index + 5552, data.Length);
            for (; index < end; index++)
            {
                a += data[index];
                b += a;
            }
            a %= ModAdler;
            b %= ModAdler;
        }
        return (b << 16) | a;
    }
}
'@
}

function Resolve-FullPath([string]$PathValue) {
    return [IO.Path]::GetFullPath($PathValue)
}

function Get-Sha256([string]$PathValue) {
    return (Get-FileHash -LiteralPath $PathValue -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Assert-Sha256Text(
    [string]$Value,
    [string]$Description
) {
    if ($Value -notmatch '^[0-9a-fA-F]{64}$') {
        throw "비정상적인 SHA-256 값입니다($Description)."
    }
}

function Read-ExactBytes(
    [IO.BinaryReader]$Reader,
    [int]$Count,
    [string]$Description
) {
    $bytes = $Reader.ReadBytes($Count)
    if ($bytes.Length -ne $Count) {
        throw "잘린 패치입니다: $Description ($($bytes.Length)/$Count 바이트)"
    }
    # Unary comma prevents PowerShell's pipeline from unrolling byte[].
    return ,$bytes
}

function Expand-ZlibPayload([byte[]]$Compressed) {
    # Python zlib.compress() emits RFC 1950: two-byte zlib header, a raw
    # DEFLATE stream, then a four-byte Adler-32 trailer. Windows PowerShell
    # 5.1 has DeflateStream but no ZLibStream, so feed it the inner stream.
    if ($Compressed.Length -lt 7) {
        throw 'zlib 레코드가 너무 짧습니다.'
    }
    $cmf = [int]$Compressed[0]
    $flg = [int]$Compressed[1]
    if (
        ($cmf -band 0x0F) -ne 8 -or
        ($cmf -shr 4) -gt 7 -or
        ((($cmf * 256) + $flg) % 31) -ne 0
    ) {
        throw '유효하지 않은 zlib 헤더입니다.'
    }
    if (($flg -band 0x20) -ne 0) {
        throw '사전(dictionary)을 사용하는 zlib 레코드는 지원하지 않습니다.'
    }

    $input = New-Object IO.MemoryStream(
        $Compressed, 2, ($Compressed.Length - 6), $false, $true
    )
    $deflate = New-Object IO.Compression.DeflateStream(
        $input, [IO.Compression.CompressionMode]::Decompress, $false
    )
    $output = New-Object IO.MemoryStream
    try {
        $deflate.CopyTo($output)
        $payload = $output.ToArray()
        [UInt32]$expectedAdler = (
            ([UInt32]$Compressed[$Compressed.Length - 4] * 0x1000000) +
            ([UInt32]$Compressed[$Compressed.Length - 3] * 0x10000) +
            ([UInt32]$Compressed[$Compressed.Length - 2] * 0x100) +
            [UInt32]$Compressed[$Compressed.Length - 1]
        )
        [UInt32]$actualAdler = [BrsPatchChecksums]::Adler32($payload)
        if ($actualAdler -ne $expectedAdler) {
            throw (
                'zlib Adler-32 검증에 실패했습니다: {0:x8} != {1:x8}' -f
                $actualAdler, $expectedAdler
            )
        }
        # Keep even a one-byte payload as byte[] under StrictMode.
        return ,$payload
    } finally {
        $deflate.Dispose()
        $input.Dispose()
        $output.Dispose()
    }
}

if (-not $PatchFile) {
    $PatchFile = Join-Path $PSScriptRoot 'BRS_Korean_NPUH10126_v1.0.brspatch'
}
$source = Resolve-FullPath $SourceIso
$patch = Resolve-FullPath $PatchFile
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "원본 ISO를 찾을 수 없습니다: $source"
}
if (-not (Test-Path -LiteralPath $patch -PathType Leaf)) {
    throw "패치 파일을 찾을 수 없습니다: $patch"
}
if (-not $OutputIso) {
    $sourceDirectory = Split-Path -Parent $source
    $sourceBase = [IO.Path]::GetFileNameWithoutExtension($source)
    $OutputIso = Join-Path $sourceDirectory ($sourceBase + '_Korean_v1.0.iso')
}
$outputPath = Resolve-FullPath $OutputIso
if ($source -eq $outputPath) {
    throw '원본 ISO를 직접 덮어쓰지 않습니다. 다른 출력 경로를 지정하세요.'
}

$patchStream = [IO.File]::Open(
    $patch, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read
)
$reader = New-Object IO.BinaryReader(
    $patchStream, [Text.Encoding]::UTF8, $true
)
$temporary = $null
try {
    $magic = [Text.Encoding]::ASCII.GetString(
        (Read-ExactBytes $reader 10 'BRSPATCH1 시그니처')
    )
    if ($magic -ne "BRSPATCH1`n") {
        throw 'BRSPATCH1 형식의 패치가 아닙니다.'
    }
    $headerLength = [int]$reader.ReadUInt32()
    if ($headerLength -lt 2 -or $headerLength -gt (16 * 1024 * 1024)) {
        throw "비정상적인 패치 헤더 크기입니다: $headerLength"
    }
    $headerJson = [Text.Encoding]::UTF8.GetString(
        (Read-ExactBytes $reader $headerLength 'JSON 헤더')
    )
    $header = $headerJson | ConvertFrom-Json
    if ($header.schema -ne 'brs-binary-delta/v1') {
        throw "지원하지 않는 패치 스키마입니다: $($header.schema)"
    }
    if ($header.compression -ne 'zlib') {
        throw "지원하지 않는 압축 형식입니다: $($header.compression)"
    }
    [Int64]$sourceSize = $header.source.size
    [Int64]$targetSize = $header.target.size
    [Int64]$recordCount64 = $header.record_count
    if ($sourceSize -lt 1 -or $targetSize -lt 1) {
        throw '패치 헤더의 ISO 크기가 올바르지 않습니다.'
    }
    if ($recordCount64 -lt 0 -or $recordCount64 -gt [Int32]::MaxValue) {
        throw "패치 헤더의 레코드 수가 올바르지 않습니다: $recordCount64"
    }
    [int]$expectedRecordCount = $recordCount64
    [string]$expectedSourceHash = $header.source.sha256
    [string]$expectedTargetHash = $header.target.sha256
    Assert-Sha256Text $expectedSourceHash '원본'
    Assert-Sha256Text $expectedTargetHash '완성본'
    $expectedSourceHash = $expectedSourceHash.ToLowerInvariant()
    $expectedTargetHash = $expectedTargetHash.ToLowerInvariant()

    $sourceInfo = Get-Item -LiteralPath $source
    if ([Int64]$sourceInfo.Length -ne $sourceSize) {
        throw "원본 ISO 크기가 일치하지 않습니다: $($sourceInfo.Length) != $sourceSize"
    }
    Write-Host '원본 ISO SHA-256을 확인하는 중...'
    $sourceHash = Get-Sha256 $source
    if ($sourceHash -ne $expectedSourceHash) {
        throw "지원 대상 원본 ISO가 아닙니다: $sourceHash"
    }

    if (Test-Path -LiteralPath $outputPath) {
        if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
            throw "출력 경로가 이미 존재하며 파일이 아닙니다: $outputPath"
        }
        $existingHash = Get-Sha256 $outputPath
        if ($existingHash -eq $expectedTargetHash) {
            Write-Host "이미 적용되어 있습니다: $outputPath"
            return
        }
        throw "출력 파일이 이미 있고 완성본 해시와 다릅니다: $outputPath"
    }

    $outputDirectory = Split-Path -Parent $outputPath
    if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }
    $temporary = Join-Path $outputDirectory (
        '.' + (Split-Path -Leaf $outputPath) + ".applying-$PID-" +
        [Guid]::NewGuid().ToString('N') + '.tmp'
    )
    if (Test-Path -LiteralPath $temporary) {
        throw "임시 출력 경로가 이미 존재합니다: $temporary"
    }

    Write-Host '원본을 보존한 채 새 ISO를 만드는 중...'
    [IO.File]::Copy($source, $temporary, $false)
    $target = [IO.File]::Open(
        $temporary, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite,
        [IO.FileShare]::None
    )
    try {
        $target.SetLength($targetSize)
        [UInt64]$previousEnd = 0
        [int]$recordCount = 0
        while ($patchStream.Position -lt $patchStream.Length) {
            if (($patchStream.Length - $patchStream.Position) -lt 16) {
                throw '잘린 패치 레코드 헤더입니다.'
            }
            if ($recordCount -ge $expectedRecordCount) {
                throw '패치 헤더에 선언되지 않은 추가 레코드가 있습니다.'
            }
            [UInt64]$offset = $reader.ReadUInt64()
            [UInt32]$rawSize = $reader.ReadUInt32()
            [UInt32]$compressedSize = $reader.ReadUInt32()
            if ($rawSize -lt 1 -or $compressedSize -lt 1) {
                throw '크기가 0인 패치 레코드입니다.'
            }
            if (
                [UInt64]$rawSize -gt [UInt64]([Int32]::MaxValue) -or
                [UInt64]$compressedSize -gt [UInt64]([Int32]::MaxValue)
            ) {
                throw 'Windows PowerShell 5.1에서 처리할 수 없는 크기의 패치 레코드입니다.'
            }
            if ($offset -lt $previousEnd) {
                throw '패치 레코드가 겹치거나 순서가 잘못되었습니다.'
            }
            if ([UInt64]$rawSize -gt ([UInt64]::MaxValue - $offset)) {
                throw '패치 레코드 오프셋이 64비트 범위를 넘습니다.'
            }
            [UInt64]$recordEnd = $offset + [UInt64]$rawSize
            if ($recordEnd -gt [UInt64]$targetSize) {
                throw '패치 레코드가 대상 ISO 범위를 벗어납니다.'
            }
            $compressed = Read-ExactBytes $reader ([int]$compressedSize) 'zlib 페이로드'
            $payload = Expand-ZlibPayload $compressed
            if ($payload.Length -ne [int]$rawSize) {
                throw "압축 해제 크기가 일치하지 않습니다: $($payload.Length) != $rawSize"
            }
            $target.Position = [Int64]$offset
            $target.Write($payload, 0, $payload.Length)
            $previousEnd = $recordEnd
            $recordCount += 1
            if (($recordCount % 250) -eq 0) {
                if ($expectedRecordCount -gt 0) {
                    $percentComplete = (
                        100.0 * $recordCount / [double]$expectedRecordCount
                    )
                } else {
                    $percentComplete = 100.0
                }
                Write-Progress -Activity '한국어 패치 적용' `
                    -Status "$recordCount / $expectedRecordCount 레코드" `
                    -PercentComplete $percentComplete
            }
        }
        Write-Progress -Activity '한국어 패치 적용' -Completed
        if ($recordCount -ne $expectedRecordCount) {
            throw "패치 레코드 수가 일치하지 않습니다: $recordCount != $expectedRecordCount"
        }
        $target.Flush($true)
    } finally {
        $target.Dispose()
    }

    Write-Host '완성된 ISO SHA-256을 확인하는 중...'
    $targetHash = Get-Sha256 $temporary
    if ($targetHash -ne $expectedTargetHash) {
        throw "완성본 해시 검증에 실패했습니다: $targetHash"
    }
    [IO.File]::Move($temporary, $outputPath)
    $temporary = $null

    $journal = [ordered]@{
        schema = 'brs-korean-install-journal/v1'
        source_iso = $source
        source_sha256 = $sourceHash
        patched_iso = $outputPath
        patched_sha256 = $targetHash
        patch_file = $patch
        installed_utc = [DateTime]::UtcNow.ToString('o')
    }
    $journalPath = $outputPath + '.brs-korean-install.json'
    $journal | ConvertTo-Json | Set-Content -LiteralPath $journalPath -Encoding UTF8

    Write-Host ''
    Write-Host '한국어 패치 적용 및 검증 완료'
    Write-Host "출력: $outputPath"
    Write-Host "SHA-256: $targetHash"
    Write-Host '원본 ISO는 변경하지 않았습니다.'
} finally {
    $reader.Dispose()
    $patchStream.Dispose()
    if ($temporary -and (Test-Path -LiteralPath $temporary)) {
        Remove-Item -LiteralPath $temporary -Force
    }
}
