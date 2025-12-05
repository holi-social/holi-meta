#!/bin/bash

set -a
source $COMPOSE_DIR/.env.local
source $COMPOSE_DIR/frontends/.env.local
set +a

cd $ROOT_DIR/holi-frontends
yarn install
yarn mobile:dev