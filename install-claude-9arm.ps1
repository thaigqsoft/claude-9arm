# install-claude-9arm.ps1 - One-time Windows setup for claude-9arm (PowerShell wrapper)
#
# What it does:
#   1. Verifies node + npm are on PATH (never installs Node silently).
#   2. Installs Claude Code via npm ONLY if the `claude` command is missing
#      (skipped wholesale with -SkipInstall).
#   3. Creates the profile dir ~\.claude-9arm.
#   4. Prompts for the gateway token (Read-Host -AsSecureString) and stores it
#      in ~\.claude-9arm\token. Only prompts if the token is missing, or when
#      -PromptToken is passed (to reset).
#   5. Writes the runtime wrapper claude-9arm.ps1 into the profile dir.
#   6. Creates the claude-9arm.cmd shim in ~\.claude-9arm\bin so you can type
#      `claude-9arm` anywhere (once the bin dir is on PATH).
#   7. Prints usage + where the token lives.
#
# Safe to re-run: idempotent.

param(
    [switch]$PromptToken,   # force re-prompt for a new token (to reset)
    [switch]$SkipInstall    # skip the npm global install entirely
)

$ErrorActionPreference = "Stop"

# --- Helpers (Stop-on-error inside functions) ---
function Test-Node {
    # node
    $node = Get-Command node -ErrorAction SilentlyContinue
    if (-not $node) {
        Write-Host ''
        Write-Host '⚠️  ไม่พบ Node.js ใน PATH' -ForegroundColor Yellow
        Write-Host 'กรุณาติดตั้ง Node.js LTS ก่อน แล้วจึงรันสคริปต์นี้อีกครั้ง'
        Write-Host 'ติดตั้งผ่าน winget:'
        Write-Host ''
        Write-Host '    winget install OpenJS.NodeJS.LTS'
        Write-Host ''
        Write-Host 'หรือดาวน์โหลดจาก https://nodejs.org แล้วเลือกตัว LTS'
        exit 1
    }
    # npm
    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npm) {
        Write-Host ''
        Write-Host '⚠️  พบ node แต่ไม่พบ npm ใน PATH' -ForegroundColor Yellow
        Write-Host 'npm ปกติมากับ Node.js - ลองเปิด terminal ใหม่หลังจากติดตั้ง Node.js'
        exit 1
    }
    $nodeVer = if ($node.Version) { $node.Version } else { 'unknown' }
    Write-Host ("node: {0}" -f $nodeVer)
    Write-Host "npm : $((& $npm.Source --version))"
}

function Install-ClaudeCli {
    param([bool]$Skip)
    $claude = Get-Command claude -ErrorAction SilentlyContinue
    if ($claude) {
        Write-Host ("พบ Claude Code แล้ว: {0}" -f $claude.Source) -ForegroundColor Green
        return
    }
    if ($Skip) {
        Write-Host 'ข้ามการติดตั้ง Claude Code (-SkipInstall) แต่ยังไม่พบคำสั่ง claude' -ForegroundColor Yellow
        return
    }
    Write-Host 'ยังไม่พบ claude - กำลังติดตั้ง Claude Code ผ่าน npm (global) ...'
    npm install -g @anthropic-ai/claude-code
    if ($LASTEXITCODE -ne 0) {
        Write-Error "npm install ล้มเหลว (exit code: $LASTEXITCODE)"
        Write-Host 'ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต / proxy แล้วลองอีกครั้ง'
        exit 1
    }
    Write-Host 'ติดตั้ง Claude Code สำเร็จ' -ForegroundColor Green
}

function Write-ProfileWrapper {
    param([string]$ProfileDir)

    # --- Runtime wrapper (claude-9arm.ps1). Kept identical to the standalone
    # --- claude-9arm.ps1 file in this project; the single-quoted here-string
    # --- prevents any $ variable expansion.
    $wrapperContent = @'
# claude-9arm.ps1 - Windows runtime wrapper for claude-9arm
# Mirrors the Linux bash wrapper env logic. Health probe is OFF by default
# (opt-in via -HealthCheck) to avoid an extra token round-trip for the friend.
# Invoke through the .cmd shim (which passes -NoProfile -ExecutionPolicy Bypass)
# or run this file directly via: powershell -NoProfile -ExecutionPolicy Bypass -File claude-9arm.ps1 ...

param([switch]$HealthCheck)

$ErrorActionPreference = "Stop"

# Capture the user-supplied arguments. The $HealthCheck switch was already
# consumed by the param() block above, so $args here holds only the real
# arguments that must be forwarded to claude.
$remainingArgs = @($args)

$PROFILE_DIR = Join-Path $env:USERPROFILE '.claude-9arm'
$TOKEN_FILE  = Join-Path $PROFILE_DIR 'token'

if (-not (Test-Path $TOKEN_FILE)) {
    Write-Error "ไม่พบ token file: $TOKEN_FILE" -Category ObjectNotFound
    Write-Error 'กรุณารัน install-claude-9arm.ps1 เพื่อตั้งค่า token ก่อน (token มาจากเจ้าของ)'
    exit 1
}

# --- Environment mirror of the original bash wrapper ---
$env:CLAUDE_CONFIG_DIR                = $PROFILE_DIR
$env:CLAUDE_OP_NO_HEADROOM            = '1'
$env:ANTHROPIC_BASE_URL               = 'https://gateway.9arm.co'
$env:ANTHROPIC_AUTH_TOKEN             = (Get-Content -Raw $TOKEN_FILE).Trim()
$env:ANTHROPIC_MODEL                  = 'deepseek-v4-flash-0731'
$env:ANTHROPIC_SMALL_FAST_MODEL       = 'deepseek-v4-flash-0731'
$env:ANTHROPIC_DEFAULT_SONNET_MODEL   = 'deepseek-v4-flash-0731'
$env:ANTHROPIC_DEFAULT_OPUS_MODEL     = 'deepseek-v4-flash-0731'
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL    = 'deepseek-v4-flash-0731'
$env:OBSCURA_ALLOW_PRIVATE_NETWORK    = '1'
$env:CLAUDE_CODE_MAX_CONTEXT_TOKENS   = '128000'
$env:CLAUDE_CODE_DISABLE_ADVISOR_TOOL = '1'

# Prevent x-api-key from overriding the Bearer token.
Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue

# Inject an isolated profile CLAUDE.md when present (mirrors the bash
# --append-system-prompt-file behavior).
$profileClaude = Join-Path $PROFILE_DIR 'CLAUDE.md'
if (Test-Path $profileClaude) {
    $remainingArgs = @('--append-system-prompt-file', $profileClaude) + $remainingArgs
}

# --- Optional health probe (OFF by default; opt-in with -HealthCheck) ---
if ($HealthCheck -and $env:CLAUDE_9ARM_SKIP_CHECK -ne '1') {
    $probeClaude = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $probeClaude) {
        Write-Error 'claude command not found - cannot run health check. Run install-claude-9arm.ps1 first.'
        exit 1
    }
    $probeOut = & $probeClaude.Source -p 'What is 1+1? Reply with the number only.'
    if ($probeOut -notmatch '2') {
        Write-Error 'claude-9arm health check FAILED'
        exit 1
    }
    Write-Host "Health check OK: $probeOut"
}

# --- Invoke claude with the forwarded arguments ---
$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude) {
    Write-Error 'ไม่พบคำสั่ง claude - กรุณารัน install-claude-9arm.ps1 (ติดตั้ง Claude Code) ก่อน'
    exit 1
}

& $claude.Source @remainingArgs
exit $LASTEXITCODE
'@

    # Write the wrapper as UTF-8 WITH BOM so Thai text survives on Windows
    # PowerShell 5.1 (which reads BOM-less .ps1 as ANSI). NB: -Encoding utf8
    # means "with BOM" on 5.1 but "without BOM" on PowerShell 7+, so use the
    # explicit .NET writer to be deterministic across both.
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText((Join-Path $ProfileDir 'claude-9arm.ps1'), $wrapperContent, $utf8Bom)
    Write-Host ("เขียน wrapper: {0}\claude-9arm.ps1" -f $ProfileDir) -ForegroundColor Green
}

function Write-CmdShim {
    param([string]$BinDir)
    if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir -Force | Out-Null }
    $shim = '@powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\claude-9arm.ps1" %*'
    Set-Content -Path (Join-Path $BinDir 'claude-9arm.cmd') -Value $shim -Encoding ascii
    Write-Host ("เขียน shim: {0}\claude-9arm.cmd" -f $BinDir) -ForegroundColor Green
}

# ==================== Main ====================
Write-Host "=== claude-9arm Windows setup ===" -ForegroundColor Cyan

Test-Node
Install-ClaudeCli -Skip:$SkipInstall

$PROFILE_DIR = Join-Path $env:USERPROFILE '.claude-9arm'
if (-not (Test-Path $PROFILE_DIR)) {
    New-Item -ItemType Directory -Path $PROFILE_DIR -Force | Out-Null
    Write-Host "สร้างโฟลเดอร์: $PROFILE_DIR" -ForegroundColor Green
}
$TOKEN_FILE = Join-Path $PROFILE_DIR 'token'

# --- Token prompt (only when missing, or when -PromptToken forces a reset) ---
if ($PromptToken -or -not (Test-Path $TOKEN_FILE)) {
    Write-Host ''
    Write-Host 'กรุณาใส่ gateway token (token ที่เจ้าของออกให้)'
    $sec = Read-Host 'Gateway token' -AsSecureString
    $cred = New-Object System.Management.Automation.PSCredential ('token', $sec)
    $token = $cred.GetNetworkCredential().Password
    if ([string]::IsNullOrWhiteSpace($token)) {
        Write-Host '⚠️  token ว่างเปล่า - จะไม่เขียนไฟล์ token ใหม่' -ForegroundColor Yellow
    } else {
        # Write without a trailing newline so the wrapper .Trim() stays clean.
        [System.IO.File]::WriteAllText($TOKEN_FILE, $token.Trim())
        Write-Host "บันทึก token ไปที่: $TOKEN_FILE" -ForegroundColor Green
    }
} else {
    Write-Host "พบ token ที่มีอยู่แล้ว: $TOKEN_FILE (ใช้ -PromptToken เพื่อรีเซ็ตใหม่)" -ForegroundColor Green
}

# --- Write wrapper + shim (rewritten every run for idempotency) ---
Write-ProfileWrapper -ProfileDir $PROFILE_DIR
$BIN_DIR = Join-Path $PROFILE_DIR 'bin'
Write-CmdShim -BinDir $BIN_DIR

# --- PATH instructions ---
Write-Host ''
Write-Host '=== เพิ่ม bin ของ claude-9arm เข้า PATH ===' -ForegroundColor Cyan
Write-Host 'รันคำสั่งนี้ (ใช้ได้กับ terminal ใหม่เท่านั้น):'
Write-Host ''
Write-Host '    setx PATH "%PATH%;%USERPROFILE%\.claude-9arm\bin"'
Write-Host ''
Write-Host 'จากนั้นเปิด terminal (PowerShell) ใหม่ แล้วลองรัน: claude-9arm "ทดสอบ"' -ForegroundColor Yellow
Write-Host 'หมายเหตุ: PATH ปัจจุบันในหน้าต่างที่เปิดอยู่จะยังไม่เห็น - ต้องเปิด terminal ใหม่'

# --- Summary (Thai) ---
Write-Host ''
Write-Host '=== สรุปการติดตั้ง ===' -ForegroundColor Cyan
Write-Host '  • token ถูกเก็บไว้ที่ : %USERPROFILE%\.claude-9arm\token'
Write-Host '  • ค่าคอนฟิกแยก (profile): %USERPROFILE%\.claude-9arm'
Write-Host '  • wrapper อยู่ที่      : %USERPROFILE%\.claude-9arm\claude-9arm.ps1'
Write-Host '  • คำสั่งใช้             : claude-9arm "คำถามของคุณ"'
Write-Host '  • ทดสอบเชื่อมต่อ       : claude-9arm -HealthCheck'
Write-Host ''
Write-Host 'สามารถรันสคริปต์นี้อีกครั้งเพื่อติดตั้งใหม่ / รีเซ็ต token (-PromptToken)' -ForegroundColor Cyan
Write-Host 'Setup เสร็จเรียบร้อย' -ForegroundColor Green