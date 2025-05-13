#!/usr/bin/env bash

# check for the presence of gitleaks hooks in the .pre-commit-config.yaml file.
rg --no-heading --with-filename --line-number -e '^\s*-\s+id:\s*gitleaks\b' -q .pre-commit-config.yaml ||
  echo 'no gitleaks hook found in .pre-commit-config.yaml'