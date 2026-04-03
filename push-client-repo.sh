#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKING_DIR="${SCRIPT_DIR}/clients"
DEBUG=false

# --- Help ---
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [CLIENT_ID...]

Add, commit and push client repositories to GitLab.

Arguments:
  CLIENT_ID     One or more client IDs to process (space-separated).
                If omitted, all local directories in clients/ are used.

Options:
  -m, --message MESSAGE   Commit message. Defaults to an automated timestamped message.
  -d, --debug             Enable debug output.
  -h, --help              Show this help message and exit.

Examples:
  $(basename "$0")
  $(basename "$0") 1365
  $(basename "$0") 1365 1241
  $(basename "$0") --message "fix: update config" 1365
  $(basename "$0") -m "fix: update config"
EOF
    exit 0
}

log()   { echo "$@"; }
debug() { $DEBUG && echo "[DEBUG] $*" >&2 || true; }
warn()  { echo "  WARN: $*" >&2; }

# --- Argument parsing ---
CLIENTS_FROM_ARGS=()
COMMIT_MSG_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)     usage ;;
        -d|--debug)    DEBUG=true; shift ;;
        -m|--message)  COMMIT_MSG_ARG="$2"; shift 2 ;;
        *)             CLIENTS_FROM_ARGS+=("$1"); shift ;;
    esac
done

# --- Ensure clients directory exists ---
if [[ ! -d "$WORKING_DIR" ]]; then
    echo "ERROR: ${WORKING_DIR} does not exist. Pull projects first." >&2
    exit 1
fi

# --- Resolve client list ---
if [[ ${#CLIENTS_FROM_ARGS[@]} -gt 0 ]]; then
    CLIENTS_ID=("${CLIENTS_FROM_ARGS[@]}")
    debug "Clients from arguments: ${CLIENTS_ID[*]}"
else
    read -r -p "Clients ID (leave empty for all): " clients_id_prompted

    if [[ -n "$clients_id_prompted" ]]; then
        read -ra CLIENTS_ID <<< "$clients_id_prompted"
    else
        mapfile -t CLIENTS_ID < <(find "$WORKING_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
        debug "Clients found locally: ${#CLIENTS_ID[@]}"
    fi
fi

if [[ ${#CLIENTS_ID[@]} -eq 0 ]]; then
    echo "No clients to process." >&2
    exit 0
fi

# --- Resolve commit message ---
if [[ -n "$COMMIT_MSG_ARG" ]]; then
    COMMIT_MSG="Custom-commit: ${COMMIT_MSG_ARG}"
else
    read -r -p "Commit message (leave empty for automated): " commit_msg_prompted
    if [[ -n "$commit_msg_prompted" ]]; then
        COMMIT_MSG="Custom-commit: ${commit_msg_prompted}"
    else
        COMMIT_MSG="Automated-commit: $(date +%Y%m%d-%H%M%S)"
    fi
fi
debug "Commit message: ${COMMIT_MSG}"

log "Processing ${#CLIENTS_ID[@]} repositories..."

ok=0
failed=0
skipped=0

for client in "${CLIENTS_ID[@]}"; do
    dest="${WORKING_DIR}/${client}"

    if [[ ! -d "${dest}/.git" ]]; then
        warn "${client}: not a git repository, skipping."
        skipped=$((skipped + 1))
        continue
    fi

    debug "Processing ${client} in ${dest}"

    git_output=$(cd "$dest" && git add -A && git status --porcelain 2>&1)

    if [[ -z "$git_output" ]]; then
        log "  [skip]  ${client} — nothing to commit"
        skipped=$((skipped + 1))
        continue
    fi

    if $DEBUG; then
        if (cd "$dest" && git commit -m "$COMMIT_MSG" && git push 2>&1); then
            log "  [push]  ${client}"
            ok=$((ok + 1))
        else
            warn "push failed for ${client}"
            failed=$((failed + 1))
        fi
    else
        if (cd "$dest" && git commit -q -m "$COMMIT_MSG" && git push -q 2>/dev/null); then
            log "  [push]  ${client}"
            ok=$((ok + 1))
        else
            warn "push failed for ${client}"
            failed=$((failed + 1))
        fi
    fi
done

log ""
log "Done — ${ok} pushed, ${skipped} skipped, ${failed} failed."