# install-hermes-9arm.ps1 - Wire the Hermes agent to the 9arm gateway
#
#   1. Requires ~\.claude-9arm\token (from install-claude-9arm.ps1).
#   2. Installs Hermes if not found (skippable with -SkipInstall).
#   3. Writes OPENAI_API_KEY + OPENAI_BASE_URL into ~/.hermes/.env pointing at
#      https://gateway.9arm.co/v1 (Hermes `openai-api` provider).
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

Write-Host "=== Hermes -> 9arm gateway setup ===" -ForegroundColor Cyan

# --- 1. hermes presence ---
$hx = Get-Command hermes -ErrorAction SilentlyContinue
if (-not $hx) {
    if ($SkipInstall) {
        Write-Host 'ยังไม่พบ hermes (-SkipInstall) - ข้ามการติดตั้ง' -ForegroundColor Yellow
    } else {
        Write-Host 'ยังไม่พบ hermes - ติดตั้งจาก https://hermes-agent.nousresearch.com (pip / uv / brew)'
        Write-Host 'ตัวอย่าง (uv): uv tool install hermes-agent' -ForegroundColor Yellow
    }
} else {
    Write-Host ("พบ hermes แล้ว: {0}" -f $hx.Source) -ForegroundColor Green
}

# --- 2. .hermes dir + .env ---
$HERMES_DIR = Join-Path $env:USERPROFILE '.hermes'
if (-not (Test-Path $HERMES_DIR)) { New-Item -ItemType Directory -Path $HERMES_DIR -Force | Out-Null }
$ENV_FILE = Join-Path $HERMES_DIR '.env'

# --- 3. merge/ensure keys (idempotent) ---
$lines = @()
if (Test-Path $ENV_FILE) {
    $lines = Get-Content $ENV_FILE | Where-Object { $_ -notmatch '^OPENAI_API_KEY=|^OPENAI_BASE_URL=' }
}
$lines += "OPENAI_API_KEY=$token"
$lines += 'OPENAI_BASE_URL=https://gateway.9arm.co/v1'
Set-Content -Path $ENV_FILE -Value $lines -Encoding ascii
Write-Host "เขียน config ลง: $ENV_FILE" -ForegroundColor Green

# --- 4. summary ---
Write-Host ''
Write-Host '=== สรุป ===' -ForegroundColor Cyan
Write-Host '  • รัน: hermes   แล้วเลือก /model -> openai-api'
Write-Host '  • ตัว model: qwen3.8-27b-fp8 / deepseek-v4-flash-0731'
Write-Host '  • วิธีใช้: hermes "คำถาม" แล้วเปลี่ยน provider เป็น openai-api'
Write-Host ''
Write-Host 'ติดตั้งเรียบร้อย' -ForegroundColor Green