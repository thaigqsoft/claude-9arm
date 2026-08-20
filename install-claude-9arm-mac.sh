#!/usr/bin/env bash
# install-claude-9arm-mac.sh - One-time macOS setup for claude-9arm
#
# What it does:
#   1. Verifies node + npm are on PATH (never installs Node silently).
#   2. Installs Claude Code via npm ONLY if the `claude` command is missing
#      (skipped wholesale with --skip-install).
#   3. Creates the profile dir ~/.claude-9arm.
#   4. Prompts for the gateway token (silent read, never echoes) and stores it
#      in ~/.claude-9arm/token with NO trailing newline. Only prompts if the
#      token is missing, or when --prompt-token is passed (to reset).
#   5. Writes the runtime wrapper claude-9arm.sh into the profile dir.
#   6. Creates a claude-9arm symlink in ~/.claude-9arm/bin so you can type
#      `claude-9arm` anywhere (once the bin dir is on PATH).
#   7. Adds ~/.claude-9arm/bin to PATH in .zshrc / .bash_profile.
#   8. Prints usage + where the token lives.
#
# Safe to re-run: idempotent.

set -euo pipefail

PROMPT_TOKEN=0   # force re-prompt for a new token (to reset)
SKIP_INSTALL=0   # skip the npm global install entirely

usage() {
    cat <<'USAGE'
การใช้งาน: install-claude-9arm-mac.sh [ตัวเลือก]

ตัวเลือก:
  --prompt-token   บังคับให้กรอก token ใหม่ (ใช้รีเซ็ต token)
  --skip-install   ข้ามการติดตั้ง Claude Code ผ่าน npm
  -h, --help       แสดงความช่วยเหลือนี้
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prompt-token) PROMPT_TOKEN=1; shift ;;
        --skip-install) SKIP_INSTALL=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "ข้อผิดพลาด: ไม่รู้จักตัวเลือก '$1'" >&2; usage >&2; exit 1 ;;
    esac
done

# ==================== 1. node + npm check ====================
if ! command -v node >/dev/null 2>&1; then
    echo ''
    echo '⚠️  ไม่พบ Node.js ใน PATH'
    echo 'กรุณาติดตั้ง Node.js LTS ก่อน แล้วจึงรันสคริปต์นี้อีกครั้ง'
    echo 'ติดตั้งผ่าน brew:'
    echo ''
    echo '    brew install node'
    echo ''
    echo 'หรือดาวน์โหลดจาก https://nodejs.org แล้วเลือกตัว LTS'
    exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
    echo ''
    echo '⚠️  พบ node แต่ไม่พบ npm ใน PATH'
    echo 'npm ปกติมากับ Node.js - ลองเปิด terminal ใหม่หลังจากติดตั้ง Node.js'
    exit 1
fi
echo "node: $(node --version)"
echo "npm : $(npm --version)"

# ==================== 2. claude install (if missing) ====================
if command -v claude >/dev/null 2>&1; then
    echo "พบ Claude Code แล้ว: $(command -v claude)"
else
    if [[ "$SKIP_INSTALL" -eq 1 ]]; then
        echo 'ข้ามการติดตั้ง Claude Code (--skip-install) แต่ยังไม่พบคำสั่ง claude'
    else
        echo 'ยังไม่พบ claude - กำลังติดตั้ง Claude Code ผ่าน npm (global) ...'
        npm install -g @anthropic-ai/claude-code || {
            rc=$?
            echo "npm install ล้มเหลว (exit code: $rc)" >&2
            echo 'ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต / proxy แล้วลองอีกครั้ง' >&2
            exit 1
        }
        echo 'ติดตั้ง Claude Code สำเร็จ'
    fi
fi

# ==================== 3. profile dir ====================
PROFILE_DIR="$HOME/.claude-9arm"
mkdir -p "$PROFILE_DIR"
echo "สร้างโฟลเดอร์: $PROFILE_DIR"

# ==================== 4. token ====================
TOKEN_FILE="$PROFILE_DIR/token"
if [[ "$PROMPT_TOKEN" -eq 1 ]] || [[ ! -f "$TOKEN_FILE" ]]; then
    echo ''
    echo 'กรุณาใส่ gateway token (token ที่เจ้าของออกให้)'
    read -r -s -p 'Gateway token: ' token </dev/tty || true
    echo ''
    if [[ -z "${token:-}" ]]; then
        echo '⚠️  token ว่างเปล่า - จะไม่เขียนไฟล์ token ใหม่'
    else
        # Write without a trailing newline so the wrapper "$(<file)" stays clean.
        printf '%s' "$token" > "$TOKEN_FILE"
        echo "บันทึก token ไปที่: $TOKEN_FILE"
    fi
else
    echo "พบ token ที่มีอยู่แล้ว: $TOKEN_FILE (ใช้ --prompt-token เพื่อรีเซ็ตใหม่)"
fi

# ==================== 5. write wrapper ====================
# --- Runtime wrapper (claude-9arm-mac.sh). Kept byte-identical to the
# --- standalone claude-9arm-mac.sh file in this project; the single-quoted
# --- heredoc ('EOF') prevents any $ / $(/) expansion.
cat <<'EOF' > "$PROFILE_DIR/claude-9arm.sh"
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
EOF
chmod +x "$PROFILE_DIR/claude-9arm.sh"
echo "เขียน wrapper: $PROFILE_DIR/claude-9arm.sh"

# ==================== 6. symlink into bin ====================
BIN_DIR="$PROFILE_DIR/bin"
mkdir -p "$BIN_DIR"
ln -sf "$PROFILE_DIR/claude-9arm.sh" "$BIN_DIR/claude-9arm"
echo "สร้าง symlink: $BIN_DIR/claude-9arm"

# ==================== 7. PATH ====================
PATH_LINE='export PATH="$PATH:$HOME/.claude-9arm/bin"'
zshrc="$HOME/.zshrc"
bash_profile="$HOME/.bash_profile"
targets=()
[[ -f "$zshrc" ]] && targets+=("$zshrc")
[[ -f "$bash_profile" ]] && targets+=("$bash_profile")
if [[ ${#targets[@]} -eq 0 ]]; then
    targets+=("$zshrc")
    echo "# เพิ่ม PATH สำหรับ claude-9arm (สร้างโดย install-claude-9arm-mac.sh)" >> "$zshrc"
    echo "ไม่พบ .zshrc / .bash_profile - สร้างไฟล์ใหม่: $zshrc"
fi
for f in "${targets[@]}"; do
    # Match "claude-9arm/bin" (present both as literal "$HOME/.claude-9arm/bin"
    # and as the expanded path) so re-runs don't duplicate the export line.
    if ! grep -qF 'claude-9arm/bin' "$f" 2>/dev/null; then
        echo "$PATH_LINE" >> "$f"
        echo "เพิ่ม PATH ไปยัง: $f"
    else
        echo "PATH มี claude-9arm อยู่แล้วใน: $f (ข้าม)"
    fi
done

# ==================== 8. summary ====================
echo ''
echo '=== สรุปการติดตั้ง ==='
echo "  • token ถูกเก็บไว้ที่ : $HOME/.claude-9arm/token"
echo "  • ค่าคอนฟิกแยก (profile): $HOME/.claude-9arm"
echo "  • wrapper อยู่ที่      : $HOME/.claude-9arm/claude-9arm.sh"
echo "  • คำสั่งใช้             : claude-9arm \"คำถามของคุณ\""
echo "  • ทดสอบเชื่อมต่อ       : claude-9arm -HealthCheck"
echo ''
echo 'PATH ถูกเพิ่มแล้ว — เปิด terminal ใหม่เพื่อให้มีผล (window ที่เปิดอยู่จะยังใช้ PATH เก่า)'
echo 'สามารถรันสคริปต์นี้อีกครั้งเพื่อติดตั้งใหม่ / รีเซ็ต token (--prompt-token)'
echo 'Setup เสร็จเรียบร้อย'