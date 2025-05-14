#!/usr/bin/env bash

# print out the TODO/FIXME/HACK/XXX comments in the codebase, for now it doesn't fail if it finds any

echo ""
echo "TODO/HACK/XXX comments found in code you might want to address:"

rg --no-heading --with-filename --line-number -e '^\s*(?://|/\*|\*|#|--)\s*(?:TODO|HACK|XXX)\b' || true

echo ""
echo "FIXME comments found in code you might want to address:"

rg --no-heading --with-filename --line-number -e '^\s*(?://|/\*|\*|#|--)\s*(?:FIXME)\b' || true

echo ""
