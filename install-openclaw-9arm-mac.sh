#!/usr/bin/env bash
# install-openclaw-9arm-mac.sh - Wire the OpenClaw agent to the 9arm gateway (macOS)
#
#   1. Requires ~/.claude-9arm/token (from install-claude-9arm-mac.sh).
#   2. Installs OpenClaw if not found (skippable with --skip-install).
#   3. Writes/merges a `9arm` custom provider into OpenClaw config (~/.openclaw/openclaw.json)
#      pointing at https://gateway.9arm.co/v1 (OpenAI-compatible) using the shared token.
#   4. Prints usage.
#
# Safe to re-run: idempotent.
#
# NOTE: this writes the token VALUE into the provider's apiKey field (OpenClaw reads
# ${VAR} or plain values from provider config; it does not support {file:...} like
# opencode). Same trust scope as claude-9arm's own token file.

set -euo pipefail
SKIP_INSTALL=0
for a in "$@"; do
  case "$a" in
    --skip-install) SKIP_INSTALL=1 ;;
    -h|--help) echo "Usage: install-openclaw-9arm-mac.sh [--skip-install]"; exit 0 ;;
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

echo "=== OpenClaw -> 9arm gateway setup ==="

# 1. openclaw presence
if command -v openclaw >/dev/null 2>&1; then
  echo "พบ openclaw แล้ว: $(command -v openclaw)"
elif [[ "$SKIP_INSTALL" -eq 1 ]]; then
  echo 'ยังไม่พบ openclaw (--skip-install) - ข้ามการติดตั้ง' >&2
else
  echo 'ยังไม่พบ openclaw - ติดตั้ง: (ดู https://docs.openclaw.ai/install)'
  echo 'ลอง: npx openclaw@latest install'
  npx openclaw@latest install || echo 'โปรดติดตั้ง OpenClaw ด้วยตนเองจาก https://docs.openclaw.ai/install' >&2
fi

# 2. config dir
OC_DIR="$HOME/.openclaw"
mkdir -p "$OC_DIR"
OC_FILE="$OC_DIR/openclaw.json"

# 3. merge provider (node)
node - "$OC_FILE" "$token" <<'EOF'
const fs = require('fs');
const [file, token] = process.argv.slice(2);
let cfg = {};
if (fs.existsSync(file)) { try { cfg = JSON.parse(fs.readFileSync(file,'utf8')); } catch { cfg={}; } }
// OpenClaw: models.providers.<name> { baseUrl, apiKey, api, models }
cfg.models = cfg.models || {};
cfg.models.providers = cfg.models.providers || {};
cfg.models.providers['9arm'] = {
  baseUrl: 'https://gateway.9arm.co/v1',
  apiKey: token,
  api: 'openai-completions',
  models: [
    { id: 'qwen3.8-27b-fp8',        name: 'Qwen 3.8 27b FP8' },
    { id: 'deepseek-v4-flash-0731', name: 'DeepSeek V4 Flash 0731' },
  ],
};
fs.writeFileSync(file, JSON.stringify(cfg, null, 2));
EOF
echo "เขียน provider '9arm' ลง config: $OC_FILE"

# 4. summary
echo ''
echo '=== สรุป ==='
echo '  • model ให้ใช้: 9arm/qwen3.8-27b-fp8  หรือ  9arm/deepseek-v4-flash-0731'
echo '  • ใน OpenClaw เลือก model รูปแบบ  provider/model  เช่น /model 9arm/qwen3.8-27b-fp8'
echo ''
echo 'ติดตั้งเรียบร้อย'