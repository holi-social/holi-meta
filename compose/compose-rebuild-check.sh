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

declare -A PROFILE_SERVICES=(
  [minimal]="app-donations app-goodnews geo-api app-events translation-api notifications unified-api okuna chat-integration rewards frontend-web"
  [all]="app-donations app-goodnews geo-api app-events translation-api notifications unified-api okuna chat-integration rewards frontend-web moderation-backend"
  [moderation]="moderation-backend"
  [frontend-staging]="frontend-web"
)

COMPOSE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$(dirname "${COMPOSE_DIR}")" && pwd)
STATE_FILE="${COMPOSE_DIR}/.compose-rebuild-state.tsv"   # single file with lines: <key>\t<sha256>
COMPOSE_CMD=("${ROOT_DIR}/holi-dev.sh")                  # override if needed

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

b64() { printf '%s' "$1" | base64 | tr -d '\n'; }

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

# ---- resolve active services from COMPOSE_PROFILES ----
# Accept comma/space separated profiles. Default to "all" (union of everything) if unset.
resolve_active_services() {
  local profiles_raw="${COMPOSE_PROFILES:-minimal}"
  # Normalize separators to spaces
  read -r -a profiles <<<"$(tr ',:' ' ' <<<"$profiles_raw")"

  # If explicitly empty (e.g., COMPOSE_PROFILES=""), fall back to all
  if [[ ${#profiles[@]} -eq 0 || -z "${profiles[0]}" ]]; then
    profiles=(all)
  fi

  declare -A seen=()
  for p in "${profiles[@]}"; do
    if [[ -z "${PROFILE_SERVICES[$p]:-}" ]]; then
      echo "⚠️  Unknown profile '$p' — ignoring."
      continue
    fi
    for s in ${PROFILE_SERVICES[$p]}; do
      seen["$s"]=1
    done
  done

  # Emit space-separated list
  if (( ${#seen[@]} == 0 )); then
    echo ""
  else
    printf '%s ' "${!seen[@]}"
  fi
}

ACTIVE_SERVICES_STR="$(resolve_active_services)"
read -r -a ACTIVE_SERVICES <<<"$ACTIVE_SERVICES_STR"

if (( ${#ACTIVE_SERVICES[@]} == 0 )); then
  echo "ℹ️  No services resolved from COMPOSE_PROFILES='${COMPOSE_PROFILES:-}' — nothing to do."
  exit 0
fi

echo "👀  Active profiles: ${COMPOSE_PROFILES:-all}"
echo "🎯  Services in scope: ${ACTIVE_SERVICES[*]}"

# ---- load or initialize state ----
declare -A PREV
if [[ -f "${STATE_FILE}" && -s "${STATE_FILE}" ]]; then
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

# ---- compute current hashes (only for ACTIVE_SERVICES) ----
for svc in "${ACTIVE_SERVICES[@]}"; do
  # guard against typos: skip services not defined in SERVICE_WATCH
  if [[ -z "${SERVICE_WATCH[$svc]:-}" ]]; then
    echo "⚠️  '$svc' has no watch definition — skipping."
    continue
  fi

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
      # else
        # echo "✅  $svc: no change in $watched"
      fi
    fi
  done
done

# ---- handle first run or rebuild ----
if [[ -n "${first_run:-}" ]]; then
  write_state_file
  echo "✅  Initial checksums recorded for scoped services. No rebuild needed."
  exit 0
fi

if ((${#SERVICES_CHANGED[@]} == 0)); then
  echo "✅  No watched changes in scoped services — no rebuild needed."
  exit 0
fi

# Only rebuild scoped, changed services
services_to_build=("${!SERVICES_CHANGED[@]}")
echo "🛠️  Rebuilding (scoped): ${services_to_build[*]}"
"${COMPOSE_CMD[@]}" build "${services_to_build[@]}"
echo "✅  Rebuild done."

# ---- write state file ----
echo "💾  Updating checksums..."
write_state_file
echo "✅  Done."
