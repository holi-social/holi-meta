#!/bin/bash

set -a
source $COMPOSE_DIR/.env
source $COMPOSE_DIR/frontends/.env
set +a

cd $ROOT_DIR/holi-frontends
yarn install
yarn mobile:dev