# 🎓 PSF Assistant

ระบบช่วยเขียนงานงี่เง่า **Thailand Professional Standard Framework (Thailand-PSF)** สำหรับอาจารย์มหาวิทยาลัย ขับเคลื่อนด้วย [Hermes Agent](https://hermes-agent.nousresearch.com) รองรับ OpenAI / Anthropic (Claude) / OpenRouter

---

## ระบบทำอะไร

Thailand-PSF ไม่ใช่ CV — เป็นเอกสาร **reflective writing** ที่แสดงให้เห็นว่าอาจารย์มีสมรรถนะตามกรอบ THPSF (ร/ส/ค) จริงผ่านหลักฐานเชิงประจักษ์

ระบบนี้ทำหน้าที่:
1. **เก็บข้อมูล** — ถามอาจารย์ทีละกลุ่มจนครบ (ข้อมูลส่วนตัว, ประวัติการศึกษา, ภาระงานสอน, กรณีศึกษา 2 กรณี)
2. **วิเคราะห์** — mapping ข้อมูลกับ dimension ร/ส/ค และหลักการทางการศึกษา
3. **เขียน** — ร่าง reflective writing แบบ What–So What–Now What ทีละส่วน
4. **แก้ไข** — รับ comment แล้ว revise เป็น loop จนอาจารย์พอใจ
5. **Export** — แปลงเป็น `.docx` และ `.pdf` พร้อม format ที่ถูกต้อง

---

## ความต้องการของระบบ

| รายการ | macOS | Linux (Ubuntu) | Windows |
|--------|-------|----------------|---------|
| Terminal | ✅ built-in | ✅ built-in | ✅ WSL2 |
| Git | ✅ | ✅ | ✅ WSL2 |
| Homebrew | ✅ ต้องใช้ | — | — |
| API Key | OpenAI / Anthropic / OpenRouter | | |

> **Windows:** ต้องติดตั้ง [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) ก่อน แล้วรันคำสั่งทั้งหมดใน WSL2 terminal

---

## ติดตั้ง

รันคำสั่งเดียวใน terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/datakruroo/th_psf_assistant/main/install.sh | bash
```

script จะดำเนินการให้อัตโนมัติ:
1. ดาวน์โหลด Hermes Agent
2. ติดตั้ง Pandoc (สำหรับแปลงเป็น DOCX/PDF)
3. ติดตั้ง PSF skill และ template ไว้ใน `~/.hermes/`
4. สร้าง `psf-new` command
5. ขอให้ตั้งค่า API key

---

## วิธีใช้งาน

### ครั้งแรก (หลังติดตั้ง)

```bash
# 1. สร้าง folder สำหรับเขียน PSF ของคุณ
psf-new ชื่อ-folder
# ตัวอย่าง: psf-new psf-somchai-2568

# 2. เข้าไปใน folder
cd ชื่อ-folder
```

folder จะมีแค่สองไฟล์ที่ต้องกรอก:

```
ชื่อ-folder/
├── cv_background.md     ← ข้อมูลส่วนตัวและประวัติ
├── teaching_cases.md    ← ข้อมูลการสอนและกรณีศึกษา
└── papers/              ← วางเอกสารประกอบ (ถ้ามี)
```

### เริ่มเขียน PSF

```bash
# 3. เปิด Hermes
hermes

# 4. เรียกระบบ PSF
/psf-writer
```

ระบบจะเริ่มถามข้อมูลทีละกลุ่ม — ตอบในแชทได้เลย ไม่ต้องกรอกไฟล์เอง

---

## Flow การทำงาน

```
/psf-writer
    │
    ▼
[Intake] ถามข้อมูล 5 กลุ่ม
    ├── กลุ่ม 1: ข้อมูลส่วนตัว
    ├── กลุ่ม 2: ประวัติการศึกษา + ภาระงานสอน 3 ปี
    ├── กลุ่ม 3: กรณีศึกษาที่ 1 (4 ด้าน)
    ├── กลุ่ม 4: กรณีศึกษาที่ 2 (4 ด้าน)
    └── กลุ่ม 5: การพัฒนาวิชาชีพ
    │
    ▼
[วิเคราะห์] mapping dimension ร/ส/ค → แสดงให้ยืนยัน
    │
    ▼
[เขียน] ร่าง Part 2 + Part 3 ทีละส่วน → render → รอ approve
    │
    ▼
[Revision Loop] รับ comment → แก้เฉพาะจุด → re-render → วนซ้ำ
    │
    ▼
[Export] PSF_Application.docx + PSF_Application.pdf
```

**ข้อมูล 4 ด้านในแต่ละกรณีศึกษา:**
- ด้านที่ 1: การออกแบบรายวิชา
- ด้านที่ 2: การจัดการเรียนรู้
- ด้านที่ 3: การวัดและประเมินผล
- ด้านที่ 4: การพัฒนาและปรับปรุง

---

## Output ที่ได้

| ไฟล์ | ใช้สำหรับ |
|------|----------|
| `cv_background.md` | ต้นฉบับข้อมูลส่วนตัว แก้ไขได้ |
| `teaching_cases.md` | ต้นฉบับกรณีศึกษา แก้ไขได้ |
| `PSF_part2.md` | ร่างส่วนที่ 2 แก้ไขได้ |
| `PSF_part3.md` | ร่างส่วนที่ 3 แก้ไขได้ |
| `PSF_Application.docx` | ไฟล์ Word สำหรับตรวจสอบ |
| `PSF_Application.pdf` | ไฟล์ PDF สำหรับ submit |

---

## คำถามที่พบบ่อย

**ต้องกรอก `cv_background.md` และ `teaching_cases.md` เองมั้ย?**
ไม่จำเป็น — พิมพ์ข้อมูลในแชทกับ Hermes ได้เลย ระบบจะบันทึกไฟล์ให้เอง แต่ถ้ามีข้อมูลอยู่แล้วก็วางใส่ไฟล์ได้เลย ระบบจะอ่านและข้ามขั้นตอน intake

**PSF ระดับไหนบ้างที่รองรับ?**
รองรับระดับ 1–4 ระบบจะปรับความละเอียดและ dimension ที่เน้นให้ตรงกับระดับที่เลือก

**ใช้กับ model ไหนได้บ้าง?**
รองรับทุก provider ที่ Hermes รองรับ: OpenAI (gpt-4o, gpt-4.1), Anthropic (Claude), OpenRouter แนะนำ model ที่มี context window ≥ 128K token เพราะ PSF session มีเนื้อหายาว

**เขียนเสร็จแล้วอยากแก้ไขทีหลังได้มั้ย?**
ได้ — เปิด Hermes ใน folder เดิม แล้วระบุว่าอยากแก้ไขส่วนไหน ระบบจะแก้เฉพาะจุดที่ระบุโดยไม่แตะส่วนอื่น

---

## โครงสร้าง Repository

```
th_psf_assistant/
├── install.sh                     ← script ติดตั้ง
├── AGENTS.md                      ← context หลักสำหรับ Hermes
├── soul_template.md               ← บุคลิกของ agent
├── context/
│   ├── psf_guidelines.md          ← ข้อกำหนดและเกณฑ์ PSF
│   └── thpsf_framework.md         ← ตาราง dimension ร/ส/ค ทั้งหมด
├── skills/psf-writer/
│   ├── SKILL.md                   ← Hermes skill (intake + writing flow)
│   └── PSF_structure.md           ← โครงสร้างเอกสาร 5 ส่วน
├── pandoc/
│   ├── psf_template.docx          ← Word template
│   └── thai_pdf.tex               ← LaTeX header สำหรับ Thai PDF
└── tests/sample_input/
    └── teaching_cases.md          ← template กรอกข้อมูล
```

---

## License

This project is available for non-commercial use only under the PolyForm Noncommercial License 1.0.0￼.

You may use, modify, and distribute this project for personal, educational, and research purposes.
Commercial use, including use in paid services, products, consulting work, or other revenue-generating activities, is not permitted without prior written permission from the author.

For commial licensing inquiries, please contact the author.



MIT
