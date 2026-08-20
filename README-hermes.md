# Hermes → 9arm Gateway

เชื่อม AI agent **Hermes** เข้ากับ gateway `https://gateway.9arm.co` ของ **9Arm** ผ่าน token ตัวเดียวกับ claude-9arm.

> ### 🙏 ขอบคุณเจ้าชายไอทีแห่งประเทศไทย — 9Arm
> ช่วย **กดติดตาม (Subscribe)** เป็นกำลังใจ & เชียร์ค่าโทเค็นให้ AI ต่อยอดได้เรื่อยๆ
> 🔗 YouTube: <https://www.youtube.com/@9arm>

---

## สิ่งที่ต้องมีก่อน

- รัน `install-claude-9arm.ps1` (Windows) หรือ `install-claude-9arm-mac.sh` (macOS) ก่อน เพื่อสร้าง token ที่ `~/.claude-9arm/token`
- มี Hermes — ติดตั้งจาก https://hermes-agent.nousresearch.com (pip / uv / brew)

## ติดตั้ง

**Windows:**
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-hermes-9arm.ps1
```

**macOS:**
```bash
bash install-hermes-9arm-mac.sh
```

สคริปต์จะเขียน `OPENAI_API_KEY` + `OPENAI_BASE_URL=https://gateway.9arm.co/v1` ลงใน `~/.hermes/.env` (provider `openai-api` ของ Hermes)

## วิธีใช้

```bash
hermes "คำถามของคุณ"
# เปลี่ยน provider ด้วย /model -> openai-api
# แล้วใช้ model:  qwen3.8-27b-fp8  หรือ  deepseek-v4-flash-0731
```

## Model ที่ใช้ได้

| Model ID |
|---|
| `qwen3.8-27b-fp8` |
| `deepseek-v4-flash-0731` |

---

## Troubleshooting

| อาการ | วิธีแก้ |
|---|---|
| `ไม่พบ token file` | รัน installer ของ claude-9arm ก่อนเพื่อสร้าง token |
| provider ไม่โผล่ | เช็ค `~/.hermes/.env` มี `OPENAI_API_KEY` + `OPENAI_BASE_URL` หรือไม่ |
| gateway เงียบ/ช้า | gateway อาจชั่วคราวลง — รอสักครู่แล้วลองใหม่ |

## ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | ตำแหน่ง | หน้าที่ |
|---|---|---|
| `.env` | `~/.hermes/.env` | config ของ Hermes (เขียนโดย installer) |
| `token` | `~/.claude-9arm/token` | gateway token (ของ claude-9arm) |