#!/bin/bash
set -e

# Generate the sygnal configuration file from the template
python3 -c "import os,sys; sys.stdout.write(os.path.expandvars(open('/data/sygnal.yaml.template').read()))" > /data/sygnal.yaml

exec "$@"