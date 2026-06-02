#!/usr/bin/env bash
# =============================================================================
# PSF Assistant — install.sh
# ติดตั้ง Hermes Agent + PSF Writing System บน macOS / Ubuntu
# =============================================================================

set -euo pipefail

# --- สี ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }
err()  { echo -e "${RED}✗ $*${NC}"; exit 1; }
info() { echo -e "  $*"; }

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
REPO_URL="https://github.com/datakruroo/th_psf_assistant.git"

# --- ถ้ารันผ่าน curl | bash จะไม่มี BASH_SOURCE ให้ clone repo ก่อน ---
if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]}" != "bash" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # รันผ่าน curl | bash — clone repo ลงใน temp folder
    TMP_REPO="$(mktemp -d)"
    info "กำลังดาวน์โหลดไฟล์ระบบ..."
    git clone --depth 1 "$REPO_URL" "$TMP_REPO" 2>/dev/null || \
        err "ดาวน์โหลดไม่สำเร็จ — กรุณาตรวจสอบ internet connection"
    SCRIPT_DIR="$TMP_REPO"
    ok "ดาวน์โหลดเสร็จแล้ว"
fi

# =============================================================================
echo ""
echo -e "${BOLD}🎓 PSF Assistant — ระบบช่วยเขียน Thailand-PSF${NC}"
echo "================================================="
echo ""

# =============================================================================
# 1. ติดตั้ง Hermes Agent
# =============================================================================
echo -e "${BOLD}[1/5] Hermes Agent${NC}"

if hermes --version &>/dev/null; then
    ok "Hermes Agent พร้อมใช้งานแล้ว ($(hermes --version 2>/dev/null))"
else
    info "กำลังติดตั้ง Hermes Agent..."
    curl -fsSL \
      https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh \
      | bash
    export PATH="$HOME/.local/bin:$PATH"
    hermes --version &>/dev/null || err "ติดตั้ง Hermes ไม่สำเร็จ — กรุณาตรวจสอบ internet connection"
    ok "ติดตั้ง Hermes Agent เสร็จแล้ว"
fi

# =============================================================================
# 2. ติดตั้ง Pandoc (สำหรับ render DOCX)
# =============================================================================
echo ""
echo -e "${BOLD}[2/5] Pandoc${NC}"

if command -v pandoc &>/dev/null; then
    ok "Pandoc พร้อมใช้งานแล้ว ($(pandoc --version | head -1))"
else
    info "กำลังติดตั้ง Pandoc..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &>/dev/null; then
            brew install pandoc
        else
            err "ต้องการ Homebrew ก่อน — ติดตั้งได้ที่ https://brew.sh แล้วรัน install.sh ใหม่"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update -qq && sudo apt-get install -y pandoc
    else
        warn "OS ไม่รู้จัก — กรุณาติดตั้ง Pandoc เอง: https://pandoc.org/installing.html"
    fi
    ok "ติดตั้ง Pandoc เสร็จแล้ว"
fi

# =============================================================================
# 3. ติดตั้ง PSF Skill → ~/.hermes/skills/psf-writer/
# =============================================================================
echo ""
echo -e "${BOLD}[3/5] PSF Skill${NC}"

SKILLS_DIR="$HERMES_HOME/skills/psf-writer"
mkdir -p "$SKILLS_DIR"
cp -r "$SCRIPT_DIR/skills/psf-writer/." "$SKILLS_DIR/"
ok "psf-writer skill → $SKILLS_DIR"

REVISER_DIR="$HERMES_HOME/skills/psf-reviser"
mkdir -p "$REVISER_DIR"
cp -r "$SCRIPT_DIR/skills/psf-reviser/." "$REVISER_DIR/"
ok "psf-reviser skill → $REVISER_DIR"

# =============================================================================
# 4. ติดตั้ง Pandoc assets → ~/.hermes/
# =============================================================================
echo ""
echo -e "${BOLD}[4/5] Pandoc Template${NC}"

cp "$SCRIPT_DIR/pandoc/psf_template.docx" "$HERMES_HOME/psf_template.docx"
ok "psf_template.docx → $HERMES_HOME/"

cp "$SCRIPT_DIR/pandoc/thai_pdf.tex" "$HERMES_HOME/thai_pdf.tex"
ok "thai_pdf.tex → $HERMES_HOME/"

# =============================================================================
# 5. ติดตั้ง SOUL.md (บุคลิกของ Hermes)
# =============================================================================
echo ""
echo -e "${BOLD}[5/5] SOUL.md${NC}"

if [ -f "$HERMES_HOME/SOUL.md" ] && [ -s "$HERMES_HOME/SOUL.md" ]; then
    warn "พบ SOUL.md อยู่แล้ว — ข้ามเพื่อไม่ให้ทับค่าที่ตั้งไว้"
else
    cp "$SCRIPT_DIR/soul_template.md" "$HERMES_HOME/SOUL.md"
    ok "SOUL.md → $HERMES_HOME/"
fi

# =============================================================================
# =============================================================================
# copy AGENTS.md และ context/ ไปไว้ใน ~/.hermes/ (ผู้ใช้ไม่เห็น)
# =============================================================================
cp "$SCRIPT_DIR/AGENTS.md" "$HERMES_HOME/AGENTS.md"
ok "AGENTS.md → $HERMES_HOME/"

mkdir -p "$HERMES_HOME/context"
cp -r "$SCRIPT_DIR/context/." "$HERMES_HOME/context/"
ok "context/ → $HERMES_HOME/context/"

# =============================================================================
# สร้าง psf-new helper — ใช้ตอนอาจารย์ต้องการเริ่ม PSF ใหม่
# =============================================================================
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# template files สำหรับ input ของอาจารย์
PSF_TEMPLATES="$HERMES_HOME/templates"
mkdir -p "$PSF_TEMPLATES"
cp "$SCRIPT_DIR/tests/sample_input/teaching_cases.md" "$PSF_TEMPLATES/teaching_cases.md"

cat > "$PSF_TEMPLATES/cv_background.md" << 'TMPL'
# ข้อมูลส่วนตัวและประวัติ

## ข้อมูลส่วนตัว
- ชื่อ-สกุล:
- ตำแหน่ง:
- คณะ/สาขา:
- สถาบัน:
- ระดับที่ยื่น PSF:

## ประวัติการศึกษา
<!-- ระบุวุฒิทุกระดับ: สาขา มหาวิทยาลัย ปีสำเร็จ -->

## ประสบการณ์การสอน (สรุป)
<!-- จำนวนปี วิชาหลักที่สอน ระดับที่สอน -->

## ผลงานทางวิชาการ / งานวิจัย (ถ้ามี)
<!-- ชื่อผลงาน ปีที่เผยแพร่ -->
TMPL

ok "templates → $PSF_TEMPLATES/"

cat > "$BIN_DIR/psf-new" << HEREDOC
#!/usr/bin/env bash
# สร้าง PSF working folder พร้อมไฟล์ input
set -e
FOLDER="\${1:-my-psf}"
if [ -d "\$FOLDER" ]; then
    echo "⚠ folder '\$FOLDER' มีอยู่แล้ว — กรุณาใช้ชื่ออื่น หรือระบุชื่อใหม่: psf-new ชื่อ-folder"
    exit 1
fi
mkdir -p "\$FOLDER/papers"
cp "$PSF_TEMPLATES/cv_background.md" "\$FOLDER/"
cp "$PSF_TEMPLATES/teaching_cases.md" "\$FOLDER/"
cp "$HERMES_HOME/AGENTS.md" "\$FOLDER/"
echo "✓ สร้าง folder '\$FOLDER' พร้อมใช้งาน"
echo ""
echo "ขั้นตอนต่อไป:"
echo "  1. cd \$FOLDER"
echo "  2. กรอกข้อมูลใน cv_background.md และ teaching_cases.md"
echo "  3. hermes"
echo "  4. พิมพ์: /psf-writer"
HEREDOC

chmod +x "$BIN_DIR/psf-new"
ok "psf-new helper → $BIN_DIR/psf-new"

# เพิ่ม ~/.local/bin ใน PATH ถ้ายังไม่มี
SHELL_RC=""
if [[ "${SHELL:-}" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "${SHELL:-}" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ] && ! grep -q '\.local/bin' "$SHELL_RC" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    info "เพิ่ม ~/.local/bin ใน $SHELL_RC"
fi

# =============================================================================
# ตั้งค่า Hermes (API key)
# =============================================================================
echo ""
echo "================================================="
echo -e "${BOLD}ตั้งค่า API Provider${NC}"
echo ""
info "รองรับ: OpenAI / Anthropic (Claude) / OpenRouter"
info "กรุณาเลือก provider และใส่ API key ในขั้นตอนต่อไป"
echo ""
hermes setup

# =============================================================================
# เสร็จสิ้น
# =============================================================================
echo ""
echo "================================================="
echo -e "${BOLD}${GREEN}✅ ติดตั้งเสร็จแล้ว!${NC}"
echo ""
echo -e "${BOLD}วิธีเริ่มใช้งาน:${NC}"
echo ""
echo "  1. สร้าง folder สำหรับ PSF ของคุณ:"
echo -e "     ${BOLD}psf-new ชื่อ-folder${NC}   (เช่น psf-new psf-siwachoat)"
echo ""
echo "  2. เข้าไปใน folder:"
echo -e "     ${BOLD}cd ชื่อ-folder${NC}"
echo ""
echo "  3. เริ่มระบบ:"
echo -e "     ${BOLD}hermes${NC}"
echo ""
echo "  4. พิมพ์:"
echo -e "     ${BOLD}/psf-writer${NC}"
echo ""
echo "  ระบบจะแนะนำทุกขั้นตอนเองครับ"
echo "================================================="
echo ""
