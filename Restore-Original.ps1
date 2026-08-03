[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$PatchedIso,

    [string]$PatchFile = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Resolve-FullPath([string]$PathValue) {
    return [IO.Path]::GetFullPath($PathValue)
}

function Get-Sha256([string]$PathValue) {
    # Get-FileHash participates in -WhatIf through the FileSystem provider and
    # can return no object under StrictMode. Use .NET so a restore dry-run still
    # performs the mandatory integrity check without deleting anything.
    $stream = [IO.File]::Open(
        $PathValue, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read
    )
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $sha.ComputeHash($stream)
        return ([BitConverter]::ToString($bytes)).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
        $stream.Dispose()
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

function Assert-Sha256Text(
    [string]$Value,
    [string]$Description
) {
    if ($Value -notmatch '^[0-9a-fA-F]{64}$') {
        throw "비정상적인 SHA-256 값입니다($Description)."
    }
}

if (-not $PatchFile) {
    $PatchFile = Join-Path $PSScriptRoot 'BRS_Korean_NPUH10126_v1.0.brspatch'
}
$patched = Resolve-FullPath $PatchedIso
$patch = Resolve-FullPath $PatchFile
if (-not (Test-Path -LiteralPath $patched -PathType Leaf)) {
    if (Test-Path -LiteralPath $patched) {
        throw "패치 ISO 경로가 파일이 아닙니다: $patched"
    }
    Write-Host "이미 복원된 상태입니다(패치 ISO 없음): $patched"
    return
}
if (-not (Test-Path -LiteralPath $patch -PathType Leaf)) {
    throw "패치 파일을 찾을 수 없습니다: $patch"
}

$stream = [IO.File]::Open(
    $patch, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read
)
$reader = New-Object IO.BinaryReader($stream, [Text.Encoding]::UTF8, $true)
try {
    $magic = [Text.Encoding]::ASCII.GetString(
        (Read-ExactBytes $reader 10 'BRSPATCH1 시그니처')
    )
    if ($magic -ne "BRSPATCH1`n") {
        throw 'BRSPATCH1 형식의 패치가 아닙니다.'
    }
    $headerLength = [int]$reader.ReadUInt32()
    if ($headerLength -lt 2 -or $headerLength -gt (16 * 1024 * 1024)) {
        throw '비정상적인 패치 헤더입니다.'
    }
    $headerBytes = Read-ExactBytes $reader $headerLength 'JSON 헤더'
    $header = ([Text.Encoding]::UTF8.GetString($headerBytes)) | ConvertFrom-Json
    if ($header.schema -ne 'brs-binary-delta/v1') {
        throw "지원하지 않는 패치 스키마입니다: $($header.schema)"
    }
    [Int64]$expectedSize = $header.target.size
    if ($expectedSize -lt 1) {
        throw '패치 헤더의 완성본 크기가 올바르지 않습니다.'
    }
    [string]$expectedHash = $header.target.sha256
    Assert-Sha256Text $expectedHash '완성본'
    $expectedHash = $expectedHash.ToLowerInvariant()
} finally {
    $reader.Dispose()
    $stream.Dispose()
}

if ([Int64](Get-Item -LiteralPath $patched).Length -ne $expectedSize) {
    throw (
        "알 수 없거나 수정된 ISO이므로 삭제하지 않습니다(크기 불일치): " +
        "$((Get-Item -LiteralPath $patched).Length) != $expectedSize"
    )
}
Write-Host '삭제 전 패치 ISO SHA-256을 확인하는 중...'
$actualHash = Get-Sha256 $patched
if ($actualHash -ne $expectedHash) {
    throw "알 수 없거나 수정된 ISO이므로 삭제하지 않습니다: $actualHash"
}

if ($PSCmdlet.ShouldProcess($patched, '검증된 한국어 패치 ISO 제거(원본은 그대로 유지)')) {
    Remove-Item -LiteralPath $patched -Force
    $journal = $patched + '.brs-korean-install.json'
    if (Test-Path -LiteralPath $journal -PathType Leaf) {
        Remove-Item -LiteralPath $journal -Force
    }
    Write-Host '복원 완료: 한국어 패치 ISO만 제거했으며 원본 ISO는 변경되지 않았습니다.'
}
