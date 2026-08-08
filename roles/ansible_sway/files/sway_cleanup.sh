#!/bin/bash

# Sway config cleanup script
# Removes backup files older than specified age in minutes

set -e

# Default values
DEFAULT_AGE_MINUTES=2880  # 2 days
AGE_MINUTES=${SWAY_CLEANUP_AGE_MINUTES:-$DEFAULT_AGE_MINUTES}

# Ensure the local bin directory exists
mkdir -p ~/.local/bin

# Find and remove old backup files (only if the sway config directory exists)
if [ -d ~/.config/sway ]; then
    find ~/.config/sway/ -name "*.backup.*" -type f -mmin +$AGE_MINUTES -delete 2>/dev/null || true
fi

exit 0