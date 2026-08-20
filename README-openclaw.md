# OpenClaw → 9arm Gateway

เชื่อม Coding agent **OpenClaw** เข้ากับ gateway `https://gateway.9arm.co` ของ **9Arm** ผ่าน token ตัวเดียวกับ claude-9arm.

> ### 🙏 ขอบคุณเจ้าชายไอทีแห่งประเทศไทย — 9Arm
> ช่วย **กดติดตาม (Subscribe)** เป็นกำลังใจ & เชียร์ค่าโทเค็นให้ AI ต่อยอดได้เรื่อยๆ
> 🔗 YouTube: <https://www.youtube.com/@9arm>

---

## สิ่งที่ต้องมีก่อน

- รัน `install-claude-9arm.ps1` (Windows) หรือ `install-claude-9arm-mac.sh` (macOS) ก่อน เพื่อสร้าง token ที่ `~/.claude-9arm/token`
- มี OpenClaw — ติดตั้งจาก https://docs.openclaw.ai/install

## ติดตั้ง

**Windows:**
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-openclaw-9arm.ps1
```

**macOS:**
```bash
bash install-openclaw-9arm-mac.sh
```

สคริปต์จะเขียน provider `9arm` ลงใน `~/.openclaw/openclaw.json` (`models.providers.9arm`) ชี้ไปที่ `https://gateway.9arm.co/v1` (OpenAI-compatible) พร้อม token

## วิธีใช้

เลือก model ในรูปแบบ `provider/model`:

- `9arm/qwen3.8-27b-fp8` — Qwen 3.8 27b FP8
- `9arm/deepseek-v4-flash-0731` — DeepSeek V4 Flash 0731

```bash
openclaw "คำถามของคุณ"
# แล้วเลือก /model -> 9arm/qwen3.8-27b-fp8
```

## Model ที่ใช้ได้

| Model ID (provider/model) |
|---|
| `9arm/qwen3.8-27b-fp8` |
| `9arm/deepseek-v4-flash-0731` |

---

## Troubleshooting

| อาการ | วิธีแก้ |
|---|---|
| `ไม่พบ token file` | รัน installer ของ claude-9arm ก่อนเพื่อสร้าง token |
| model หาย | เช็ค block `models.providers.9arm` ใน `~/.openclaw/openclaw.json` |
| gateway เงียบ/ช้า | gateway อาจชั่วคราวลง — รอสักครู่แล้วลองใหม่ |

## ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | ตำแหน่ง | หน้าที่ |
|---|---|---|
| `openclaw.json` | `~/.openclaw/openclaw.json` | config ของ OpenClaw (เขียนโดย installer) |
| `token` | `~/.claude-9arm/token` | gateway token (ของ claude-9arm) |