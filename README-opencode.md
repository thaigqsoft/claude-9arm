# opencode → 9arm Gateway

เชื่อมตัว Coding agent **opencode** เข้ากับ gateway `https://gateway.9arm.co` ของ **9Arm** ผ่าน token ตัวเดียวกับ claude-9arm.

> ### 🙏 ขอบคุณเจ้าชายไอทีแห่งประเทศไทย — 9Arm
> ช่วย **กดติดตาม (Subscribe)** เป็นกำลังใจ & เชียร์ค่าโทเค็นให้ AI ต่อยอดได้เรื่อยๆ
> 🔗 YouTube: <https://www.youtube.com/@9arm>

---

## สิ่งที่ต้องมีก่อน

- รัน `install-claude-9arm.ps1` (Windows) หรือ `install-claude-9arm-mac.sh` (macOS) ก่อน เพื่อสร้าง token ที่ `~/.claude-9arm/token`
- มี `opencode` — ใช้สคริปต์นี้ติดตั้งให้อัตโนมัติ หรือติดตั้งเอง: `npm install -g opencode-ai`

## ติดตั้ง

**Windows:**
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-opencode-9arm.ps1
```

**macOS:**
```bash
bash install-opencode-9arm-mac.sh
```

สคริปต์จะเขียน provider `9arm` ลงใน `opencode.json` โดยใช้ token path จาก `~/.claude-9arm/token` แล้วพิมพ์วิธีใช้

## วิธีใช้

```bash
opencode --model 9arm/qwen3.8-27b-fp8 "คำถามของคุณ"
opencode --model 9arm/deepseek-v4-flash-0731 "คำถามของคุณ"
```

### ตั้งเป็น model เริ่มต้น (ไม่ต้องระบุ `--model` ทุกครั้ง)

เพิ่มบรรทัดนี้ใน `opencode.json`:

```json
{ "model": "9arm/qwen3.8-27b-fp8" }
```

## Model ที่ใช้ได้

| Model ID | ชื่อ |
|---|---|
| `qwen3.8-27b-fp8` | Qwen 3.8 27b FP8 |
| `deepseek-v4-flash-0731` | DeepSeek V4 Flash 0731 |

---

## Troubleshooting

| อาการ | วิธีแก้ |
|---|---|
| `ไม่พบ token file` | รัน installer ของ claude-9arm ก่อนเพื่อสร้าง token |
| `model not found / 9arm/...` | ลอง `opencode --model 9arm/qwen3.8-27b-fp8` อีกครั้ง; เช็คว่ามี provider `9arm` ใน config |
| gateway เงียบ/ช้า | gateway อาจชั่วคราวลง — รอสักครู่แล้วลองใหม่ |

## ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | ตำแหน่ง | หน้าที่ |
|---|---|---|
| `opencode.json` | `~/.config/opencode/opencode.json` | config ของ opencode (เขียนโดย installer) |
| `token` | `~/.claude-9arm/token` | gateway token (ของ claude-9arm) |