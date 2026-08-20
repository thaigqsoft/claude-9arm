# Qwen Code → 9arm Gateway

เชื่อม Coding agent **Qwen Code** เข้ากับ gateway `https://gateway.9arm.co` ของ **9Arm** ผ่าน token ตัวเดียวกับ claude-9arm.

> ### 🙏 ขอบคุณเจ้าชายไอทีแห่งประเทศไทย — 9Arm
> ช่วย **กดติดตาม (Subscribe)** เป็นกำลังใจ & เชียร์ค่าโทเค็นให้ AI ต่อยอดได้เรื่อยๆ
> 🔗 YouTube: <https://www.youtube.com/@9arm>

---

## สิ่งที่ต้องมีก่อน

- รัน `install-claude-9arm.ps1` (Windows) หรือ `install-claude-9arm-mac.sh` (macOS) ก่อน เพื่อสร้าง token ที่ `~/.claude-9arm/token`
- มี Qwen Code (`qwen` / `qwen-code`) — ใช้สคริปต์นี้ติดตั้งให้อัตโนมัติ หรือติดตั้งเองจาก [QwenLM/qwen-code](https://github.com/QwenLM/qwen-code)

## ติดตั้ง

**Windows:**
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-qwen-code-9arm.ps1
```

**macOS:**
```bash
bash install-qwen-code-9arm-mac.sh
```

สคริปต์จะเขียน `modelProviders` (auth type `openai`) ลงใน `settings.json` ของ Qwen Code โดยชี้ไปที่ `https://gateway.9arm.co/v1` และใส่ token เป็น `ARM_API_PASSPORT`

## วิธีใช้

เปิด Qwen Code แล้วใช้คำสั่ง `/model` เลือกรายชื่อ:

- `qwen3.8-27b-fp8` — Qwen 3.8 27b FP8
- `deepseek-v4-flash-0731` — DeepSeek V4 Flash 0731

```bash
qwen "คำถามของคุณ"   # แล้วกดเลื่อน model ที่ต้องการ
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
| model หายจาก /model | เช็คว่ามี block `modelProviders.openai` ใน `~/.config/qwen-code/settings.json` |
| gateway เงียบ/ช้า | gateway อาจชั่วคราวลง — รอสักครู่แล้วลองใหม่ |

## ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | ตำแหน่ง | หน้าที่ |
|---|---|---|
| `settings.json` | `~/.config/qwen-code/settings.json` | config ของ Qwen Code (เขียนโดย installer) |
| `token` | `~/.claude-9arm/token` | gateway token (ของ claude-9arm) |