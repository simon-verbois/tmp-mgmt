#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARS_FILE="${SCRIPT_DIR}/roles/common/vars/gitlab.yaml"
WORKING_DIR="${SCRIPT_DIR}/clients"
VAULTS_DIR="${SCRIPT_DIR}/vaults"
VAULT_ARGS=()
DEBUG=false

# --- Help ---
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [CLIENT_ID...]

Clone or pull client repositories from GitLab.

Arguments:
  CLIENT_ID     One or more client IDs to process (space-separated).
                If omitted, all non-archived projects are fetched from the GitLab API.

Options:
  -d, --debug   Enable debug output.
  -h, --help    Show this help message and exit.

Examples:
  $(basename "$0")
  $(basename "$0") 1365
  $(basename "$0") 1365 1241
  $(basename "$0") --debug 1365
EOF
    exit 0
}

log()   { echo "$@"; }
debug() { $DEBUG && echo "[DEBUG] $*" >&2 || true; }
warn()  { echo "  WARN: $*" >&2; }

# --- Argument parsing ---
CLIENTS_FROM_ARGS=()
for arg in "$@"; do
    case "$arg" in
        -h|--help)  usage ;;
        -d|--debug) DEBUG=true ;;
        *)          CLIENTS_FROM_ARGS+=("$arg") ;;
    esac
done

# --- Resolve client list (before slow operations) ---
FETCH_ALL=false
if [[ ${#CLIENTS_FROM_ARGS[@]} -gt 0 ]]; then
    CLIENTS_ID=("${CLIENTS_FROM_ARGS[@]}")
    debug "Clients from arguments: ${CLIENTS_ID[*]}"
else
    read -r -p "Clients ID (leave empty for all): " clients_id_prompted

    if [[ -n "$clients_id_prompted" ]]; then
        read -ra CLIENTS_ID <<< "$clients_id_prompted"
    else
        FETCH_ALL=true
    fi
fi

# --- Vault handling ---
if grep -q '!vault' "$VARS_FILE" 2>/dev/null; then
    for vault_file in "${VAULTS_DIR}"/*; do
        vault_id="$(basename "$vault_file")"
        VAULT_ARGS+=(--vault-id "${vault_id}@${vault_file}")
        debug "Vault loaded: ${vault_id}"
    done
fi

# --- Extract vars via Ansible ---
_extract_var() {
    ansible localhost -m debug -a "msg={{ $1 }}" \
        -e "@${VARS_FILE}" "${VAULT_ARGS[@]+"${VAULT_ARGS[@]}"}" --connection=local 2>/dev/null \
    | grep -oP '(?<=msg: ).*' \
    || true
}

debug "Extracting variables from ${VARS_FILE}"
GITLAB_FQDN=$(_extract_var "__gitlab_fqdn")
GITLAB_TOKEN=$(_extract_var "__gitlab_ictlas_token")

debug "FQDN:  ${GITLAB_FQDN}"
debug "TOKEN: ${GITLAB_TOKEN:0:6}..."

if [[ -z "$GITLAB_FQDN" || -z "$GITLAB_TOKEN" ]]; then
    echo "ERROR: Could not resolve __gitlab_fqdn or __gitlab_ictlas_token" >&2
    exit 1
fi

GITLAB_API_URL="https://${GITLAB_FQDN}"
GITLAB_GROUP_API_PATH="ict-las%2Fclients"
GIT_BASE_URL="git@${GITLAB_FQDN}:ict-las/clients"

# --- Fetch all projects from API if needed ---
if $FETCH_ALL; then
    debug "Fetching project list from GitLab API..."
    response=$(curl -sf \
        -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        "${GITLAB_API_URL}/api/v4/groups/${GITLAB_GROUP_API_PATH}/projects?per_page=100&include_subgroups=false") || true

    if [[ -z "$response" ]]; then
        echo "ERROR: GitLab API call failed or returned empty." >&2
        exit 1
    fi

    mapfile -t CLIENTS_ID < <(
        echo "$response" | python3 -c "
import sys, json
projects = json.load(sys.stdin)
for p in projects:
    if not p.get('archived', False):
        print(p['path'])
"
    )
    debug "Projects fetched: ${#CLIENTS_ID[@]}"
fi

if [[ ${#CLIENTS_ID[@]} -eq 0 ]]; then
    echo "No clients to process." >&2
    exit 0
fi

mkdir -p "$WORKING_DIR"

# --- Clone or pull ---
log "Processing ${#CLIENTS_ID[@]} repositories..."

ok=0
failed=0

for client in "${CLIENTS_ID[@]}"; do
    repo_url="${GIT_BASE_URL}/${client}.git"
    dest="${WORKING_DIR}/${client}"

    if [[ -d "${dest}/.git" ]]; then
        debug "Pulling ${client} in ${dest}"
        if $DEBUG; then
            (cd "$dest" && git pull --ff-only 2>&1) && { log "  [pull]  ${client}"; ok=$((ok + 1)); } || { warn "pull failed for ${client}"; failed=$((failed + 1)); }
        else
            (cd "$dest" && git pull --ff-only -q 2>/dev/null) && { log "  [pull]  ${client}"; ok=$((ok + 1)); } || { warn "pull failed for ${client}"; failed=$((failed + 1)); }
        fi
    else
        debug "Cloning ${client} into ${dest}"
        if $DEBUG; then
            GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" \
                git clone "$repo_url" "$dest" 2>&1 \
                && { log "  [clone] ${client}"; ok=$((ok + 1)); } || { warn "clone failed for ${client}"; failed=$((failed + 1)); }
        else
            GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" \
                git clone -q "$repo_url" "$dest" 2>/dev/null \
                && { log "  [clone] ${client}"; ok=$((ok + 1)); } || { warn "clone failed for ${client}"; failed=$((failed + 1)); }
        fi
    fi
done

log ""
log "Done — ${ok} succeeded, ${failed} failed."