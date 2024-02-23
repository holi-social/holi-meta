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
  brew list "$1" &>/dev/null || brew install "$1"
}

checkoutAndPrepare() {
  message "Preparing $2 ---------------------------------------------------------"
  git clone "$1" "$2" >/dev/null 2>&1 || true
  pushd "$2"
  direnv allow .
  eval "$(direnv export bash)"
  # install git hooks via husky
  husky install
  [ -x ./init.sh ] && ./init.sh
  popd
}

# This script should be idempotent. Any step performed should also work after it has been performed before.
# That way we can re-init at any time and all be on the same spot.

# we need a couple of prerequisites installed, but can't universally install it for everyone because of differing installation methods on different platforms/distros
#
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
ensureAvailable yarn
ensureAvailable direnv
ensureAvailable gcloud

# Install Google PubSub emulator
# some commands in the following chain of commands are supposed to fail, therefore we suspend the pipefail option temporarily
set +o pipefail
# first, update all components for easy filtering later
yes | gcloud components update || true
gcloud components list --filter=state.name=Installed | grep beta > /dev/null || yes | gcloud components install beta
gcloud components list --filter=state.name=Installed | grep pubsub-emulator > /dev/null || yes | gcloud components install pubsub-emulator
set -o pipefail


ensureAvailable ory
ensureAvailable docker
ensureAvailable deno
ensureAvailable brew
ensureAvailable pyenv
ensureAvailable ffmpeg # needed by okuna
brewInstall libmagic # needed by okuna, missing on mac, we just install it independent of OS

# dependencies we can auto-install
# install velociraptor for deno projects
isAvailable vr || deno install -qAn vr -f https://deno.land/x/velociraptor@1.5.0/cli.ts
# we want to use mprocs for running the development environments
isAvailable mprocs || yarn global add mprocs
# we want to use husky for pre-commit hooks
isAvailable husky || yarn global add husky
# in husky pre-commit hooks, we're using gitleaks for secret detection
brewInstall gitleaks

# check out and initialize the repositories
checkoutAndPrepare git@gitlab.holi.team:app/holi-frontends.git holi-frontends
checkoutAndPrepare git@gitlab.holi.team:app/holi-okuna.git holi-okuna
checkoutAndPrepare git@gitlab.holi.team:app/holi-unified-api.git holi-unified-api
checkoutAndPrepare git@gitlab.holi.team:app/app.gitlab-pages.holi.team app.gitlab-pages.holi.team
checkoutAndPrepare git@gitlab.holi.team:app/holi-app-donations.git holi-app-donations
checkoutAndPrepare git@gitlab.holi.team:app/holi-app-goodnews.git holi-app-goodnews
checkoutAndPrepare git@gitlab.holi.team:app/holi-geo-api.git holi-geo-api
checkoutAndPrepare git@gitlab.holi.team:app/holi-app-volunteering.git holi-app-volunteering
checkoutAndPrepare git@gitlab.holi.team:app/holi-notifications.git holi-notifications
checkoutAndPrepare git@gitlab.holi.team:app/holi-tracking-endpoint.git holi-tracking-endpoint
checkoutAndPrepare git@gitlab.holi.team:app/holi-chat-server.git holi-chat-server
checkoutAndPrepare git@gitlab.holi.team:app/holi-ocis.git holi-ocis
checkoutAndPrepare git@gitlab.holi.team:app/holi-meet.git holi-meet
checkoutAndPrepare git@gitlab.holi.team:app/holi-ocis-integration.git holi-ocis-integration
checkoutAndPrepare git@gitlab.holi.team:app/holi-chat-integration.git holi-chat-integration

# these are technically not used in a local development environment, but they
# make use of common definitions from holi-meta. If you want to check them out,
# then use `./init.sh full`
if [ "${1-default}" = "full" ]; then
  checkoutAndPrepare git@gitlab.holi.team:app/holi-infra.git holi-infra
  checkoutAndPrepare git@gitlab.holi.team:app/holi-docker.git holi-docker
  checkoutAndPrepare git@gitlab.holi.team:app/holi-load-testing.git holi-load-testing
fi

# Install dependencies to run Google Pub/Sub locally
pushd pubsub
[ -x ./init.sh ] && ./init.sh
eval "$(direnv export bash)"
popd

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
