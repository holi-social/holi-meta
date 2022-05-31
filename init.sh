#!/bin/bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

isInstalled() {
    command -v "$1" >/dev/null 2>&1
}

ensureInstalled() {
    isInstalled "$1" || { echo >&2 "$1 is not installed. Please install it according to README.md and run $0 again afterwards"; exit 1; }
}

# This script should be idempotent. Any step performed should also work after it has been performed before.
# That way we can re-init at any time and all be on the same spot.

# we need a couple of prerequisites installed, but can't universally install it for everyone because of differing installation methods on different platforms/distros
ensureInstalled yarn
ensureInstalled direnv
isInstalled nvm || isInstalled nodenv || { echo >&2 "Neither nvm nor nodenv are installed. Please install one of them according to README.md and run $0 again afterwards"; exit 1; }
ensureInstalled ory
ensureInstalled emulator

# dependencies we can auto-install
# jest for running tests, unsure whether needed
# isInstalled jest || yarn global add jest-cli
# we want to use mprocs for running the development environments
isInstalled mprocs || yarn global add mprocs

# check out and initialize the repositories
git clone git@gitlab.com:holisticfoundation/holi-frontends.git holi-frontends >/dev/null 2>&1 || true
pushd holi-frontends
direnv allow .
yarn install
popd

git clone git@gitlab.com:holisticfoundation/holi-okuna.git holi-okuna >/dev/null 2>&1 || true
pushd holi-okuna
direnv allow .
popd

echo "All set up. You can now set up the projects in your IDE and start a development environment."
echo "For starting it, execute \`mprocs\`"