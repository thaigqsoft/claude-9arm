#!/usr/bin/env bash
# install-opencode-9arm-mac.sh - Wire the `opencode` coding agent to the 9arm gateway (macOS)
#
#   1. Requires ~/.claude-9arm/token (from install-claude-9arm-mac.sh).
#   2. Installs `opencode` via npm if not found (skippable with --skip-install).
#   3. Writes/merges the `9arm` provider into ~/.config/opencode/opencode.json
#      pointing at https://gateway.9arm.co/v1 using the shared token file.
#   4. Prints usage.
#
# Safe to re-run: idempotent.

set -euo pipefail
SKIP_INSTALL=0
for a in "$@"; do
  case "$a" in
    --skip-install) SKIP_INSTALL=1 ;;
    -h|--help) echo "Usage: install-opencode-9arm-mac.sh [--skip-install]"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 1 ;;
  esac
done

PROFILE_DIR="$HOME/.claude-9arm"
TOKEN_FILE="$PROFILE_DIR/token"
if [[ ! -r "$TOKEN_FILE" ]]; then
  echo "ไม่พบ token file: $TOKEN_FILE - กรุณารัน install-claude-9arm-mac.sh ก่อน (token มาจากเจ้าของ)" >&2
  exit 1
fi

echo "=== opencode -> 9arm gateway setup ==="
echo "ใช้ token เดียวกับ claude-9arm: $TOKEN_FILE"

# 1. opencode presence
if command -v opencode >/dev/null 2>&1; then
  echo "พบ opencode แล้ว: $(command -v opencode)"
elif [[ "$SKIP_INSTALL" -eq 1 ]]; then
  echo 'ยังไม่พบ opencode (--skip-install) - ข้ามการติดตั้ง' >&2
else
  echo 'ยังไม่พบ opencode - กำลังติดตั้งผ่าน npm (global) ...'
  npm install -g opencode-ai
  echo 'ติดตั้ง opencode สำเร็จ'
fi

# 2. config dir
OC_DIR="$HOME/.config/opencode"
mkdir -p "$OC_DIR"
OC_FILE="$OC_DIR/opencode.json"

# 3. merge provider (simple: if opencode.json not JSON, start fresh; else append via node)
# Use a small node one-liner so we merge without clobbering an existing config.
node - "$OC_FILE" "$TOKEN_FILE" <<'EOF'
const fs = require('fs');
const [file, tokenFile] = process.argv.slice(2);
let cfg = {};
if (fs.existsSync(file)) {
  try { cfg = JSON.parse(fs.readFileSync(file, 'utf8')); } catch { cfg = {}; }
}
cfg.provider = cfg.provider || {};
cfg.provider['9arm'] = {
  name: '9arm Gateway',
  options: { baseURL: 'https://gateway.9arm.co/v1', apiKey: `{file:${tokenFile}}` },
  models: {
    'qwen3.8-27b-fp8':       { name: 'Qwen 3.8 27b FP8' },
    'deepseek-v4-flash-0731': { name: 'DeepSeek V4 Flash 0731' },
  },
};
fs.writeFileSync(file, JSON.stringify(cfg, null, 2));
EOF
echo "เขียน provider '9arm' ลง config: $OC_FILE"

# 4. summary
echo ''
echo '=== สรุป ==='
echo '  • ตัวเลือก model:'
echo '      opencode --model 9arm/qwen3.8-27b-fp8 "คำถาม"'
echo '      opencode --model 9arm/deepseek-v4-flash-0731 "คำถาม"'
echo '  • ตั้งเป็นค่าเริ่มต้น: เพิ่ม "model": "9arm/qwen3.8-27b-fp8" ใน opencode.json'
echo ''
echo 'ติดตั้งเรียบร้อย'