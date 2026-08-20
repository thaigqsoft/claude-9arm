#!/usr/bin/env bash
# install-qwen-code-9arm-mac.sh - Wire the `qwen-code` agent to the 9arm gateway (macOS)
#
#   1. Requires ~/.claude-9arm/token (from install-claude-9arm-mac.sh).
#   2. Installs qwen-code via npm if not found (skippable with --skip-install).
#   3. Writes the `openai`-auth modelProviders into ~/.config/qwen-code/settings.json
#      pointing at https://gateway.9arm.co/v1, with the shared token as ARM_API_PASSPORT.
#   4. Prints usage.
#
# Safe to re-run: idempotent.

set -euo pipefail
SKIP_INSTALL=0
for a in "$@"; do
  case "$a" in
    --skip-install) SKIP_INSTALL=1 ;;
    -h|--help) echo "Usage: install-qwen-code-9arm-mac.sh [--skip-install]"; exit 0 ;;
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

echo "=== qwen-code -> 9arm gateway setup ==="

# 1. qwen-code presence
if command -v qwen-code >/dev/null 2>&1 || command -v qwen >/dev/null 2>&1; then
  echo "พบ qwen-code แล้ว: $(command -v qwen-code || command -v qwen)"
elif [[ "$SKIP_INSTALL" -eq 1 ]]; then
  echo 'ยังไม่พบ qwen-code (--skip-install) - ข้ามการติดตั้ง' >&2
else
  echo 'ยังไม่พบ qwen-code - กำลังติดตั้งผ่าน npm (global) ...'
  npm install -g @qwen-code/cli || npm install -g qwen-code
  echo 'ติดตั้ง qwen-code สำเร็จ'
fi

# 2. config dir
QC_DIR="$HOME/.config/qwen-code"
mkdir -p "$QC_DIR"
SETTINGS="$QC_DIR/settings.json"

# 3. merge settings.json (node)
node - "$SETTINGS" "$token" <<'EOF'
const fs = require('fs');
const [file, token] = process.argv.slice(2);
let cfg = {};
if (fs.existsSync(file)) { try { cfg = JSON.parse(fs.readFileSync(file,'utf8')); } catch { cfg={}; } }
cfg.env = cfg.env || {};
cfg.env.ARM_API_PASSPORT = token;
cfg.modelProviders = cfg.modelProviders || {};
cfg.modelProviders.openai = [
  { id: 'qwen3.8-27b-fp8',        name: 'Qwen 3.8 27b FP8',        baseUrl: 'https://gateway.9arm.co/v1', envKey: 'ARM_API_PASSPORT' },
  { id: 'deepseek-v4-flash-0731', name: 'DeepSeek V4 Flash 0731', baseUrl: 'https://gateway.9arm.co/v1', envKey: 'ARM_API_PASSPORT' },
];
fs.writeFileSync(file, JSON.stringify(cfg, null, 2));
EOF
echo "เขียน modelProviders ลง config: $SETTINGS"

# 4. summary
echo ''
echo '=== สรุป ==='
echo '  • เปิด qwen-code แล้วใช้ /model เลือก: qwen3.8-27b-fp8 หรือ deepseek-v4-flash-0731'
echo '  • ทดสอบ: qwen "คำถาม" (กดเลื่อน model)'
echo ''
echo 'ติดตั้งเรียบร้อย'