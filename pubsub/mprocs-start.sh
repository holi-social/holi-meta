#!/bin/bash

# This file is used by the mprocs yaml files in https://gitlab.holi.team/app/holi-meta 

set -m
gcloud beta emulators pubsub start --project=holi-dev --host-port=localhost:8085 & ../wait-for-port.sh 8085
eval "$(gcloud beta emulators pubsub env-init)"
. .venv/bin/activate; pip3 install -r requirements.txt
python3 init.py
fg
