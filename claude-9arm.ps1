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
    Write-Host "ไม่พบ token file: $TOKEN_FILE" -ForegroundColor Red
    Write-Host 'กรุณารัน install-claude-9arm.ps1 เพื่อตั้งค่า token ก่อน (token มาจากเจ้าของ)' -ForegroundColor Red
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
        Write-Host 'claude command not found - cannot run health check. Run install-claude-9arm.ps1 first.' -ForegroundColor Red
        exit 1
    }
    $probeOut = & $probeClaude.Source -p 'What is 1+1? Reply with the number only.'
    $probeText = ($probeOut | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $probeText -notmatch '2') {
        Write-Host 'claude-9arm health check FAILED' -ForegroundColor Red
        exit 1
    }
    Write-Host "Health check OK: $probeText"
}

# --- Invoke claude with the forwarded arguments ---
$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude) {
    Write-Host 'ไม่พบคำสั่ง claude - กรุณารัน install-claude-9arm.ps1 (ติดตั้ง Claude Code) ก่อน' -ForegroundColor Red
    exit 1
}

& $claude.Source @remainingArgs
exit $LASTEXITCODE