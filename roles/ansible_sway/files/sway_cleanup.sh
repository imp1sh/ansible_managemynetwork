#!/bin/bash

# Sway config cleanup script
# Removes backup files older than the age given in minutes.

DEFAULT_AGE_MINUTES=10080  # 7 days
AGE_MINUTES="${SWAY_CLEANUP_AGE_MINUTES:-$DEFAULT_AGE_MINUTES}"

if [ -d ~/.config/sway ]; then
    find ~/.config/sway/ \( -name "*.backup.*" -o -name "*~" \) -type f -mmin "+${AGE_MINUTES}" -delete 2>/dev/null || true
fi

exit 0
