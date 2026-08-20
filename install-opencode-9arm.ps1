# install-opencode-9arm.ps1 - Wire the `opencode` coding agent to the 9arm gateway
#
# What it does:
#   1. Requires the gateway token at ~\.claude-9arm\token (from install-claude-9arm.ps1).
#   2. Installs `opencode` via npm if not found (skippable with -SkipInstall).
#   3. Writes/merges the `9arm` provider into ~\.config\opencode\opencode.json
#      pointing at https://gateway.9arm.co/v1 using the shared token file.
#   4. Prints how to use (opencode --model 9arm/<model>).
#
# Safe to re-run: idempotent.
#
# NOTE: This writes the shared token PATH into opencode config via opencode's
# `{file:...}` syntax so the token value itself is never duplicated in the config.

param(
    [switch]$SkipInstall  # skip the npm install of opencode
)

$ErrorActionPreference = "Stop"

# --- shared token (single source of truth, created by install-claude-9arm.ps1) ---
$PROFILE_DIR = Join-Path $env:USERPROFILE '.claude-9arm'
$TOKEN_FILE  = Join-Path $PROFILE_DIR 'token'
if (-not (Test-Path $TOKEN_FILE)) {
    Write-Error 'ไม่พบ token file: ~\.claude-9arm\token - กรุณารัน install-claude-9arm.ps1 ก่อน (token มาจากเจ้าของ)'
    exit 1
}

Write-Host "=== opencode -> 9arm gateway setup ===" -ForegroundColor Cyan
Write-Host "ใช้ token เดียวกับ claude-9arm: $TOKEN_FILE"

# --- 1. opencode presence ---
$oc = Get-Command opencode -ErrorAction SilentlyContinue
if (-not $oc) {
    if ($SkipInstall) {
        Write-Host 'ยังไม่พบ opencode (-SkipInstall) - จะข้ามการติดตั้ง แต่ยังต้องให้ opencode พร้อมก่อนถึงจะใช้ได้' -ForegroundColor Yellow
    } else {
        Write-Host 'ยังไม่พบ opencode - กำลังติดตั้งผ่าน npm (global) ...'
        npm install -g opencode-ai
        if ($LASTEXITCODE -ne 0) {
            Write-Error "npm install opencode-ai ล้มเหลว (exit $LASTEXITCODE)"
            exit 1
        }
        Write-Host 'ติดตั้ง opencode สำเร็จ' -ForegroundColor Green
    }
} else {
    Write-Host ("พบ opencode แล้ว: {0}" -f $oc.Source) -ForegroundColor Green
}

# --- 2. opencode config dir ---
$OC_DIR = Join-Path $env:USERPROFILE '.config\opencode'
if (-not (Test-Path $OC_DIR)) { New-Item -ItemType Directory -Path $OC_DIR -Force | Out-Null }
$OC_FILE = Join-Path $OC_DIR 'opencode.json'

# --- 3. build/merge the 9arm provider ---
# Preserve any existing config; add/update the "9arm" provider.
$cfg = @{}
if (Test-Path $OC_FILE) {
    try { $cfg = Get-Content -Raw $OC_FILE | ConvertFrom-Json -AsHashtable } catch { $cfg = @{} }
}
if (-not $cfg.ContainsKey('provider')) { $cfg['provider'] = @{} }
$provider = $cfg['provider']
$provider['9arm'] = @{
    name    = '9arm Gateway'
    options = @{
        baseURL = 'https://gateway.9arm.co/v1'
        apiKey  = "{file:$TOKEN_FILE}"
    }
    models  = @{
        'qwen3.8-27b-fp8'       = @{ name = 'Qwen 3.8 27b FP8' }
        'deepseek-v4-flash-0731' = @{ name = 'DeepSeek V4 Flash 0731' }
    }
}
# JSON ignores ordering of hashtable; ConvertFrom-Json -AsHashtable round-trips fine.
$json = $cfg | ConvertTo-Json -Depth 20
Set-Content -Path $OC_FILE -Value $json -Encoding utf8
Write-Host "เขียน provider '9arm' ลง config: $OC_FILE" -ForegroundColor Green

# --- 4. summary ---
Write-Host ''
Write-Host '=== สรุป ===' -ForegroundColor Cyan
Write-Host '  • ตัวเลือก model:'
Write-Host '      opencode --model 9arm/qwen3.8-27b-fp8 "คำถาม"'
Write-Host '      opencode --model 9arm/deepseek-v4-flash-0731 "คำถาม"'
Write-Host '  • ถ้าต้องการตั้งเป็นค่าเริ่มต้น: เพิ่มบรรทัด "model": "9arm/qwen3.8-27b-fp8" ในไฟล์ opencode.json'
Write-Host ''
Write-Host 'ติดตั้งเรียบร้อย' -ForegroundColor Green