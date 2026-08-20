# claude-9arm — macOS bash wrapper

ตัวห่อ (wrapper) สำหรับเรียก Claude Code ผ่าน gateway `https://gateway.9arm.co` บน macOS
พอร์ตมาจากเวอร์ชัน Linux (bash) — ใช้ model เดียวกันและแยก profile/config แยกเป็นของตัวเอง

> ### 🙏 ขอบคุณเจ้าชายไอทีแห่งประเทศไทย — 9Arm
> สคริปต์ตัวนี้เชื่อมต่อกับ AI gateway ของ **9Arm (เจ้าชายไอทีแห่งประเทศไทย)**
> ถ้าใช้งานแล้วถูกใจ ช่วย **กดติดตาม (Subscribe)** เป็นกำลังใจ & เชียร์ค่าโทเค็น (token) ที่ใช้เลี้ยง AI ให้เค้าได้ต่อยอดไปเรื่อยๆ
>
> 🔗 YouTube: <https://www.youtube.com/@9arm>

> ต่างจากเวอร์ชัน Windows ตรงที่บน macOS ไม่มี ExecutionPolicy และ shim เป็น **symlink** (ไม่มี `.cmd`)
> ตัว script เขียนด้วย **bash** (`#!/usr/bin/env bash`) — หน้า terminal เริ่มต้นเป็น zsh ก็รันได้

---

## ความต้องการของระบบ (Requirements)

- **macOS** (Apple Silicon หรือ Intel ก็ได้)
- **Node.js LTS** (มาพร้อม `npm`) และ `bash`, `curl` (มากับ macOS อยู่แล้ว)
- ถ้ายังไม่มี Node.js ให้ติดตั้งผ่าน brew:
  ```bash
  brew install node
  ```
  หรือดาวน์โหลดตัว LTS จาก https://nodejs.org
- อินเทอร์เน็ต (สำหรับติดตั้ง Claude Code ผ่าน npm และคุยกับ gateway)

---

## 1) ติดตั้ง Installer

รันสคริปต์ `install-claude-9arm-mac.sh` หนึ่งครั้ง:

### วิธี A — ผ่าน bash โดยตรง
```bash
bash install-claude-9arm-mac.sh
```

### วิธี B — ให้สิทธิ์ execute แล้วรัน
```bash
chmod +x install-claude-9arm-mac.sh
./install-claude-9arm-mac.sh
```

สิ่งที่สคริปต์ทำ:
1. ตรวจว่า `node` + `npm` มีหรือไม่ (ถ้าไม่มี จะบอกวิธีติดตั้ง Node.js LTS และจบการทำงาน — ไม่ติดตั้งเงียบๆ)
2. ถ้ายังไม่มี `claude` จะติดตั้ง Claude Code ผ่าน npm (`@anthropic-ai/claude-code`)
3. สร้างโฟลเดอร์ `~/.claude-9arm`
4. ให้กรอก **gateway token** (เก็บไว้ใน `~/.claude-9arm/token` แบบไม่ขึ้นบรรทัดใหม่)
5. เขียน wrapper `claude-9arm.sh` + symlink `claude-9arm` ลงใน `~/.claude-9arm/bin`
6. เพิ่ม `~/.claude-9arm/bin` เข้า PATH ใน `.zshrc` / `.bash_profile` และสรุปการใช้งาน

---

## 2) Token มาจากไหน

Token เป็นค่าที่ **เจ้าของ (owner) เป็นผู้ออกให้** — เป็นหัวข้อเดียวกับที่ใช้กับ gateway `9arm`

- เก็บไว้ที่: `~/.claude-9arm/token`
- ห้ามแชร์ token นี้ให้ใคร
- อยากรีเซ็ต token → รัน installer อีกครั้งด้วย `--prompt-token`

```bash
bash install-claude-9arm-mac.sh --prompt-token
```

---

## 3) เพิ่ม bin เข้า PATH

สคริปต์ติดตั้งจะเพิ่ม `export PATH="$PATH:$HOME/.claude-9arm/bin"` ลงใน `.zshrc` / `.bash_profile`
โดยอัตโนมัติ (เฉพาะไฟล์ที่มีอยู่; ถ้าไม่มีทั้งคู่จะสร้าง `.zshrc`)

แล้ว **เปิด terminal ใหม่** — window ที่เปิดอยู่ในขณะนั้นจะยังใช้ PATH เก่า

ถ้าอยากเพิ่มเอง (กรณีที่ใช้ shell แปลกๆ):
```bash
echo 'export PATH="$PATH:$HOME/.claude-9arm/bin"' >> ~/.zshrc
# หรือ ~/.bash_profile แล้วเปิด terminal ใหม่
```

---

## 4) วิธีใช้งาน

```bash
claude-9arm "คำถามของคุณ"
```

ตัวอย่าง:
```bash
claude-9arm "สรุปให้ฟังว่าวันนี้ต้องทำอะไรบ้าง"
claude-9arm "เขียนโปรแกรม Python คิดเลขง่ายๆ ให้หน่อย"
```

ทดสอบว่าต่อ gateway สำเร็จ (health check):
```bash
claude-9arm -HealthCheck
```
จะถาม Claude ว่า `What is 1+1?` และถ้าไม่ได้คำตอบที่มีเลข `2` จะรายงานว่าล้มเหลว

> หมายเหตุ: health check ถูกปิดเป็นค่าเริ่มต้นเพื่อประหยัด token ของเพื่อน — จะรันก็ต่อเมื่อส่ง `-HealthCheck`.
> ถ้าต้องการข้าม health check แม้ส่ง `-HealthCheck` ให้ตั้ง `CLAUDE_9ARM_SKIP_CHECK=1`

---

## 5) Troubleshooting

| อาการ | สาเหตุ / วิธีแก้ |
|---|---|
| `ไม่พบ token file` | ยังไม่ได้กรอก token — รัน installer อีกครั้งให้ครบ |
| `command not found: claude-9arm` | ยังไม่ได้เพิ่ม bin เข้า PATH หรือยังไม่เปิด terminal ใหม่ — ดูข้อ 3 |
| `command not found: node` | ยังไม่ได้ติดตั้ง Node.js — ติดตั้งด้วย `brew install node` แล้วเปิด terminal ใหม่ |
| `npm install ล้มเหลว / network error` | ตรวจอินเทอร์เน็ต / proxy แล้วลองใหม่; ถ้าติดตั้ง node ใหม่ให้เปิด terminal ใหม่ |
| `ไม่พบคำสั่ง claude` | ติดตั้ง Claude Code ไม่สำเร็จ — รัน installer อีกครั้ง (หรือ `npm install -g @anthropic-ai/claude-code` เอง) |
| health check FAILED | gateway ตาย / token ผิด — ลองใหม่ หรือติดต่อเจ้าของเรื่อง token |

---

## เชื่อมต่อกับ agent อื่น (ใช้ token เดียวกัน)

มีสคริปต์เชื่อม coding agent ตัวอื่นเข้ากับ gateway 9arm เดียวกัน (ใช้ token ตัวเดียวกับ claude-9arm). ดู README ของแต่ละตัว:

- **opencode** → `install-opencode-9arm-mac.sh` — [README-opencode.md](README-opencode.md)
- **Qwen Code** → `install-qwen-code-9arm-mac.sh` — [README-qwen-code.md](README-qwen-code.md)
- **OpenClaw** → `install-openclaw-9arm-mac.sh` — [README-openclaw.md](README-openclaw.md)
- **Hermes** → `install-hermes-9arm-mac.sh` — [README-hermes.md](README-hermes.md)

ทุกตัวต้องการ token จาก `install-claude-9arm-mac.sh` ก่อน แล้วค่อยเลือกติดตั้ง agent ที่เพื่อนใช้จริง

---

## ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | ตำแหน่ง | หน้าที่ |
|---|---|---|
| `install-claude-9arm-mac.sh` | โปรเจกต์นี้ | ติดตั้งครั้งเดียว (idempotent) |
| `claude-9arm-mac.sh` | โปรเจกต์นี้ | standalone runtime wrapper (ต้นฉบับที่ installer ก็อปไป) |
| `claude-9arm.sh` | `~/.claude-9arm/` | runtime wrapper (เขียนโดย installer) |
| `claude-9arm` | `~/.claude-9arm/bin/` | symlink ไปยัง wrapper สำหรับเรียก `claude-9arm` |
| `install-opencode-9arm-mac.sh` | โปรเจกต์นี้ | เชื่อม opencode เข้า gateway |
| `install-qwen-code-9arm-mac.sh` | โปรเจกต์นี้ | เชื่อม Qwen Code เข้า gateway |
| `install-openclaw-9arm-mac.sh` | โปรเจกต์นี้ | เชื่อม OpenClaw เข้า gateway |
| `install-hermes-9arm-mac.sh` | โปรเจกต์นี้ | เชื่อม Hermes เข้า gateway |
| `token` | `~/.claude-9arm/` | gateway token |
| `CLAUDE.md` | `~/.claude-9arm/` | (ถ้ามี) system prompt เพิ่มเติม |