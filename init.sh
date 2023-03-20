#!/bin/bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m'

message() {
  echo -e >&2 "${GREEN}${1}${NOCOLOR}"
}

fail() {
  echo -e >&2 "${RED}${1}${NOCOLOR}"
  exit 1
}

isAvailable() {
  type -t "$1" >/dev/null 2>&1
}

ensureAvailable() {
  isAvailable "$1" || fail "$1 is not installed. Please install it according to README.md and run $0 again afterwards"
}

brewInstall() {
  brew list $1 &>/dev/null || brew install $1
}

# This script should be idempotent. Any step performed should also work after it has been performed before.
# That way we can re-init at any time and all be on the same spot.

# we need a couple of prerequisites installed, but can't universally install it for everyone because of differing installation methods on different platforms/distros
ensureAvailable yarn
ensureAvailable direnv
ensureAvailable gcloud

# Install Google PubSub emulator
gcloud components list | grep beta > /dev/null || gcloud components install beta
gcloud components list | grep pubsub-emulator > /dev/null || gcloud components install pubsub-emulator

# nvm is oftentimes installed as a function sourced in the shell environment and might not be available in the script subshell
# therefore we try sourcing it here before
# (ignore shellcheck warning:)
# shellcheck source=/dev/null
if [ -f ~/.nvm/nvm.sh ]; then
  message 'sourcing nvm from ~/.nvm'
  . ~/.nvm/nvm.sh || true
elif isAvailable brew; then
  # https://docs.brew.sh/Manpage#--prefix-formula
  BREW_PREFIX=$(brew --prefix nvm)
  if [ -f "$BREW_PREFIX/nvm.sh" ]; then
    message "sourcing nvm from brew ($BREW_PREFIX)"
    . "$BREW_PREFIX/nvm.sh" || true
  fi
fi
isAvailable nvm || isAvailable nodenv || fail "Neither nvm nor nodenv are installed. Please install one of them according to README.md and run $0 again afterwards"

ensureAvailable ory
ensureAvailable emulator
ensureAvailable docker-compose
ensureAvailable deno
ensureAvailable brew

# dependencies we can auto-install
# we want to use mprocs for running the development environments
isAvailable mprocs || yarn global add mprocs

# check out and initialize the repositories
git clone git@gitlab.com:holisticfoundation/holi-frontends.git holi-frontends >/dev/null 2>&1 || true
pushd holi-frontends
direnv allow .
yarn install
# install pre-commit hook via husky
yarn prepare
popd

git clone git@gitlab.com:holisticfoundation/holi-okuna.git holi-okuna >/dev/null 2>&1 || true
pushd holi-okuna
# we need to install some postgis libs for holi-okuna
brewInstall gdal
brewInstall proj
brewInstall geos
if [[ -f /opt/homebrew/lib/libgdal.dylib && -f /opt/homebrew/lib/libgeos_c.dylib && -f /opt/homebrew/lib/libproj.dylib ]]; then
  # MacOS
  [[ -f .envrc.local ]] || cat <<- EOF > .envrc.local
export GDAL_LIBRARY_PATH=/opt/homebrew/lib/libgdal.dylib
export GEOS_LIBRARY_PATH=/opt/homebrew/lib/libgeos_c.dylib
export PROJ_LIBRARY_PATH=/opt/homebrew/lib/libproj.dylib
EOF
elif [[ -f /home/linuxbrew/.linuxbrew/lib/libgdal.so && -f /home/linuxbrew/.linuxbrew/lib/libgeos_c.so && -f /home/linuxbrew/.linuxbrew/lib/libproj.so ]]; then
  # Linux
  [[ -f .envrc.local ]] || cat <<- EOF > .envrc.local
export GDAL_LIBRARY_PATH=/home/linuxbrew/.linuxbrew/lib/libgdal.so
export GEOS_LIBRARY_PATH=/home/linuxbrew/.linuxbrew/lib/libgeos_c.so
export PROJ_LIBRARY_PATH=/home/linuxbrew/.linuxbrew/lib/libproj.so
# if not exported like this, system libs will be used as deps of brew libs
export LD_LIBRARY_PATH=/home/linuxbrew/.linuxbrew/lib/:\$LD_LIBRARY_PATH
EOF
else
  fail "Could not determine how to include the libraries necessary for PostGIS. Please investigate in init.sh."
fi
direnv allow .
popd

git clone git@gitlab.com:holisticfoundation/holi-unified-api.git holi-unified-api >/dev/null 2>&1 || true
pushd holi-unified-api
direnv allow .
yarn install
popd

isAvailable vr || deno install -qAn vr -f https://deno.land/x/velociraptor@1.5.0/cli.ts

git clone git@gitlab.com:holisticfoundation/holi-app-donations.git holi-app-donations >/dev/null 2>&1 || true
pushd holi-app-donations
direnv allow .
popd

git clone git@gitlab.com:holisticfoundation/holi-app-goodnews.git holi-app-goodnews >/dev/null 2>&1 || true
pushd holi-app-goodnews
direnv allow .
popd

git clone git@gitlab.com:holisticfoundation/holi-geo-api.git holi-geo-api >/dev/null 2>&1 || true
pushd holi-geo-api
direnv allow .
popd

git clone git@gitlab.com:holisticfoundation/holi-app-volunteering.git holi-app-volunteering >/dev/null 2>&1 || true
pushd holi-app-volunteering
direnv allow .
popd

# Install dependencies to run Google Pub/Sub locally
cd pubsub

INITIALIZED=false
EXPECTED_PYTHON_VERSION=$(cat .python-version)
ACTUAL_PYTHON_VERSION=$(python3 --version | cut -c 8-)

if [[ "$EXPECTED_PYTHON_VERSION" != "$ACTUAL_PYTHON_VERSION" ]]
then
  echo "The installed python version ($ACTUAL_PYTHON_VERSION) differs from the expected version ($EXPECTED_PYTHON_VERSION)" >&2
  echo "Please see README.md to learn how to set up your local dev environment correctly" >&2
  exit 1
fi

if [ ! -d ".venv" ]
then
  python3 -m venv .venv
  INITIALIZED=true
fi

source .venv/bin/activate

if [ "$INITIALIZED" = true ]
then
  pip install --upgrade pip
  pip install -r requirements.txt
fi

set +x

message "$(cat << EOF
${GREEN}
██████╗  ██████╗ ███╗   ██╗███████╗
██╔══██╗██╔═══██╗████╗  ██║██╔════╝
██║  ██║██║   ██║██╔██╗ ██║█████╗
██║  ██║██║   ██║██║╚██╗██║██╔══╝
██████╔╝╚██████╔╝██║ ╚████║███████╗
╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝

All set up. You can now set up the projects in your IDE and start a development environment.

For starting it, execute \`mprocs\`.
${NOCOLOR}
EOF
)"
