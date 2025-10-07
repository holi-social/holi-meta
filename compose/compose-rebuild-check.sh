#!/usr/bin/env bash
# Rebuild only services whose watched files' checksums changed since last run.
# Stores all checksums in a single state file.
# On first run (no existing checksums), initializes and exits 0 without rebuilding.
set -euo pipefail

# ---- config (paths relative to repo root) ----
declare -A SERVICE_WATCH=(
  [app-donations]="holi-app-donations/deno.json holi-app-donations/deno.lock"
  [app-goodnews]="holi-app-goodnews/deno.json holi-app-goodnews/deno.lock"
  [geo-api]="holi-geo-api/deno.json holi-geo-api/deno.lock"
  [app-events]="holi-app-events/deno.json holi-app-events/deno.lock"
  [translation-api]="holi-translation-api/deno.json holi-translation-api/deno.lock"
  [notifications]="holi-notifications/deno.json holi-notifications/deno.lock"
  [unified-api]="holi-unified-api/.meshrc.yml holi-unified-api/package.json holi-unified-api/yarn.lock"
  [okuna]="holi-okuna/uv.lock"
  [chat-integration]="holi-chat-integration/.yarnrc.yml holi-chat-integration/package.json holi-chat-integration/yarn.lock"
  [rewards]="holi-rewards/deno.json holi-rewards/deno.lock"
  [frontend-web]="holi-frontends/package.json holi-frontends/apps/web/package.json holi-frontends/holi-bricks/package.json"
  [moderation-backend]="holi-moderation/apps/backend/.yarnrc.yml holi-moderation/.yarnrc.yml holi-moderation/yarn.lock holi-moderation/package.json"
)

COMPOSE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$(dirname "${COMPOSE_DIR}")" && pwd)
STATE_FILE="${COMPOSE_DIR}/.compose-rebuild-state.tsv"   # single file with lines: <key>\t<sha256>
COMPOSE_CMD=("${ROOT_DIR}/holi-dev.sh")      # override if needed

# ---- helpers ----
hash_cmd() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "No sha256sum/shasum available" >&2
    return 127
  fi
}

b64() {  # base64 encode without newlines (portable)
  printf '%s' "$1" | base64 | tr -d '\n'
}

key_for() {  # unique key per (service, file)
  local svc="$1" path="$2"
  printf '%s|%s' "$svc" "$(b64 "$path")"
}

write_state_file() {
  {
    for k in "${!NEW_HASHES[@]}"; do
      printf '%s\t%s\n' "$k" "${NEW_HASHES[$k]}"
    done | sort
  } > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "${STATE_FILE}"
}

# ---- load or initialize state ----
declare -A PREV
if [[ -f "${STATE_FILE}" && -s "${STATE_FILE}" ]]; then
  # load existing checksums
  while IFS=$'\t' read -r k v; do
    [[ -z "${k:-}" || -z "${v:-}" ]] && continue
    PREV["$k"]="$v"
  done < "${STATE_FILE}"
else
  echo "ℹ️  No previous checksum file found — initializing..."
  first_run=true
fi

declare -A SERVICES_CHANGED=()
declare -A NEW_HASHES=()

# ---- compute current hashes ----
for svc in "${!SERVICE_WATCH[@]}"; do
  for watched in ${SERVICE_WATCH[$svc]}; do
    if [[ ! -f "${ROOT_DIR}/$watched" ]]; then
      echo "⚠️  $svc: missing watched file '$watched' — skipping."
      continue
    fi

    k="$(key_for "$svc" "$watched")"
    current_hash="$(hash_cmd "${ROOT_DIR}/$watched")"
    NEW_HASHES["$k"]="$current_hash"

    if [[ -z "${first_run:-}" ]]; then
      prev_hash="${PREV[$k]:-}"
      if [[ "$current_hash" != "$prev_hash" ]]; then
        SERVICES_CHANGED["$svc"]=1
        echo "🔁  $svc: detected change in $watched"
      else
        echo "✅  $svc: no change in $watched"
      fi
    fi
  done
done

# ---- handle first run or rebuild ----
if [[ -n "${first_run:-}" ]]; then
  write_state_file
  echo "✅  Initial checksums recorded. No rebuild needed."
  exit 0
fi

if ((${#SERVICES_CHANGED[@]} == 0)); then
  echo "✅  No watched changes — no rebuild needed."
  exit 0
fi

services_to_build=("${!SERVICES_CHANGED[@]}")
echo "🛠️  Rebuilding: ${services_to_build[*]}"
"${COMPOSE_CMD[@]}" build "${services_to_build[@]}"
echo "✅  Rebuild done."

# ---- write state file ----
echo "💾  Updating checksums..."
write_state_file
echo "✅  Done."
