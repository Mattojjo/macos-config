#!/bin/bash

REPO_URL="https://github.com/Mattojjo/macos-config.git"
TEMP_DIR="/tmp/config"

echo "Cloning configuration repository..."
git clone "$REPO_URL" "$TEMP_DIR"

if [ $? -eq 0 ]; then
    echo "Clone successful!"
else
    echo "Clone failed!"
    exit 1
fi
