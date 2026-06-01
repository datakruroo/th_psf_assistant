# PSF Assistant — Developer Context

คุณกำลังช่วยพัฒนาระบบ PSF Assistant สำหรับอาจารย์คณะครุศาสตร์
ระบบ deploy ผ่าน Hermes Agent (NousResearch) บนเครื่องส่วนตัวของอาจารย์
ใช้ Markdown เป็น source of truth และ Pandoc แปลงเป็น DOCX และ PDF

> หมายเหตุ: ไฟล์นี้เป็น developer context — Hermes จะไม่โหลดเพราะ AGENTS.md มี priority สูงกว่า

## บทบาทของคุณ

คุณเป็น developer ที่สร้าง infrastructure ให้ Hermes agent ทำหน้าที่เขียน PSF
แยกให้ชัดเสมอว่ากำลังสร้าง "ระบบ" หรือ "เนื้อหา PSF"

## โครงสร้าง Project (ปัจจุบัน)

```
project_02_psf/
├── AGENTS.md              ← context หลักสำหรับ Hermes (โหลด auto)
├── CLAUDE.md              ← developer context (ไฟล์นี้)
├── install.sh             ← [TODO] script ติดตั้ง Hermes + setup
├── soul_template.md       ← template บุคลิก → install.sh copy ไป ~/.hermes/SOUL.md
├── pandoc/
│   ├── psf_template.docx  ← template Word (สร้างแล้ว)
│   └── thai_pdf.tex       ← LaTeX header สำหรับ PDF ภาษาไทย
├── skills/
│   └── psf-writer/
│       ├── SKILL.md       ← Hermes skill (มี YAML frontmatter แล้ว)
│       └── PSF_structure.md
├── context/
│   ├── psf_guidelines.md
│   └── thpsf_framework.md
├── tests/
│   └── sample_input/
│       └── teaching_cases.md
└── references/            ← PDF ต้นแบบจาก ควอท (อ่านอย่างเดียว)
```

## Hermes Architecture

```
install.sh ทำ:
  1. curl ติดตั้ง Hermes Agent
  2. copy skills/psf-writer/ → ~/.hermes/skills/psf-writer/
  3. copy pandoc/psf_template.docx → ~/.hermes/psf_template.docx
  4. copy pandoc/thai_pdf.tex → ~/.hermes/thai_pdf.tex
  5. copy soul_template.md → ~/.hermes/SOUL.md
  6. hermes setup (เลือก provider: OpenAI / Anthropic / OpenRouter)

อาจารย์ทำ:
  1. สร้าง working folder ใหม่
  2. copy AGENTS.md + context/ เข้า folder
  3. ใส่ cv_background.md และ teaching_cases.md
  4. รัน hermes จาก folder นั้น → พิมพ์ /psf-writer
```

## Render Pipeline

อาจารย์ input → Hermes แก้ไข PSF_part2.md + PSF_part3.md → pandoc → PSF.docx + PSF.pdf

คำสั่ง pandoc มาตรฐาน:
```bash
pandoc PSF_part2.md PSF_part3.md -o PSF_Application.docx \
  --reference-doc=$HOME/.hermes/psf_template.docx

pandoc PSF_part2.md PSF_part3.md -o PSF_Application.pdf \
  --pdf-engine=xelatex \
  --include-in-header=$HOME/.hermes/thai_pdf.tex
```

## กฎสำคัญ

- AGENTS.md และ SKILL.md เขียนเป็นคำสั่งให้ Hermes อ่าน ใช้ภาษาคำสั่ง กระชับ
- ทุก shell command ใน install.sh ต้องใช้ได้บน macOS และ Ubuntu
- การแปลง MD → PDF ต้องรองรับ Thai font ถ้ายังทดสอบไม่ได้ให้ระบุ TODO
- ห้าม hardcode path ใช้ $HOME และ relative path เสมอ

## สิ่งที่ยังไม่ต้องทำ (Phase 2)

- Multi-user หรือ server deployment
- Web interface
- Auto-update mechanism
- Integration กับระบบฐานข้อมูลของมหาวิทยาลัย
