#!/bin/sh
set -e

# Install dependencies on start or restart to ensure dependencies are up-to-date
yarn install

exec "$@"