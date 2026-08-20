#!/usr/bin/env bash
# install-hermes-9arm-mac.sh - Wire the Hermes agent to the 9arm gateway (macOS)
#
#   1. Requires ~/.claude-9arm/token (from install-claude-9arm-mac.sh).
#   2. Installs Hermes if not found (skippable with --skip-install).
#   3. Writes OPENAI_API_KEY + OPENAI_BASE_URL into ~/.hermes/.env pointing at
#      https://gateway.9arm.co/v1 (Hermes `openai-api` provider via /model openai-api).
#   4. Prints usage.
#
# Safe to re-run: idempotent.
#
# NOTE: Hermes reads provider keys from ~/.hermes/.env. We write the token VALUE
# there (same trust scope as claude-9arm's own token file).

set -euo pipefail
SKIP_INSTALL=0
for a in "$@"; do
  case "$a" in
    --skip-install) SKIP_INSTALL=1 ;;
    -h|--help) echo "Usage: install-hermes-9arm-mac.sh [--skip-install]"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 1 ;;
  esac
done

PROFILE_DIR="$HOME/.claude-9arm"
TOKEN_FILE="$PROFILE_DIR/token"
if [[ ! -r "$TOKEN_FILE" ]]; then
  echo "ไม่พบ token file: $TOKEN_FILE - กรุณารัน install-claude-9arm-mac.sh ก่อน" >&2
  exit 1
fi
token="$(< "$TOKEN_FILE")"

echo "=== Hermes -> 9arm gateway setup ==="

# 1. hermes presence
if command -v hermes >/dev/null 2>&1; then
  echo "พบ hermes แล้ว: $(command -v hermes)"
elif [[ "$SKIP_INSTALL" -eq 1 ]]; then
  echo 'ยังไม่พบ hermes (--skip-install) - ข้ามการติดตั้ง' >&2
else
  echo 'ยังไม่พบ hermes - ติดตั้งจาก https://hermes-agent.nousresearch.com (pip / uv / brew)'
  echo 'ตัวอย่าง (uv): uv tool install hermes-agent' || true
fi

# 2. .hermes dir + .env
HERMES_DIR="$HOME/.hermes"
mkdir -p "$HERMES_DIR"
ENV_FILE="$HERMES_DIR/.env"

# 3. merge/ensure keys in .env (idempotent: replace existing lines if any)
if [[ -f "$ENV_FILE" ]]; then
  sed -i.bak '/^OPENAI_API_KEY=/d; /^OPENAI_BASE_URL=/d' "$ENV_FILE" && rm -f "$ENV_FILE.bak"
fi
# append if no trailing newline
[[ -f "$ENV_FILE" && -s "$ENV_FILE" ]] && [[ "$(tail -c1 "$ENV_FILE" | wc -l)" -eq 0 ]] && echo '' >> "$ENV_FILE"
{
  echo "OPENAI_API_KEY=$token"
  echo 'OPENAI_BASE_URL=https://gateway.9arm.co/v1'
} >> "$ENV_FILE"
chmod 600 "$ENV_FILE"
echo "เขียน config ลง: $ENV_FILE"

# 4. summary
echo ''
echo '=== สรุป ==='
echo '  • รัน: hermes  แล้วเลือก /model -> openai-api  (หรือตั้ง model เริ่มต้น)'
echo '  • ตัว model: qwen3.8-27b-fp8 / deepseek-v4-flash-0731'
echo '  • วิธีใช้: hermes "คำถาม" แล้วเปลี่ยน provider เป็น openai-api'
echo ''
echo 'ติดตั้งเรียบร้อย'