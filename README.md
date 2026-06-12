# PSF Assistant

ระบบช่วยร่างเอกสาร Thailand Professional Standard Framework (Thailand-PSF) ด้วย Hermes Agent สำหรับใช้งานบนเครื่องกลางของภาควิชา รองรับ workflow เดิม ได้แก่ intake, mapping กับกรอบ THPSF, reflective writing, revision loop และ export เป็น DOCX/PDF

ระบบนี้ออกแบบให้ **อาจารย์แต่ละคนมี case แยกกัน** เพื่อไม่ให้ workspace, deliverables, session, memory และ Hermes state ปนกัน

## แนวคิดหลัก

```text
อาจารย์ 1 คน
→ case folder 1 folder
→ Hermes profile 1 profile
→ Docker sandbox 1 sandbox
```

ตัวอย่างการสร้าง case ที่ใช้งานได้:

```bash
psf-new siwachoat
psf-new PSF-2026-001
psf-new PSF-2026-001_somchai
```

ถ้าใส่แค่ชื่อ เช่น `psf-new siwachoat` ระบบจะหาเลขถัดไปของปีปัจจุบันให้อัตโนมัติ แล้วสร้าง folder ตามรูปแบบ:

```text
PSF-2026-001_siwachoat
```

ระบบจะอ่านเลข case หลักเป็น canonical case ID เสมอ:

```text
folder:  PSF-2026-001_somchai
case ID: PSF-2026-001
profile: psf-2026-001
```

ดังนั้นใส่ชื่ออาจารย์ต่อท้าย folder ได้เพื่อให้กลับมาทำงานต่อภายหลังง่ายขึ้น แต่ Hermes profile จะยังผูกกับเลข case หลักเพื่อแยก memory/session/state อย่างสม่ำเสมอ

## โครงสร้างไฟล์

หลังติดตั้ง ระบบจะใช้โครงสร้างนี้:

```text
~/Documents/psf-assistant/
├── cases/
│   └── PSF-2026-001_somchai/
│       ├── input/
│       │   ├── cv_background.md
│       │   ├── teaching_cases.md
│       │   └── papers/
│       ├── workspace/
│       └── deliverables/
└── private-admin/

~/.hermes/psf-shared/
├── assets/
│   ├── psf_template.docx
│   └── thai_pdf.tex
├── context/
│   ├── psf_guidelines.md
│   └── thpsf_framework.md
└── templates/
```

ความหมายของแต่ละ folder:

| Folder | ใช้ทำอะไร |
|---|---|
| `input/` | ข้อมูลต้นฉบับและหลักฐานที่อาจารย์ให้มา mount เข้า Docker แบบอ่านอย่างเดียว |
| `workspace/` | ไฟล์ร่าง Markdown, working copy, review report และไฟล์ระหว่างทำงาน |
| `deliverables/` | ไฟล์ DOCX/PDF ที่จะส่งมอบ |
| `private-admin/` | พื้นที่เก็บข้อมูลบริหารภายใน ไม่ mount เข้า sandbox |

## Requirements

- macOS หรือ Linux
- Git
- Hermes Agent
- Docker CLI และ Docker daemon ที่เปิดใช้งานอยู่
- Pandoc บน host สำหรับ compatibility
- API provider ที่ Hermes รองรับ เช่น OpenAI, Anthropic, OpenRouter หรือ provider อื่นที่ตั้งค่าไว้

Installer จะสร้าง Docker image ชื่อ `psf-assistant:local` ซึ่งมี Pandoc, XeLaTeX และ Thai fonts สำหรับ render DOCX/PDF ภายใน sandbox

## ติดตั้ง

```bash
curl -fsSL https://raw.githubusercontent.com/datakruroo/th_psf_assistant/main/install.sh | bash
```

สิ่งที่ installer ทำ:

- ตรวจหรือ install Hermes Agent
- ตรวจหรือ install Pandoc บน host
- ตรวจ Docker CLI และ Docker daemon
- สร้าง `~/Documents/psf-assistant/cases`
- สร้าง `~/Documents/psf-assistant/private-admin`
- ติดตั้ง shared assets/context ที่ `~/.hermes/psf-shared`
- สร้างหรือ configure Hermes profile template ชื่อ `psf-template`
- ติดตั้ง helper commands:
  - `psf-new`
  - `psf-open`
  - `psf-list`
  - `psf-close`
  - `psf-delete-profile`
- สร้าง Docker image `psf-assistant:local`

ถ้า Docker ยังไม่พร้อม installer จะหยุดและแจ้ง error ชัดเจน ไม่ fallback ไปใช้ local backend แบบเงียบ ๆ

## วิธีใช้งานจริง

### 1. สร้าง case folder

วิธีที่แนะนำสำหรับผู้ใช้ทั่วไปคือใส่แค่ชื่อหรือชื่อย่อ:

```bash
psf-new siwachoat
```

ระบบจะออกเลข case ถัดไปให้อัตโนมัติ เช่น:

```text
PSF-2026-001_siwachoat
```

ถ้าต้องการกำหนดเลขเองก็ยังทำได้:

```bash
psf-new PSF-2026-001
psf-new PSF-2026-001_somchai
```

ระบบจะสร้าง:

```text
~/Documents/psf-assistant/cases/PSF-2026-001_somchai/
├── input/
├── workspace/
└── deliverables/
```

และสร้าง Hermes profile:

```text
psf-2026-001
```

### 2. ใส่ข้อมูลอาจารย์

นำไฟล์ของอาจารย์ไปไว้ใน:

```text
~/Documents/psf-assistant/cases/PSF-2026-001_somchai/input/
```

ไฟล์หลัก:

```text
input/cv_background.md
input/teaching_cases.md
input/papers/
```

### 3. เปิด Hermes ของ case นั้น

เปิดด้วย folder name เต็ม:

```bash
psf-open PSF-2026-001_somchai
```

หรือเปิดด้วยเลข case หลักก็ได้ ถ้ามี folder เดียวที่ตรงกับ case นั้น:

```bash
psf-open PSF-2026-001
```

ห้ามใช้ plain `hermes` สำหรับงานหลายอาจารย์บนเครื่องกลาง เพราะอาจเปิด default profile และ local backend ทำให้ session/memory/state ปนกันได้

### 4. ใช้งาน workflow เดิม

ใน Hermes:

```text
/psf-writer
```

ถ้าต้องการตรวจ draft:

```text
/psf-reviewer
```

## Commands

| Command | หน้าที่ |
|---|---|
| `psf-new siwachoat` | สร้าง case folder โดยออกเลขถัดไปให้อัตโนมัติ เช่น `PSF-2026-001_siwachoat` |
| `psf-new PSF-2026-001_somchai` | สร้าง case folder ด้วยเลขที่กำหนดเอง, copy input templates, clone Hermes profile จาก `psf-template`, generate Docker config |
| `psf-open PSF-2026-001_somchai` | เปิด Hermes profile ของ case นั้น พร้อมตรวจ Docker |
| `psf-list` | แสดง case ID, folder name, สถานะ folder/profile, จำนวนไฟล์ input และ deliverables |
| `psf-close PSF-2026-001_somchai` | หยุด Docker sandbox ของ case นั้น ไม่ลบไฟล์ |
| `psf-delete-profile PSF-2026-001_somchai` | ลบ Hermes profile/session/memory/log ของ case นั้น แต่ไม่ลบ case folder |

ลบ profile แบบ automation:

```bash
psf-delete-profile --yes PSF-2026-001_somchai
```

## Path ภายใน Docker Sandbox

เมื่อ Hermes ทำงานใน Docker จะเห็น path แบบคงที่:

```text
/input/cv_background.md
/input/teaching_cases.md
/input/papers/

/workspace/PSF_part2.md
/workspace/PSF_part3.md
/workspace/PSF_review.md

/deliverables/PSF_Application.docx
/deliverables/PSF_Application.pdf

/assets/psf_template.docx
/assets/thai_pdf.tex

/psf-context/psf_guidelines.md
/psf-context/thpsf_framework.md
```

กติกาสำคัญ:

- `/input` อ่านได้อย่างเดียว
- ห้ามแก้ไฟล์ต้นฉบับใน `/input`
- ถ้าต้องบันทึกข้อมูลใหม่จากบทสนทนา ให้เขียนเป็น working copy ใน `/workspace`

ตัวอย่าง:

```text
/workspace/cv_background_working.md
/workspace/teaching_cases_working.md
```

ไฟล์ส่งมอบสุดท้ายต้องอยู่ใน:

```text
/deliverables/
```

## Rendering Strategy

โปรเจกต์นี้เลือกใช้ Docker image เฉพาะ `psf-assistant:local` สำหรับ render ด้วย Pandoc/XeLaTeX/Thai fonts

เหตุผล:

- environment สำหรับ render ซ้ำได้ง่าย
- ไม่ต้อง install dependency ระหว่างทำงานในแต่ละ case
- render อยู่ใน sandbox เดียวกับ case
- host helper ไม่ต้องมีสิทธิ์อ่าน path กว้างเกินจำเป็น

ข้อแลกเปลี่ยนคือการติดตั้งครั้งแรกจะใช้เวลามากขึ้นเพราะต้อง build Docker image

## ย้ายจาก workflow เดิม

workflow เดิม:

```text
หนึ่งอาจารย์
→ หนึ่ง working folder
→ เปิดด้วย plain hermes/default profile
```

วิธีย้าย:

1. รัน installer ใหม่
2. สร้าง case folder:

```bash
psf-new siwachoat
```

3. ย้ายไฟล์เดิมเข้า:

```text
cases/PSF-2026-001_siwachoat/input/
```

4. ถ้ามี draft เดิม ให้ย้ายเข้า:

```text
cases/PSF-2026-001_siwachoat/workspace/
```

5. เปิดใช้งาน:

```bash
psf-open PSF-2026-001_siwachoat
```

ไม่ควร copy Hermes memory/session เดิมเข้ามา เว้นแต่ตั้งใจจริงว่าต้องการใช้ประวัติเดิมต่อ

## ข้อควรระวัง

- Docker sandbox จำกัด filesystem ที่ Hermes มองเห็น แต่ไม่ได้กันคนที่ใช้ OS user เดียวกันจากการเปิด Finder/Terminal ไปดู folder อื่นเอง
- ถ้าต้องการกันผู้ใช้ระดับ OS จริง ควรใช้ user account แยก, file permission หรือ encryption เพิ่ม
- ถ้าใช้ API provider ภายนอก เนื้อหา prompt, draft และ evidence บางส่วนอาจถูกส่งออกจากเครื่องตาม policy ของ provider นั้น
- ชื่ออาจารย์ใน folder เช่น `PSF-2026-001_somchai` อาจปรากฏใน path, Docker mount config, command history หรือ logs
- ห้ามนำข้อมูลจริงไป commit เข้า Git repository

## Testing

รัน smoke tests:

```bash
tests/smoke.sh
```

ตรวจ shell syntax:

```bash
bash -n install.sh bin/psf-* lib/psf-lib.sh tests/smoke.sh
```

ถ้ามี `shellcheck`:

```bash
shellcheck install.sh bin/psf-* lib/psf-lib.sh tests/smoke.sh
```

## Repository Layout

```text
th_psf_assistant/
├── bin/
│   ├── psf-new
│   ├── psf-open
│   ├── psf-list
│   ├── psf-close
│   └── psf-delete-profile
├── lib/
│   └── psf-lib.sh
├── docker/
│   └── Dockerfile
├── install.sh
├── AGENTS.md
├── soul_template.md
├── context/
├── skills/
├── pandoc/
└── tests/
```

## ยังไม่ทำในรอบนี้

- web application
- database server
- authentication หลาย user
- cloud deployment
- Telegram bot
- upload ผ่าน browser
- encryption เต็มรูปแบบ
- auto-delete หลักฐาน
- case registry ที่เก็บชื่อจริง
