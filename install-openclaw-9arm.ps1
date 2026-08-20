# install-openclaw-9arm.ps1 - Wire the OpenClaw agent to the 9arm gateway
#
#   1. Requires ~\.claude-9arm\token (from install-claude-9arm.ps1).
#   2. Installs OpenClaw if not found (skippable with -SkipInstall).
#   3. Writes/merges a `9arm` custom provider into OpenClaw config (~/.openclaw/openclaw.json)
#      pointing at https://gateway.9arm.co/v1 (OpenAI-compatible) using the shared token.
#   4. Prints usage.
#
# Safe to re-run: idempotent.

param([switch]$SkipInstall)

$ErrorActionPreference = "Stop"

$PROFILE_DIR = Join-Path $env:USERPROFILE '.claude-9arm'
$TOKEN_FILE  = Join-Path $PROFILE_DIR 'token'
if (-not (Test-Path $TOKEN_FILE)) {
    Write-Error 'ไม่พบ token file: ~\.claude-9arm\token - กรุณารัน install-claude-9arm.ps1 ก่อน'
    exit 1
}
$token = (Get-Content -Raw $TOKEN_FILE).Trim()

Write-Host "=== OpenClaw -> 9arm gateway setup ===" -ForegroundColor Cyan

# --- 1. openclaw presence ---
$oc = Get-Command openclaw -ErrorAction SilentlyContinue
if (-not $oc) {
    if ($SkipInstall) {
        Write-Host 'ยังไม่พบ openclaw (-SkipInstall) - ข้ามการติดตั้ง' -ForegroundColor Yellow
    } else {
        Write-Host 'ยังไม่พบ openclaw - ติดตั้งผ่าน npx ...'
        npx openclaw@latest install
        if ($LASTEXITCODE -ne 0) {
            Write-Host 'โปรดติดตั้ง OpenClaw ด้วยตนเองจาก https://docs.openclaw.ai/install' -ForegroundColor Yellow
        }
    }
} else {
    Write-Host ("พบ openclaw แล้ว: {0}" -f $oc.Source) -ForegroundColor Green
}

# --- 2. config dir ---
$OC_DIR = Join-Path $env:USERPROFILE '.openclaw'
if (-not (Test-Path $OC_DIR)) { New-Item -ItemType Directory -Path $OC_DIR -Force | Out-Null }
$OC_FILE = Join-Path $OC_DIR 'openclaw.json'

# --- 3. merge provider ---
$cfg = @{}
if (Test-Path $OC_FILE) {
    try { $cfg = Get-Content -Raw $OC_FILE | ConvertFrom-Json -AsHashtable } catch { $cfg = @{} }
}
if (-not $cfg.ContainsKey('models')) { $cfg['models'] = @{} }
$models = $cfg['models']
if (-not $models.ContainsKey('providers')) { $models['providers'] = @{} }
$models['providers']['9arm'] = @{
    baseUrl = 'https://gateway.9arm.co/v1'
    apiKey  = $token
    api     = 'openai-completions'
    models  = @(
        @{ id = 'qwen3.8-27b-fp8';        name = 'Qwen 3.8 27b FP8' },
        @{ id = 'deepseek-v4-flash-0731'; name = 'DeepSeek V4 Flash 0731' }
    )
}
$json = $cfg | ConvertTo-Json -Depth 20
Set-Content -Path $OC_FILE -Value $json -Encoding utf8
Write-Host "เขียน provider '9arm' ลง config: $OC_FILE" -ForegroundColor Green

# --- 4. summary ---
Write-Host ''
Write-Host '=== สรุป ===' -ForegroundColor Cyan
Write-Host '  • model ให้ใช้: 9arm/qwen3.8-27b-fp8  หรือ  9arm/deepseek-v4-flash-0731'
Write-Host '  • เลือกใน OpenClaw ผ่าน /model  รูปแบบ  provider/model'
Write-Host ''
Write-Host 'ติดตั้งเรียบร้อย' -ForegroundColor Green