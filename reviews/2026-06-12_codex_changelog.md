# Codex changelog — 2026-06-12

## ไฟล์ที่แตะ

- `tests/sample_input/teaching_cases.md`
- `skills/psf-writer/SKILL.md`
- `skills/psf-writer/PSF_structure.md`
- `context/psf_guidelines.md`
- `context/style_guide.md`
- `AGENTS.md`
- `pandoc/psf_template.docx`
- `pandoc/thai_pdf.tex`
- `scripts/count_thai_words.py`
- `docker/Dockerfile`
- `install.sh`
- `.gitignore`

## สิ่งที่แก้

- ขยาย intake template ให้รองรับ CLO, สถิติผลการเรียน, คะแนนประเมินรายวิชา, ผลงานผู้เรียนพร้อมสถานะเผยแพร่, บทบาทระดับหลักสูตร/องค์กร, เส้นทางอาชีพ, รางวัล/จรรยาบรรณ และการดูแลผู้เรียน
- เพิ่มขั้นเลือก theme ก่อนเขียน Part 3 โดยเสนอ 2-3 ทางเลือกพร้อมข้อดีข้อเสีย และให้อาจารย์เป็นผู้เลือก
- เพิ่มกฎ micro-loop ส 2.4 ต่อกิจกรรมการเรียนรู้ และกำหนดให้ทุก section ตาม CLO ปิดท้ายด้วยหลักฐานว่าผู้เรียนบรรลุ CLO ใด
- เพิ่มส่วนประมวลประสบการณ์การสอนท้ายกรณีศึกษา ก่อนส่วนค่านิยม ค
- เปลี่ยน default การกำกับรหัส ร/ส/ค เป็น 2 ระดับ เช่น (ส 2.4) และอนุญาต 3 ระดับเฉพาะเมื่ออาจารย์ต้องการ
- เพิ่มกฎ PDPA ไม่เอ่ยชื่อนิสิตจริงโดย default เว้นแต่เป็นข้อมูลเผยแพร่สาธารณะ
- ปรับย่อหน้าเปิด Part 3 ให้เลือกได้ระหว่างแบบกระชับและแบบ narrative
- เพิ่ม style guide ภาษาไทยวิชาการพร้อมตัวอย่างสมมุติที่แสดง micro-loop ส 2.4
- เพิ่มสคริปต์ `scripts/count_thai_words.py` สำหรับนับคำภาษาไทยด้วย PyThaiNLP และผูกเข้ากับ workflow export
- แก้ `pandoc/psf_template.docx` ให้มี line numbering ใน DOCX โดย restart ทุกหน้า
- เพิ่ม TODO ใน `pandoc/thai_pdf.tex` ว่ายังไม่ได้ทำ line numbering ฝั่ง PDF
- เพิ่ม PyThaiNLP ใน Docker image และให้ installer copy สคริปต์นับคำเข้า shared assets

## การตัดสินใจที่ทำเอง

- ใช้ `style_guide.md` เป็น context แยกแทนการยัดกฎภาษาทั้งหมดเข้า `SKILL.md` เพื่อให้คำสั่ง Hermes กระชับตามข้อจำกัดใน `CLAUDE.md`
- วาง `count_thai_words.py` ไว้ใน `/assets/scripts/` ภายใน sandbox เพราะ `/assets` เป็น shared read-only mount ที่ทุก case ใช้ร่วมกันได้
- ตรวจ line numbering ของ DOCX ด้วย OOXML และ pandoc render output เพราะเครื่องนี้ไม่มี LibreOffice สำหรับ render PNG visual QA

## สิ่งที่ทำไม่ได้/ติดปัญหา

- ยังไม่ได้ทำ line numbering ฝั่ง PDF ตาม scope ที่กำหนดไว้ จึงใส่ TODO ใน `pandoc/thai_pdf.tex`
- ไม่สามารถตรวจภาพหน้า DOCX ด้วย `render_docx.py` ได้ เพราะเครื่องนี้ไม่มี `soffice`/LibreOffice
- ไม่ได้แก้ `references/` ตามข้อห้ามใน `CLAUDE.md`
