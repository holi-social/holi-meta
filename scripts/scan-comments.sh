#!/usr/bin/env bash

# print out the TODO/FIXME/HACK/XXX comments in the codebase, for now it doesn't fail if it finds any
rg --no-heading --with-filename --line-number -e '^\s*(?://|/\*|\*|#|--)\s*(?:TODO|FIXME|HACK|XXX)\b' ||
  true