#!/bin/bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

isAvailable() {
    type -t "$1" >/dev/null 2>&1
}

ensureAvailable() {
    isAvailable "$1" || { echo >&2 "$1 is not installed. Please install it according to README.md and run $0 again afterwards"; exit 1; }
}

# This script should be idempotent. Any step performed should also work after it has been performed before.
# That way we can re-init at any time and all be on the same spot.

# we need a couple of prerequisites installed, but can't universally install it for everyone because of differing installation methods on different platforms/distros
ensureAvailable yarn
ensureAvailable direnv

# nvm is oftentimes installed as a function sourced in the shell environment and might not be available in the script subshell
# therefore we try sourcing it here before
# (ignore shellcheck warning:)
# shellcheck source=/dev/null
if [ -f ~/.nvm/nvm.sh ]; then
  echo 'sourcing nvm from ~/.nvm'
  . ~/.nvm/nvm.sh || true
elif type -t brew; then
  # https://docs.brew.sh/Manpage#--prefix-formula
  BREW_PREFIX=$(brew --prefix nvm)
  if [ -f "$BREW_PREFIX/nvm.sh" ]; then
    echo "sourcing nvm from brew ($BREW_PREFIX)"
    . "$BREW_PREFIX/nvm.sh" || true
  fi
fi
isAvailable nvm || isAvailable nodenv || { echo >&2 "Neither nvm nor nodenv are installed. Please install one of them according to README.md and run $0 again afterwards"; exit 1; }

ensureAvailable ory
ensureAvailable emulator
ensureAvailable docker-compose
ensureAvailable deno

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

cat << EOF

██████╗  ██████╗ ███╗   ██╗███████╗
██╔══██╗██╔═══██╗████╗  ██║██╔════╝
██║  ██║██║   ██║██╔██╗ ██║█████╗
██║  ██║██║   ██║██║╚██╗██║██╔══╝
██████╔╝╚██████╔╝██║ ╚████║███████╗
╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝

All set up. You can now set up the projects in your IDE and start a development environment.

For starting it, execute \`mprocs\`.
EOF
