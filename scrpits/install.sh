#!/bin/bash

SOURCE_DIR="/tmp/config"
TARGET_DIR="$HOME/.config"

echo "Installing configuration files..."
cp -r "$SOURCE_DIR"/* "$TARGET_DIR"/

if [ $? -eq 0 ]; then
    echo "Installation successful!"
else
    echo "Installation failed!"
    exit 1
fi

echo "Cleaning up temporary files..."
rm -rf "$SOURCE_DIR"