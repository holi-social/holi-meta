#!/usr/bin/env bash

# Only print echos if `rg --quiet $RG_ARGS_TODO` returns with exit code 0

# Define regex patterns
TODO_PATTERN='^\s*(?://|/\*|\*|#|--)\s*(?:TODO|HACK|XXX)\b'
FIXME_PATTERN='^\s*(?://|/\*|\*|#|--)\s*(?:FIXME)\b'

# First run a quiet check to see if any TODOs exist
if rg --quiet --regexp=$TODO_PATTERN; then
    echo ""
    echo "TODO/HACK/XXX comments found in code you might want to address:"
    echo ""
    # Run the actual search with details
    rg --no-heading --with-filename --line-number -e $TODO_PATTERN || true
    echo ""
fi

# First run a quiet check to see if any FIXMEs exist
if rg --quiet --regexp=$FIXME_PATTERN; then
    echo ""
    echo "FIXME comments found in code you might want to address:"
    echo ""
    # Run the actual search with details
    rg --no-heading --with-filename --line-number -e $FIXME_PATTERN || true
    echo ""
fi
