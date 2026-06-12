#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export HOME="$TMP_DIR/home"
export HERMES_HOME="$HOME/.hermes"
export PSF_ROOT="$HOME/Documents/psf-assistant"
export PSF_SHARED="$HERMES_HOME/psf-shared"
export PSF_INSTALL_SKIP_SETUP=1
export PSF_INSTALL_SKIP_DOCKER_BUILD=1
export PATH="$TMP_DIR/fakebin:$ROOT_DIR/bin:$PATH"

mkdir -p "$TMP_DIR/fakebin" "$HOME" "$HERMES_HOME" "$PSF_SHARED/templates"

cat > "$TMP_DIR/fakebin/hermes" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail

home="${HERMES_HOME:-$HOME/.hermes}"

profile_dir() {
    if [ "$1" = "default" ]; then
        printf '%s\n' "$home"
    else
        printf '%s/profiles/%s\n' "$home" "$1"
    fi
}

profile="default"
if [ "${1:-}" = "-p" ]; then
    profile="$2"
    shift 2
fi

case "${1:-}" in
    --version)
        printf 'Hermes Agent fake\n'
        ;;
    profile)
        shift
        sub="${1:-}"
        shift || true
        case "$sub" in
            show)
                dir="$(profile_dir "$1")"
                [ -d "$dir" ] || exit 1
                printf 'Profile: %s\nPath: %s\n' "$1" "$dir"
                ;;
            create)
                name="$1"
                shift
                clone_from="default"
                while [ "$#" -gt 0 ]; do
                    case "$1" in
                        --clone-from)
                            clone_from="$2"
                            shift 2
                            ;;
                        --description)
                            shift 2
                            ;;
                        --clone|--clone-all|--no-alias)
                            shift
                            ;;
                        *)
                            shift
                            ;;
                    esac
                done
                dest="$(profile_dir "$name")"
                [ ! -e "$dest" ] || exit 1
                mkdir -p "$dest/memories" "$dest/sessions" "$dest/skills" "$dest/logs"
                src="$(profile_dir "$clone_from")"
                for file in config.yaml .env SOUL.md AGENTS.md; do
                    [ -f "$src/$file" ] && cp "$src/$file" "$dest/$file"
                done
                if [ -d "$src/skills" ]; then
                    cp -R "$src/skills/." "$dest/skills/"
                fi
                ;;
            delete)
                name=""
                for arg in "$@"; do
                    case "$arg" in
                        -y|--yes) ;;
                        *) name="$arg" ;;
                    esac
                done
                [ -n "$name" ] || exit 2
                rm -rf "$(profile_dir "$name")"
                ;;
            list)
                printf 'default\n'
                [ -d "$home/profiles" ] && find "$home/profiles" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
                ;;
            *)
                exit 2
                ;;
        esac
        ;;
    config)
        shift
        [ "${1:-}" = "path" ] || exit 2
        printf '%s/config.yaml\n' "$(profile_dir "$profile")"
        ;;
    chat)
        printf '%s\n' "$profile" >> "${PSF_TEST_CHAT_LOG:-$TMPDIR/psf-chat.log}"
        ;;
    setup)
        mkdir -p "$home"
        printf 'OPENROUTER_API_KEY=fake\n' > "$home/.env"
        ;;
    *)
        exit 2
        ;;
esac
FAKE

cat > "$TMP_DIR/fakebin/docker" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    --version)
        printf 'Docker fake\n'
        ;;
    info)
        [ "${PSF_FAKE_DOCKER_DOWN:-0}" != "1" ] || exit 1
        printf 'fake docker info\n'
        ;;
    image)
        [ "${2:-}" = "inspect" ] || exit 2
        exit 0
        ;;
    build)
        exit 0
        ;;
    ps)
        exit 0
        ;;
    stop)
        shift
        printf '%s\n' "$@" >> "${PSF_TEST_DOCKER_STOP_LOG:-$TMPDIR/psf-docker-stop.log}"
        ;;
    *)
        exit 2
        ;;
esac
FAKE

cat > "$TMP_DIR/fakebin/pandoc" <<'FAKE'
#!/usr/bin/env bash
printf 'pandoc fake\n'
FAKE

chmod +x "$TMP_DIR/fakebin/hermes" "$TMP_DIR/fakebin/docker" "$TMP_DIR/fakebin/pandoc"

mkdir -p "$HERMES_HOME/profiles/psf-template/skills" "$HERMES_HOME/profiles/psf-template/memories" "$HERMES_HOME/profiles/psf-template/sessions" "$HERMES_HOME/profiles/psf-template/logs"
cat > "$HERMES_HOME/config.yaml" <<'EOF'
model:
  default: fake/model
custom_keep: yes
terminal:
  backend: local
EOF
printf 'OPENROUTER_API_KEY=fake\n' > "$HERMES_HOME/.env"
printf '# Default soul\n' > "$HERMES_HOME/SOUL.md"
cp "$HERMES_HOME/config.yaml" "$HERMES_HOME/profiles/psf-template/config.yaml"
cp "$HERMES_HOME/.env" "$HERMES_HOME/profiles/psf-template/.env"
printf '# Template soul\n' > "$HERMES_HOME/profiles/psf-template/SOUL.md"

cat > "$PSF_SHARED/templates/cv_background.md" <<'EOF'
# CV template
EOF
cp "$ROOT_DIR/tests/sample_input/teaching_cases.md" "$PSF_SHARED/templates/teaching_cases.md"
mkdir -p "$PSF_SHARED/assets" "$PSF_SHARED/context"
printf 'agent instructions\n' > "$PSF_SHARED/AGENTS.md"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_dir() {
    [ -d "$1" ] || fail "missing directory: $1"
}

assert_file() {
    [ -f "$1" ] || fail "missing file: $1"
}

assert_contains() {
    grep -qF "$2" "$1" || fail "expected '$2' in $1"
}

assert_not_contains() {
    ! grep -qF "$2" "$1" || fail "did not expect '$2' in $1"
}

expect_fail() {
    if "$@" >/tmp/psf-smoke.out 2>/tmp/psf-smoke.err; then
        fail "expected command to fail: $*"
    fi
}

psf-new PSF-2026-001 >/tmp/psf-smoke-new.out

CASE1="$PSF_ROOT/cases/PSF-2026-001"
PROFILE1="$HERMES_HOME/profiles/psf-2026-001"
CONFIG1="$PROFILE1/config.yaml"

assert_dir "$CASE1/input"
assert_dir "$CASE1/input/papers"
assert_dir "$CASE1/workspace"
assert_dir "$CASE1/deliverables"
assert_file "$CASE1/input/cv_background.md"
assert_file "$CASE1/input/teaching_cases.md"
assert_dir "$PROFILE1"
assert_file "$CONFIG1"
assert_contains "$CONFIG1" "$CASE1/input:/input:ro"
assert_contains "$CONFIG1" "$CASE1/workspace:/workspace"
assert_contains "$CONFIG1" "$CASE1/deliverables:/deliverables"
assert_contains "$CONFIG1" "$PSF_SHARED/assets:/assets:ro"
assert_contains "$CONFIG1" "$PSF_SHARED/context:/psf-context:ro"
assert_contains "$CONFIG1" "docker_mount_cwd_to_workspace: false"
assert_contains "$CONFIG1" "docker_forward_env: []"
assert_contains "$CONFIG1" "docker_env: {}"
assert_not_contains "$CONFIG1" "$HOME:/"
assert_not_contains "$CONFIG1" "$HOME/Documents:/"

expect_fail psf-new PSF-2026-001
expect_fail psf-new Somchai

psf-new PSF-2026-002 >/tmp/psf-smoke-new2.out
assert_not_contains "$CONFIG1" "PSF-2026-002"
assert_not_contains "$CONFIG1" "psf-2026-002"

psf-new psf_2026_003_somchai >/tmp/psf-smoke-new3.out
CASE3="$PSF_ROOT/cases/psf_2026_003_somchai"
PROFILE3="$HERMES_HOME/profiles/psf-2026-003"
CONFIG3="$PROFILE3/config.yaml"
assert_dir "$CASE3"
assert_dir "$PROFILE3"
assert_contains "$CONFIG3" "$CASE3/input:/input:ro"
assert_contains "$CONFIG3" "psf.case_id=PSF-2026-003"
expect_fail psf-new PSF-2026-003

printf 'Somchai Example\n' >> "$CASE1/input/cv_background.md"
LIST_OUT="$(psf-list)"
printf '%s\n' "$LIST_OUT" | grep -q "PSF-2026-001" || fail "psf-list did not show case ID"
printf '%s\n' "$LIST_OUT" | grep -q "psf_2026_003_somchai" || fail "psf-list did not show friendly folder name"
printf '%s\n' "$LIST_OUT" | grep -q "Somchai" && fail "psf-list leaked real-name content"

PSF_FAKE_DOCKER_DOWN=1 expect_fail psf-open PSF-2026-001

psf-delete-profile --yes PSF-2026-001 >/tmp/psf-smoke-delete.out
assert_dir "$CASE1"
[ ! -d "$PROFILE1" ] || fail "profile was not deleted"

"$ROOT_DIR/install.sh" >/tmp/psf-smoke-install.out
assert_contains "$HERMES_HOME/profiles/psf-template/config.yaml" "custom_keep: yes"

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$ROOT_DIR/install.sh" "$ROOT_DIR"/bin/psf-* "$ROOT_DIR/lib/psf-lib.sh" "$ROOT_DIR/tests/smoke.sh"
fi

printf 'All smoke tests passed.\n'
