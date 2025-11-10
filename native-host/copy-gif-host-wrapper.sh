#!/bin/bash
# Wrapper script to ensure Python can be found
exec /opt/homebrew/opt/python@3.12/libexec/bin/python3 "$(dirname "$0")/copy-gif-host.py" "$@"
