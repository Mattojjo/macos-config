#!/bin/bash

# Backup and update configuration files from GitHub
# Always fetches latest from remote repository

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Repository configuration
REPO_URL="https://github.com/Mattojjo/macos-config.git"
TEMP_DIR="/tmp/macos-config-update"

# Backup directory with timestamp
BACKUP_DIR="$HOME/.config/backup_$(date +%Y%m%d_%H%M%S)"

# Configuration directories to backup and update
CONFIGS=("nvim" "btop" "zsh")

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        echo -e "${YELLOW}Cleaning up temporary files...${NC}"
        rm -rf "$TEMP_DIR"
    fi
}

# Trap to ensure cleanup runs on exit
trap cleanup EXIT

echo -e "${GREEN}Starting configuration backup and update...${NC}"

# Always clone from remote
echo -e "${YELLOW}Fetching latest configs from GitHub...${NC}"
rm -rf "$TEMP_DIR" 2>/dev/null
git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to clone repository${NC}"
    exit 1
fi
SOURCE_DIR="$TEMP_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}Backup directory created: $BACKUP_DIR${NC}"

# Backup existing configurations
for config in "${CONFIGS[@]}"; do
    if [ -d "$HOME/.config/$config" ]; then
        echo -e "${YELLOW}Backing up ~/.config/$config${NC}"
        cp -r "$HOME/.config/$config" "$BACKUP_DIR/"
    else
        echo -e "${YELLOW}~/.config/$config does not exist, skipping backup${NC}"
    fi
done

# Update configurations from repository
for config in "${CONFIGS[@]}"; do
    if [ -d "$SOURCE_DIR/$config" ]; then
        echo -e "${GREEN}Updating ~/.config/$config from repository${NC}"
        mkdir -p "$HOME/.config/$config"
        cp -r "$SOURCE_DIR/$config/"* "$HOME/.config/$config/"
    else
        echo -e "${RED}Warning: $SOURCE_DIR/$config not found in repository${NC}"
    fi
done

echo -e "${GREEN}Configuration update complete!${NC}"
echo -e "${YELLOW}Backup saved to: $BACKUP_DIR${NC}"