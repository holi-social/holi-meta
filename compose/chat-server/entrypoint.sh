#!/bin/bash
set -e

# Generate the homeserver configuration file from the template
# python3 -c "import os,sys; sys.stdout.write(os.path.expandvars(open('/data/homeserver.yaml.template').read()))" > /data/homeserver.yaml

python3 << 'PYCODE' > /data/homeserver.yaml
import os, sys
sys.stdout.write(os.path.expandvars(open('/data/homeserver.yaml.template').read()))
PYCODE

exec "$@"