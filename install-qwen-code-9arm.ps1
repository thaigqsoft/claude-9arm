# install-qwen-code-9arm.ps1 - Wire the `qwen-code` agent to the 9arm gateway
#
#   1. Requires ~\.claude-9arm\token (from install-claude-9arm.ps1).
#   2. Installs `@qwen-code/cli` (or `qwen-code`) if not found.
#   3. Writes the `openai`-auth modelProviders pointing at https://gateway.9arm.co/v1
#      into Qwen Code's settings.json, with the shared token as ARM_API_PASSPORT.
#   4. Prints usage.
#
# Safe to re-run: idempotent.
#
# note: package name for Qwen Code CLI — verify at install; primary is `@qwen-code/cli`.

param([switch]$SkipInstall)

$ErrorActionPreference = "Stop"

function Convert-PSObjectToHashtable {
    param($InputObject)
    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $h = @{}
        foreach ($p in $InputObject.PSObject.Properties) { $h[$p.Name] = Convert-PSObjectToHashtable $p.Value }
        return $h
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return @($InputObject | ForEach-Object { Convert-PSObjectToHashtable $_ })
    }
    return $InputObject
}

function Read-JsonFileAsHashtable {
    param([string]$Path)
    $raw = Get-Content -Raw $Path
    if ($PSVersionTable.PSVersion.Major -ge 6) { return $raw | ConvertFrom-Json -AsHashtable }
    return Convert-PSObjectToHashtable ($raw | ConvertFrom-Json)
}

$PROFILE_DIR = Join-Path $env:USERPROFILE '.claude-9arm'
$TOKEN_FILE  = Join-Path $PROFILE_DIR 'token'
if (-not (Test-Path $TOKEN_FILE)) {
    Write-Host 'ไม่พบ token file: ~\.claude-9arm\token - กรุณารัน install-claude-9arm.ps1 ก่อน' -ForegroundColor Red
    exit 1
}
$token = (Get-Content -Raw $TOKEN_FILE).Trim()

Write-Host "=== qwen-code -> 9arm gateway setup ===" -ForegroundColor Cyan

# --- 1. qwen-code presence ---
$qc = Get-Command qwen-code -ErrorAction SilentlyContinue
if (-not $qc) { $qc = Get-Command qwen -ErrorAction SilentlyContinue }
if (-not $qc) {
    if ($SkipInstall) {
        Write-Host 'ยังไม่พบ qwen-code/qwen (-SkipInstall) - ข้ามการติดตั้ง' -ForegroundColor Yellow
    } else {
        Write-Host 'ยังไม่พบ qwen-code - กำลังติดตั้งผ่าน npm (global) ...'
        npm install -g @qwen-code/cli
        if ($LASTEXITCODE -ne 0) {
            # fallback package name
            Write-Host 'ลองชื่อ package สำรอง: qwen-code ...'
            npm install -g qwen-code
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Host "npm install qwen-code ล้มเหลว (exit $LASTEXITCODE) - โปรดติดตั้งด้วยตนเองแล้วรันสคริปต์นี้อีกครั้ง" -ForegroundColor Red
            exit 1
        }
        Write-Host 'ติดตั้ง qwen-code สำเร็จ' -ForegroundColor Green
    }
} else {
    Write-Host ("พบ qwen-code แล้ว: {0}" -f $qc.Source) -ForegroundColor Green
}

# --- 2. qwen-code config dir ---
$QC_DIR = Join-Path $env:USERPROFILE '.config\qwen-code'
if (-not (Test-Path $QC_DIR)) { New-Item -ItemType Directory -Path $QC_DIR -Force | Out-Null }
$SETTINGS = Join-Path $QC_DIR 'settings.json'

# --- 3. build/merge settings.json ---
$cfg = @{}
if (Test-Path $SETTINGS) {
    try {
        $cfg = Read-JsonFileAsHashtable $SETTINGS
        if ($null -eq $cfg) { $cfg = @{} }
    } catch {
        Write-Host "อ่าน config เดิมไม่สำเร็จ จะเริ่มจาก config ว่าง: $SETTINGS" -ForegroundColor Yellow
        $cfg = @{}
    }
}
if (-not $cfg.ContainsKey('env')) { $cfg['env'] = @{} }
$cfg['env']['ARM_API_PASSPORT'] = $token
if (-not $cfg.ContainsKey('modelProviders')) { $cfg['modelProviders'] = @{} }
$cfg['modelProviders']['openai'] = @(
    @{ id = 'qwen3.8-27b-fp8';        name = 'Qwen 3.8 27b FP8';        baseUrl = 'https://gateway.9arm.co/v1'; envKey = 'ARM_API_PASSPORT' },
    @{ id = 'deepseek-v4-flash-0731'; name = 'DeepSeek V4 Flash 0731'; baseUrl = 'https://gateway.9arm.co/v1'; envKey = 'ARM_API_PASSPORT' }
)
$json = $cfg | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($SETTINGS, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "เขียน modelProviders ลง config: $SETTINGS" -ForegroundColor Green

# --- 4. summary ---
Write-Host ''
Write-Host '=== สรุป ===' -ForegroundColor Cyan
Write-Host '  • เปิด qwen-code แล้วใช้คำสั่ง /model เลือก: qwen3.8-27b-fp8 หรือ deepseek-v4-flash-0731'
Write-Host '  • ทดสอบ: qwen "คำถาม" (แล้วกดเลื่อน model ที่ต้องการ)'
Write-Host ''
Write-Host 'ติดตั้งเรียบร้อย' -ForegroundColor Green