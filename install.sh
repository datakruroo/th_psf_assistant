#!/usr/bin/env bash
# =============================================================================
# PSF Assistant — multi-case installer
# Installs Hermes Agent, PSF skills/assets, helper commands, and a Docker
# sandbox image for Thailand-PSF case work on macOS / Linux.
# =============================================================================

set -Eeuo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
err()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }
info() { printf '  %s\n' "$*"; }

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
PSF_ROOT="${PSF_ROOT:-$HOME/Documents/psf-assistant}"
PSF_SHARED="${PSF_SHARED:-$HERMES_HOME/psf-shared}"
PSF_TEMPLATE_PROFILE="${PSF_TEMPLATE_PROFILE:-psf-template}"
PSF_DOCKER_IMAGE="${PSF_DOCKER_IMAGE:-psf-assistant:local}"
REPO_URL="https://github.com/datakruroo/th_psf_assistant.git"

if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]}" != "bash" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    TMP_REPO="$(mktemp -d)"
    info "Downloading PSF Assistant..."
    git clone --depth 1 "$REPO_URL" "$TMP_REPO" 2>/dev/null || \
        err "Download failed. Check your internet connection."
    SCRIPT_DIR="$TMP_REPO"
    ok "Downloaded"
fi

echo ""
echo -e "${BOLD}PSF Assistant — Thailand-PSF multi-case mode${NC}"
echo "================================================="

echo ""
echo -e "${BOLD}[1/8] Hermes Agent${NC}"
if hermes --version >/dev/null 2>&1; then
    ok "Hermes Agent is installed ($(hermes --version 2>/dev/null | head -1))"
else
    info "Installing Hermes Agent..."
    curl -fsSL \
      https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh \
      | bash
    export PATH="$HOME/.local/bin:$PATH"
    hermes --version >/dev/null 2>&1 || err "Hermes installation failed"
    ok "Hermes Agent installed"
fi

echo ""
echo -e "${BOLD}[2/8] Pandoc on host${NC}"
if command -v pandoc >/dev/null 2>&1; then
    ok "Pandoc is installed ($(pandoc --version | head -1))"
else
    info "Installing Pandoc for host-side compatibility..."
    if [[ "${OSTYPE:-}" == darwin* ]]; then
        command -v brew >/dev/null 2>&1 || err "Homebrew is required on macOS: https://brew.sh"
        brew install pandoc
    elif [[ "${OSTYPE:-}" == linux-gnu* ]]; then
        sudo apt-get update -qq
        sudo apt-get install -y pandoc
    else
        warn "Unknown OS. Install Pandoc manually if host-side rendering is needed."
    fi
    ok "Pandoc step complete"
fi

echo ""
echo -e "${BOLD}[3/8] Docker${NC}"
command -v docker >/dev/null 2>&1 || err "Docker CLI is required. Install Docker Desktop on macOS or Docker Engine on Linux."
if ! docker info >/dev/null 2>&1; then
    err "Docker daemon is not reachable. Start Docker Desktop on macOS, or start the Docker service on Linux, then rerun install.sh."
fi
ok "Docker daemon is reachable"

if [ "${PSF_INSTALL_SKIP_DOCKER_BUILD:-0}" = "1" ]; then
    warn "Skipping Docker image build because PSF_INSTALL_SKIP_DOCKER_BUILD=1"
elif docker image inspect "$PSF_DOCKER_IMAGE" >/dev/null 2>&1; then
    ok "Docker image already exists: $PSF_DOCKER_IMAGE"
else
    info "Building Docker image with Pandoc, XeLaTeX, and Thai fonts: $PSF_DOCKER_IMAGE"
    docker build -t "$PSF_DOCKER_IMAGE" "$SCRIPT_DIR/docker"
    ok "Docker image built"
fi

echo ""
echo -e "${BOLD}[4/8] Directories${NC}"
mkdir -p \
    "$PSF_ROOT/cases" \
    "$PSF_ROOT/private-admin" \
    "$PSF_SHARED/assets" \
    "$PSF_SHARED/context" \
    "$PSF_SHARED/templates" \
    "$HERMES_HOME/skills"
ok "Cases root: $PSF_ROOT/cases"
ok "Private admin root: $PSF_ROOT/private-admin"
ok "Shared PSF root: $PSF_SHARED"

if [ -f "$PSF_ROOT/.gitignore" ]; then
    touch "$PSF_ROOT/.gitignore"
else
    cat > "$PSF_ROOT/.gitignore" <<'EOF'
cases/
private-admin/
.env
*.log
.DS_Store
EOF
fi
for pattern in "cases/" "private-admin/" ".env" "*.log" ".DS_Store"; do
    grep -qxF "$pattern" "$PSF_ROOT/.gitignore" 2>/dev/null || printf '%s\n' "$pattern" >> "$PSF_ROOT/.gitignore"
done
ok "Runtime .gitignore configured"

echo ""
echo -e "${BOLD}[5/8] PSF skills, context, assets, templates${NC}"
rm -rf "$HERMES_HOME/skills/psf-reviser"

mkdir -p "$HERMES_HOME/skills/psf-writer" "$HERMES_HOME/skills/psf-reviewer"
cp -R "$SCRIPT_DIR/skills/psf-writer/." "$HERMES_HOME/skills/psf-writer/"
cp -R "$SCRIPT_DIR/skills/psf-reviewer/." "$HERMES_HOME/skills/psf-reviewer/"
ok "PSF skills installed"

cp "$SCRIPT_DIR/pandoc/psf_template.docx" "$PSF_SHARED/assets/psf_template.docx"
cp "$SCRIPT_DIR/pandoc/thai_pdf.tex" "$PSF_SHARED/assets/thai_pdf.tex"
cp -R "$SCRIPT_DIR/context/." "$PSF_SHARED/context/"
cp "$SCRIPT_DIR/AGENTS.md" "$PSF_SHARED/AGENTS.md"
ok "Shared assets/context installed read-only source"

cat > "$PSF_SHARED/templates/cv_background.md" <<'TMPL'
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
cp "$SCRIPT_DIR/tests/sample_input/teaching_cases.md" "$PSF_SHARED/templates/teaching_cases.md"
ok "Input templates installed"

if [ -f "$HERMES_HOME/SOUL.md" ] && [ -s "$HERMES_HOME/SOUL.md" ]; then
    warn "Existing default SOUL.md found; leaving it unchanged"
else
    cp "$SCRIPT_DIR/soul_template.md" "$HERMES_HOME/SOUL.md"
    ok "Default SOUL.md installed"
fi

cp "$SCRIPT_DIR/AGENTS.md" "$HERMES_HOME/AGENTS.md"
mkdir -p "$HERMES_HOME/context"
cp -R "$SCRIPT_DIR/context/." "$HERMES_HOME/context/"

echo ""
echo -e "${BOLD}[6/8] API provider setup${NC}"
if [ "${PSF_INSTALL_SKIP_SETUP:-0}" = "1" ]; then
    warn "Skipping hermes setup because PSF_INSTALL_SKIP_SETUP=1"
elif [ -f "$HERMES_HOME/.env" ] && [ -s "$HERMES_HOME/.env" ]; then
    ok "Hermes .env exists; leaving provider credentials unchanged"
else
    info "Configure your model provider. API keys remain in Hermes profiles, not in case folders."
    hermes setup
fi

echo ""
echo -e "${BOLD}[7/8] Template profile${NC}"
template_created=0
if hermes profile show "$PSF_TEMPLATE_PROFILE" >/dev/null 2>&1; then
    warn "Template profile '$PSF_TEMPLATE_PROFILE' already exists; not overwriting config, .env, or SOUL.md"
else
    hermes profile create "$PSF_TEMPLATE_PROFILE" --clone --clone-from default --no-alias \
        --description "Template profile for Thailand-PSF case profiles. Do not use for real case work."
    template_created=1
    ok "Created template profile: $PSF_TEMPLATE_PROFILE"
fi

template_config_path="$(hermes -p "$PSF_TEMPLATE_PROFILE" config path)"
template_dir="$(dirname "$template_config_path")"

if [ "$template_created" -eq 1 ]; then
    cp "$SCRIPT_DIR/soul_template.md" "$template_dir/SOUL.md"
fi
cp "$SCRIPT_DIR/AGENTS.md" "$template_dir/AGENTS.md"
mkdir -p "$template_dir/skills/psf-writer" "$template_dir/skills/psf-reviewer"
cp -R "$SCRIPT_DIR/skills/psf-writer/." "$template_dir/skills/psf-writer/"
cp -R "$SCRIPT_DIR/skills/psf-reviewer/." "$template_dir/skills/psf-reviewer/"
rm -f "$template_dir/memories/MEMORY.md" "$template_dir/memories/USER.md"
rm -f "$template_dir/state.db" "$template_dir/state.db-shm" "$template_dir/state.db-wal"
find "$template_dir/sessions" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
find "$template_dir/logs" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
ok "Template profile has PSF skills and no template memory/session files"

echo ""
echo -e "${BOLD}[8/8] Helper commands${NC}"
BIN_DIR="$HOME/.local/bin"
LIB_DIR="$HOME/.local/lib/psf-assistant"
mkdir -p "$BIN_DIR" "$LIB_DIR"
cp "$SCRIPT_DIR/lib/psf-lib.sh" "$LIB_DIR/psf-lib.sh"
for cmd in psf-new psf-open psf-list psf-close psf-delete-profile; do
    cp "$SCRIPT_DIR/bin/$cmd" "$BIN_DIR/$cmd"
    chmod +x "$BIN_DIR/$cmd"
done
chmod +x "$LIB_DIR/psf-lib.sh"
ok "Installed helper commands to $BIN_DIR"

SHELL_RC=""
if [[ "${SHELL:-}" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "${SHELL:-}" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ] && ! grep -q '\.local/bin' "$SHELL_RC" 2>/dev/null; then
    printf 'export PATH="$HOME/.local/bin:$PATH"\n' >> "$SHELL_RC"
    info "Added ~/.local/bin to $SHELL_RC"
fi

echo ""
echo "================================================="
echo -e "${BOLD}${GREEN}Installation complete${NC}"
echo ""
echo "Create a case with a case ID, not a real name:"
echo -e "  ${BOLD}psf-new PSF-2026-001${NC}"
echo ""
echo "Open the isolated Hermes profile and Docker sandbox:"
echo -e "  ${BOLD}psf-open PSF-2026-001${NC}"
echo ""
echo "Do not open cases with plain 'hermes'; use psf-open so the correct profile and sandbox are used."
echo "================================================="
