#!/bin/bash

# Cross-Platform Config Installer

# Usage: ./install-config.sh [repo-url]

set -e  # Exit on error

# Configuration

REPO_URL=”${1:-https://github.com/Mattojjo/config.git}”
TEMP_DIR=”/tmp/config-install-$$”

# Color output

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
NC=’\033[0m’ # No Color

print_info() { echo -e “${GREEN}[INFO]${NC} $1”; }
print_warn() { echo -e “${YELLOW}[WARN]${NC} $1”; }
print_error() { echo -e “${RED}[ERROR]${NC} $1”; }

# Detect OS

detect_os() {
case “$(uname -s)” in
Darwin*)
echo “macos”
;;
Linux*)
echo “linux”
;;
CYGWIN*|MINGW*|MSYS*)
echo “windows”
;;
*)
echo “unknown”
;;
esac
}

# Get config directory based on OS

get_config_dir() {
local os=$1
case $os in
macos|linux)
echo “$HOME/.config”
;;
windows)
echo “$APPDATA”
;;
*)
echo “$HOME/.config”
;;
esac
}

# Backup existing config

backup_config() {
local config_dir=$1
local backup_dir=”${config_dir}.backup-$(date +%Y%m%d-%H%M%S)”

```
if [ -d "$config_dir" ]; then
    print_info "Backing up existing config to: $backup_dir"
    cp -r "$config_dir" "$backup_dir"
    return 0
fi
return 1
```

}

# Main installation

main() {
print_info “Starting config installation…”

```
# Detect OS
OS=$(detect_os)
print_info "Detected OS: $OS"

# Get appropriate config directory
CONFIG_DIR=$(get_config_dir "$OS")
print_info "Config directory: $CONFIG_DIR"

# Create temp directory
print_info "Creating temporary directory: $TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Clone repository
print_info "Cloning repository from: $REPO_URL"
if ! git clone "$REPO_URL" "$TEMP_DIR"; then
    print_error "Failed to clone repository"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Backup existing config
backup_config "$CONFIG_DIR"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Copy files
print_info "Copying files to $CONFIG_DIR"
cp -r "$TEMP_DIR"/* "$CONFIG_DIR/"

# Cleanup
print_info "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

print_info "✓ Installation complete!"
echo ""
print_warn "Config directory: $CONFIG_DIR"
if [ -d "${CONFIG_DIR}.backup-"* ]; then
    print_warn "Backup created: ${CONFIG_DIR}.backup-*"
fi
```

}

# Run main function

main