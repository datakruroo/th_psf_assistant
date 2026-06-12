#!/usr/bin/env bash

psf_err() {
    printf 'ERROR: %s\n' "$*" >&2
}

psf_info() {
    printf '%s\n' "$*"
}

psf_root() {
    printf '%s\n' "${PSF_ROOT:-$HOME/Documents/psf-assistant}"
}

psf_hermes_home() {
    printf '%s\n' "${HERMES_HOME:-$HOME/.hermes}"
}

psf_shared_root() {
    printf '%s\n' "${PSF_SHARED:-$(psf_hermes_home)/psf-shared}"
}

psf_template_profile() {
    printf '%s\n' "${PSF_TEMPLATE_PROFILE:-psf-template}"
}

psf_docker_image() {
    printf '%s\n' "${PSF_DOCKER_IMAGE:-psf-assistant:local}"
}

psf_canonical_case_id() {
    local raw="${1:-}"
    if [ -z "$raw" ]; then
        psf_err "case ID cannot be empty"
        return 1
    fi
    case "$raw" in
        */*|.*|*..*)
            psf_err "invalid case folder name '$raw'. Do not use path separators, leading dots, or '..'."
            return 1
            ;;
    esac

    local normalized
    normalized="${raw//_/-}"
    if [[ "$normalized" =~ ^[Pp][Ss][Ff]-([0-9]{4})-([0-9]{3})(-.+)?$ ]]; then
        printf 'PSF-%s-%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return 0
    fi

    psf_err "invalid case ID '$raw'. Expected PSF-YYYY-NNN, optionally with a suffix, e.g. PSF-2026-001 or PSF-2026-001_somchai"
    return 1
}

psf_validate_case_id() {
    psf_canonical_case_id "$1" >/dev/null
}

psf_slugify_case_suffix() {
    local raw="${1:-}"
    if [ -z "$raw" ]; then
        psf_err "case name cannot be empty"
        return 1
    fi
    case "$raw" in
        */*|.*|*..*)
            psf_err "invalid case name '$raw'. Do not use path separators, leading dots, or '..'."
            return 1
            ;;
    esac

    local suffix
    suffix="$(
        printf '%s' "$raw" \
            | tr '[:upper:]' '[:lower:]' \
            | sed -E 's/[[:space:]]+/_/g; s/[^[:alnum:]_.-]+/_/g; s/_+/_/g; s/^[_.-]+//; s/[_.-]+$//'
    )"
    if [ -z "$suffix" ]; then
        psf_err "case name '$raw' did not contain usable characters"
        return 1
    fi
    printf '%s\n' "$suffix"
}

psf_next_case_number_for_year() {
    local year="$1"
    local cases_dir max=0 entry base canonical number
    cases_dir="$(psf_root)/cases"

    if [ -d "$cases_dir" ]; then
        for entry in "$cases_dir"/*; do
            [ -d "$entry" ] || continue
            base="$(basename "$entry")"
            canonical="$(psf_canonical_case_id "$base" 2>/dev/null || true)"
            case "$canonical" in
                PSF-"$year"-[0-9][0-9][0-9])
                    number="${canonical##*-}"
                    number=$((10#$number))
                    if [ "$number" -gt "$max" ]; then
                        max="$number"
                    fi
                    ;;
            esac
        done
    fi

    printf '%03d\n' "$((max + 1))"
}

psf_next_available_case_id() {
    local year="$1"
    local number canonical profile case_dir
    number="$(psf_next_case_number_for_year "$year")"

    while :; do
        canonical="$(printf 'PSF-%s-%03d' "$year" "$((10#$number))")"
        profile="$(psf_profile_for_case "$canonical")"
        case_dir="$(psf_case_dir "$canonical" 2>/dev/null || true)"
        if { [ -z "$case_dir" ] || [ ! -d "$case_dir" ]; } && ! psf_profile_exists "$profile"; then
            printf '%s\n' "$canonical"
            return 0
        fi
        number="$(printf '%03d' "$((10#$number + 1))")"
    done
}

psf_profile_for_case() {
    psf_canonical_case_id "$1" | tr '[:upper:]' '[:lower:]'
}

psf_case_dir_for_new() {
    printf '%s/cases/%s\n' "$(psf_root)" "$1"
}

psf_case_dir() {
    local ref="$1"
    local cases_dir
    cases_dir="$(psf_root)/cases"

    if [ -d "$cases_dir/$ref" ]; then
        printf '%s\n' "$cases_dir/$ref"
        return 0
    fi

    local wanted
    wanted="$(psf_canonical_case_id "$ref")" || return 1

    local match="" count=0 entry base canonical
    if [ -d "$cases_dir" ]; then
        for entry in "$cases_dir"/*; do
            [ -d "$entry" ] || continue
            base="$(basename "$entry")"
            canonical="$(psf_canonical_case_id "$base" 2>/dev/null || true)"
            if [ "$canonical" = "$wanted" ]; then
                match="$entry"
                count=$((count + 1))
            fi
        done
    fi

    if [ "$count" -eq 1 ]; then
        printf '%s\n' "$match"
        return 0
    fi
    if [ "$count" -gt 1 ]; then
        psf_err "multiple case folders match $wanted; use the exact folder name"
        return 1
    fi

    printf '%s\n' "$cases_dir/$ref"
}

psf_require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        psf_err "required command '$1' was not found in PATH"
        return 1
    }
}

psf_profile_exists() {
    hermes profile show "$1" >/dev/null 2>&1
}

psf_profile_config_path() {
    hermes -p "$1" config path
}

psf_python() {
    if command -v python3 >/dev/null 2>&1; then
        printf 'python3\n'
    elif command -v python >/dev/null 2>&1; then
        printf 'python\n'
    else
        psf_err "python3 or python is required"
        return 1
    fi
}

psf_check_docker_ready() {
    psf_require_command docker || return 1
    if ! docker info >/dev/null 2>&1; then
        psf_err "Docker daemon is not reachable. Start Docker Desktop on macOS, or start the Docker service on Linux, then try again."
        psf_err "This command will not fall back to the local terminal backend because that would not isolate case files."
        return 1
    fi
}

psf_count_files() {
    if [ ! -d "$1" ]; then
        printf '0\n'
        return 0
    fi
    find "$1" -type f | wc -l | tr -d '[:space:]'
}

psf_input_template_dir() {
    local shared_templates
    shared_templates="$(psf_shared_root)/templates"
    if [ -f "$shared_templates/cv_background.md" ] && [ -f "$shared_templates/teaching_cases.md" ]; then
        printf '%s\n' "$shared_templates"
        return 0
    fi

    local legacy_templates
    legacy_templates="$(psf_hermes_home)/templates"
    if [ -f "$legacy_templates/cv_background.md" ] && [ -f "$legacy_templates/teaching_cases.md" ]; then
        printf '%s\n' "$legacy_templates"
        return 0
    fi

    psf_err "input templates were not found. Re-run install.sh to create shared templates."
    return 1
}

psf_sync_profile_support_files() {
    local profile="$1"
    local profile_dir
    profile_dir="$(dirname "$(psf_profile_config_path "$profile")")"

    local shared
    shared="$(psf_shared_root)"

    if [ -f "$shared/AGENTS.md" ]; then
        cp "$shared/AGENTS.md" "$profile_dir/AGENTS.md"
    fi

    mkdir -p "$profile_dir/skills"
    if [ -d "$(psf_hermes_home)/skills/psf-writer" ]; then
        mkdir -p "$profile_dir/skills/psf-writer"
        cp -R "$(psf_hermes_home)/skills/psf-writer/." "$profile_dir/skills/psf-writer/"
    fi
    if [ -d "$(psf_hermes_home)/skills/psf-reviewer" ]; then
        mkdir -p "$profile_dir/skills/psf-reviewer"
        cp -R "$(psf_hermes_home)/skills/psf-reviewer/." "$profile_dir/skills/psf-reviewer/"
    fi

    rm -f "$profile_dir/memories/MEMORY.md" "$profile_dir/memories/USER.md"
    rm -f "$profile_dir/state.db" "$profile_dir/state.db-shm" "$profile_dir/state.db-wal"
    find "$profile_dir/sessions" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
    find "$profile_dir/logs" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
}

psf_write_profile_docker_config() {
    local profile="$1"
    local case_id="$2"
    local case_dir="$3"
    local config_path
    config_path="$(psf_profile_config_path "$profile")"

    local input_dir workspace_dir deliverables_dir assets_dir context_dir image
    input_dir="$case_dir/input"
    workspace_dir="$case_dir/workspace"
    deliverables_dir="$case_dir/deliverables"
    assets_dir="$(psf_shared_root)/assets"
    context_dir="$(psf_shared_root)/context"
    image="$(psf_docker_image)"

    local py
    py="$(psf_python)"
    "$py" - "$config_path" "$image" "$case_id" "$profile" "$input_dir" "$workspace_dir" "$deliverables_dir" "$assets_dir" "$context_dir" <<'PY'
import sys
from pathlib import Path

config_path, image, case_id, profile, input_dir, workspace_dir, deliverables_dir, assets_dir, context_dir = sys.argv[1:]

def q(value: str) -> str:
    return '"' + value.replace('\\', '\\\\').replace('"', '\\"') + '"'

volumes = [
    f"{input_dir}:/input:ro",
    f"{workspace_dir}:/workspace",
    f"{deliverables_dir}:/deliverables",
    f"{assets_dir}:/assets:ro",
    f"{context_dir}:/psf-context:ro",
]

terminal_lines = [
    "terminal:",
    "  backend: docker",
    "  modal_mode: auto",
    "  cwd: /workspace",
    "  timeout: 180",
    "  env_passthrough: []",
    "  shell_init_files: []",
    "  auto_source_bashrc: true",
    f"  docker_image: {q(image)}",
    "  docker_forward_env: []",
    "  docker_env: {}",
    "  docker_mount_cwd_to_workspace: false",
    "  docker_run_as_host_user: true",
    "  docker_persist_across_processes: true",
    "  container_persistent: true",
    "  persistent_shell: true",
    "  docker_volumes:",
]
terminal_lines.extend(f"    - {q(volume)}" for volume in volumes)
terminal_lines.extend([
    "  docker_extra_args:",
    "    - --label",
    f"    - {q('psf.case_id=' + case_id)}",
    "    - --label",
    f"    - {q('psf.profile=' + profile)}",
])

path = Path(config_path)
path.parent.mkdir(parents=True, exist_ok=True)
text = path.read_text(encoding="utf-8") if path.exists() else ""
lines = text.splitlines()

start = None
for index, line in enumerate(lines):
    if line == "terminal:":
        start = index
        break

if start is None:
    if lines and lines[-1].strip():
        lines.append("")
    lines.extend(terminal_lines)
else:
    end = len(lines)
    for index in range(start + 1, len(lines)):
        line = lines[index]
        if line and not line.startswith((" ", "\t")) and not line.startswith("#"):
            end = index
            break
    lines = lines[:start] + terminal_lines + lines[end:]

path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
}
