#!/usr/bin/env bash
set -eo pipefail

# commands and options
profile="${COMPOSE_PROFILES:-minimal}"
command=""
rest=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile|-p)
      profile="$2"
      shift 2
      ;;
    init|start|stop|status|logs|exec|migrate|services|attach|build|compose)
      command="$1"
      shift
      ;;
    *)
      rest+=("$1")
      shift
      ;;
  esac
done

# set the profile for docker compose
export COMPOSE_PROFILES="${profile}"

##############################
# environment variable setup #
##############################

create_env_file() {
  local path_dir="$1"
  local env_template_file="$2"
  local env_file="$3"

  if [ ! -f "$path_dir/$env_file" ]; then
    if [ -f "$path_dir/$env_template_file" ]; then
      cp "$path_dir/$env_template_file" "$path_dir/$env_file"
    else
      echo "Template file $path_dir/$env_template_file does not exist. Cannot create $path_dir/$env_file."
      exit 1
    fi
  fi
}

OKUNA_COMPOSE_ENV_FILE="./holi-okuna/.docker-compose.env.local"

## Initialization
if [ "$command" = "init" ]; then
  # Create Okuna env file
  if [ ! -f $OKUNA_COMPOSE_ENV_FILE ]; then
    # generate a random secret key
    # step 1: copy the template file to the target location

    if [ -f "./holi-okuna/templates/.docker-compose.env.local" ]; then
      cp ./holi-okuna/templates/.docker-compose.env.local ./holi-okuna/.docker-compose.env.local
    else
      echo "./holi-okuna/templates/ does not exist. Cannot copy .docker-compose.env.local."
      exit 1
    fi
    # step 2: generate a secret key (cross-platform for macOS/Linux/Windows Unix)
    if command -v openssl &> /dev/null; then
      OKUNA_SECRET_KEY=$(openssl rand -base64 40 | tr -d '\n=+')
    elif [ -c /dev/urandom ]; then
      OKUNA_SECRET_KEY=$(head -c 30 /dev/urandom | base64 | tr -d '\n=+')
    elif command -v uuidgen &> /dev/null; then
      OKUNA_SECRET_KEY=$(uuidgen | tr -d '-')
    else
      echo "Cannot generate a secret key for Okuna Django."
      exit 1
    fi
    # step 3: replace {{DJANGO_SECRET_KEY}} in the .docker-compose.env.local file with the generated secret key
    sed -i.bak "s|{{DJANGO_SECRET_KEY}}|$OKUNA_SECRET_KEY|" ./holi-okuna/.docker-compose.env.local && rm ./holi-okuna/.docker-compose.env.local.bak
  fi

  # Create frontends env file
  create_env_file "./compose/frontends" ".env.template" ".env"

  # Create unified api env file
  create_env_file "./compose/unified-api" ".env.template" ".env"

  echo "Initialization completed."
  exit 0
else
  if [ ! -f $OKUNA_COMPOSE_ENV_FILE ]; then
    echo "The file $OKUNA_COMPOSE_ENV_FILE does not exist. Please run './holi-dev.sh init' first to create it."
    exit 1
  fi
fi

# set library paths for GDAL, GEOS, and PROJ
LIB_BASE_PATH="/usr/lib/$(uname -m | sed 's/^arm64$/aarch64/')-linux-gnu"
export GDAL_LIBRARY_PATH="$LIB_BASE_PATH/libgdal.so"
export GEOS_LIBRARY_PATH="$LIB_BASE_PATH/libgeos_c.so"
export PROJ_LIBRARY_PATH="$LIB_BASE_PATH/libproj.so"

## Frontend Mobile
# set the path for the Android SDK
export ANDROID_HOME=$([ "$(uname)" = "Darwin" ] && echo "$HOME/Library/Android/sdk" || echo "$HOME/Android/Sdk")

# set development host IP address
get_local_ip_linux() {
  default_device=$(ip route | grep default | head -n 1 | awk '{print $5}')
  ip addr show dev "$default_device" | grep -oP 'inet \K[\d.]+'
}
get_local_ip_macos() {
  default_device=$(netstat -rn | grep default | grep -v utun | head -n 1 | awk '{print $4}')
  ipconfig getifaddr "$default_device"
}
if [ -z "${DEV_HOST:-}" ]; then
  if [ "$(uname)" = "Linux" ]; then
    DEV_HOST=$(get_local_ip_linux)
  elif [ "$(uname)" = "Darwin" ]; then
    DEV_HOST=$(get_local_ip_macos)
  else
    echo "Could not determine the local IP address. Please provide it yourself in .env.local"
    exit 1
  fi
  echo "Determined the local IP to be $DEV_HOST. If this is not correct, please provide it yourself in DEV_HOST"
fi
export DEV_HOST

#####################################
# end of environment variable setup #
#####################################

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG_DIR="$ROOT_DIR/compose"

# prepare the base command for docker compose
cmd_base=(docker compose \
  # sets the root directory for the compose file
  --project-directory	$ROOT_DIR \
  # sets the default variables for the compose file
  --env-file $CONFIG_DIR/.env \
  # sets which compose file to use
  --file $CONFIG_DIR/compose.infra.yaml)

# add overlay compose files based on the profile
case "$profile" in
  minimal)
    cmd_base+=(
      --file $CONFIG_DIR/compose.base.yaml \
      --file $CONFIG_DIR/compose.frontend.yaml \
      --file $CONFIG_DIR/compose.moderation.yaml
    )
    ;;
  all)
    cmd_base+=(
      --file $CONFIG_DIR/compose.base.yaml \
      --file $CONFIG_DIR/compose.frontend.yaml \
      --file $CONFIG_DIR/compose.moderation.yaml \
      --file $CONFIG_DIR/compose.misc.yaml
    )
    ;;
  moderation)
    cmd_base+=(--file $CONFIG_DIR/compose.moderation.yaml)
    ;;
  frontend-staging)
    cmd_base+=(
      --file $CONFIG_DIR/compose.frontend.yaml \
      --file $CONFIG_DIR/compose.frontend.staging.yaml
    )
    ;;
esac

# handle commands
case "$command" in
  start)
    # check if we need to rebuild any services
    ./compose/compose-rebuild-check.sh
    
    # start the services in detached mode and then start watching for changes
    "${cmd_base[@]}" up --detach "${rest[@]}" && \
      echo -e "\nServices are running in detach mode.\nWatching the file changes..." && \
      "${cmd_base[@]}" watch --no-up 2>&1 | \
        # Filter the warning logs about volume binding and watch mode path conflicts
        (grep -v ".*declared by a bind mount volume, this path won't be monitored")
    ;;
  stop)
    "${cmd_base[@]}" down "${rest[@]}"
    ;;
  status)
    "${cmd_base[@]}" ps "${rest[@]}"
    ;;
  logs)
    "${cmd_base[@]}" logs "${rest[@]}"
    ;;
  exec)
    "${cmd_base[@]}" exec -it "${rest[@]}"
    ;;
  migrate)
    $CONFIG_DIR/pg/migrate.sh "${rest[@]}"
    ;;
  services)
    "${cmd_base[@]}" config --service
    ;;
  attach)
    "${cmd_base[@]}" attach --detach-keys "ctrl-c" "${rest[@]}"
    ;;
  build)
    "${cmd_base[@]}" build "${rest[@]}"
    ;;
  compose)
    "${cmd_base[@]}" "${rest[@]}"
    ;;
  *)
    echo "Unknown or missing command. Use one of: start, stop, status, logs, exec, migrate, services, attach, build, compose."
    exit 1
    ;;
esac