#!/usr/bin/env bash
# claude-9arm-mac.sh - macOS runtime wrapper for claude-9arm
# Mirrors the Linux bash wrapper env logic. Health probe is OFF by default
# (opt-in via -HealthCheck) to avoid an extra token round-trip for the friend.
# Invoke through the claude-9arm symlink in ~/.claude-9arm/bin.
set -euo pipefail

PROFILE_DIR="$HOME/.claude-9arm"
TOKEN_FILE="$PROFILE_DIR/token"

if [[ ! -r "$TOKEN_FILE" ]]; then
    echo "ไม่พบ token file: $TOKEN_FILE" >&2
    echo 'กรุณารัน install-claude-9arm-mac.sh เพื่อตั้งค่า token ก่อน (token มาจากเจ้าของ)' >&2
    exit 1
fi

# --- Forwarded args; strip -HealthCheck before invoking claude ---
args=()
health_check=0
for a in "$@"; do
    if [[ "$a" == "-HealthCheck" ]]; then
        health_check=1
    else
        args+=("$a")
    fi
done

# --- Environment mirror of the original bash wrapper ---
export CLAUDE_CONFIG_DIR="$PROFILE_DIR"
export CLAUDE_OP_NO_HEADROOM=1
export ANTHROPIC_BASE_URL="https://gateway.9arm.co"
export ANTHROPIC_AUTH_TOKEN="$(< "$TOKEN_FILE")"
export ANTHROPIC_MODEL="deepseek-v4-flash-0731"
export ANTHROPIC_SMALL_FAST_MODEL="deepseek-v4-flash-0731"
export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-flash-0731"
export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-flash-0731"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash-0731"
export OBSCURA_ALLOW_PRIVATE_NETWORK=1
export CLAUDE_CODE_MAX_CONTEXT_TOKENS=128000
export CLAUDE_CODE_DISABLE_ADVISOR_TOOL=1
unset ANTHROPIC_API_KEY 2>/dev/null || true

# Inject an isolated profile CLAUDE.md when present.
if [[ -r "$PROFILE_DIR/CLAUDE.md" ]]; then
    args=(--append-system-prompt-file "$PROFILE_DIR/CLAUDE.md" "${args[@]}")
fi

# --- Optional health probe (OFF by default; opt-in with -HealthCheck) ---
if [[ "$health_check" -eq 1 && "${CLAUDE_9ARM_SKIP_CHECK:-0}" != "1" ]]; then
    if ! command -v claude >/dev/null 2>&1; then
        echo 'claude command not found - cannot run health check. Run install-claude-9arm-mac.sh first.' >&2
        exit 1
    fi
    probe_out="$(claude -p 'What is 1+1? Reply with the number only.' || true)"
    if [[ "$probe_out" != *2* ]]; then
        echo 'claude-9arm health check FAILED' >&2
        exit 1
    fi
    echo "Health check OK: $probe_out"
fi

# --- Invoke claude with the forwarded arguments ---
if ! command -v claude >/dev/null 2>&1; then
    echo 'ไม่พบคำสั่ง claude - กรุณารัน install-claude-9arm-mac.sh (ติดตั้ง Claude Code) ก่อน' >&2
    exit 1
fi
exec claude "${args[@]}"
