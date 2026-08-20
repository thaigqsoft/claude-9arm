# claude-9arm — Windows PowerShell wrapper

ตัวห่อ (wrapper) สำหรับเรียก Claude Code ผ่าน gateway `https://gateway.9arm.co` บน Windows
พอร์ตมาจากเวอร์ชัน Linux (bash) — ใช้ model เดียวกันและแยก profile/config แยกเป็นของตัวเอง

---

## ความต้องการของระบบ (Requirements)

- **Windows 10 / 11**
- **Node.js LTS** (มาพร้อม `npm`) — ถ้ายังไม่มี ระหว่าง setup จะมีคำแนะนำให้ติดตั้ง
- อินเทอร์เน็ต (สำหรับติดตั้ง Claude Code ผ่าน npm และคุยกับ gateway)

---

## 1) ติดตั้ง Installer

รันสคริปต์ `install-claude-9arm.ps1` หนึ่งครั้งด้วยวิธีใดวิธีหนึ่ง:

### วิธี A — ผ่าน command line (แนะนำ)
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-claude-9arm.ps1
```

### วิธี B — คลิกขวา
คลิกขวาที่ `install-claude-9arm.ps1` → **Run with PowerShell**
(ถ้าโดน Execution Policy บล็อก ให้ใช้วิธี A)

สิ่งที่สคริปต์ทำ:
1. ตรวจว่า `node` + `npm` มีหรือไม่ (ถ้าไม่มี จะบอกวิธีติดตั้ง Node.js LTS และจบการทำงาน — ไม่ติดตั้งเงียบๆ)
2. ถ้ายังไม่มี `claude` จะติดตั้ง Claude Code ผ่าน npm (`@anthropic-ai/claude-code`)
3. สร้างโฟลเดอร์ `%USERPROFILE%\.claude-9arm`
4. ให้กรอก **gateway token** (เก็บไว้ใน `%USERPROFILE%\.claude-9arm\token`)
5. เขียน wrapper `claude-9arm.ps1` + shim `claude-9arm.cmd`
6. พิมพ์คำสั่งเพิ่ม PATH และสรุปการใช้งาน

---

## 2) Token มาจากไหน

Token เป็นค่าที่ **เจ้าของ (owner) เป็นผู้ออกให้** — เป็นหัวข้อเดียวกับที่ใช้กับ gateway `9arm`

- เก็บไว้ที่: `%USERPROFILE%\.claude-9arm\token`
- ห้ามแชร์ token นี้ให้ใคร
- อยากรีเซ็ต token → รัน installer อีกครั้งด้วย `-PromptToken`

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-claude-9arm.ps1 -PromptToken
```

---

## 3) เพิ่ม bin เข้า PATH

เพื่อให้พิมพ์ `claude-9arm` ได้จากที่ไหนก็ได้ ให้รันคำสั่งนี้ (ใช้กับ terminal ใหม่เท่านั้น):

```bat
setx PATH "%PATH%;%USERPROFILE%\.claude-9arm\bin"
```

แล้ว **เปิด terminal (PowerShell) ใหม่** — window ที่เปิดอยู่ในขณะนั้นจะยังใช้ PATH เก่า

---

## 4) วิธีใช้งาน

```powershell
claude-9arm "คำถามของคุณ"
```

ตัวอย่าง:
```powershell
claude-9arm "สรุปให้ฟังว่าวันนี้ต้องทำอะไรบ้าง"
claude-9arm "เขียนโปรแกรม Python คิดเลขง่ายๆ ให้หน่อย"
```

ทดสอบว่าต่อ gateway สำเร็จ (health check):
```powershell
claude-9arm -HealthCheck
```
จะถาม Claude ว่า `What is 1+1?` และถ้าไม่ได้คำตอบที่มีเลข `2` จะรายงานว่าล้มเหลว

> หมายเหตุ: health check ถูกปิดเป็นค่าเริ่มต้นเพื่อประหยัด token ของเพื่อน — จะรันก็ต่อเมื่อส่ง `-HealthCheck`.

---

## 5) Troubleshooting

| อาการ | สาเหตุ / วิธีแก้ |
|---|---|
| `ไม่พบ token file` | ยังไม่ได้กรอก token — รัน installer อีกครั้งให้ครบ |
| `not recognized... ไม่ใช่คำสั่งภายในหรือภายนอก` | ยังไม่ได้เพิ่ม bin เข้า PATH หรือยังไม่เปิด terminal ใหม่ — ดูข้อ 3 |
| `ไม่สามารถโหลดไฟล์... ไม่อนุญาตให้เรียกใช้สคริปต์...` | ExecutionPolicy — ใช้วิธี A (`-ExecutionPolicy Bypass -File`) |
| `npm install ล้มเหลว / network error` | ตรวจอินเทอร์เน็ต / proxy แล้วลองใหม่; ถ้าติดตั้ง node ใหม่ให้เปิด terminal ใหม่ |
| `ไม่พบคำสั่ง claude` | ติดตั้ง Claude Code ไม่สำเร็จ — รัน installer อีกครั้ง (หรือ `npm install -g @anthropic-ai/claude-code` เอง) |
| health check FAILED | gateway ตาย / token ผิด / ยังไม่ได้เพิ่ม PATH — ลองใหม่ หรือติดต่อเจ้าของเรื่อง token |

---

## ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | ตำแหน่ง | หน้าที่ |
|---|---|---|
| `install-claude-9arm.ps1` | โปรเจกต์นี้ | ติดตั้งครั้งเดียว (idempotent) |
| `claude-9arm.ps1` | `%USERPROFILE%\.claude-9arm\` | runtime wrapper (เขียนโดย installer) |
| `claude-9arm.cmd` | `%USERPROFILE%\.claude-9arm\bin\` | shim สำหรับเรียก `claude-9arm` |
| `token` | `%USERPROFILE%\.claude-9arm\` | gateway token |
| `CLAUDE.md` | `%USERPROFILE%\.claude-9arm\` | (ถ้ามี) system prompt เพิ่มเติม |