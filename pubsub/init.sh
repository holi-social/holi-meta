#!/bin/bash

# This file contains any project specific shell commands that are needed to set up a working local dev environment
# for this project. It is used by the overall init.sh script in https://gitlab.holi.team/app/holi-meta 

# install the Python virtualenv
pyenv install -s "$(cat .python-version)"
pyenv local "$(cat .python-version)"
direnv allow .
