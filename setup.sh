#!/bin/bash

# Configuration
REPO_URL="https://github.com/Mattojjo/macos-config.git"
TEMP_DIR="/tmp/config"
TARGET_DIR="$HOME/.config"
ZSHRC="$HOME/.zshrc"

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# Clone configuration repository
echo "Cloning configuration repository..."
git clone "$REPO_URL" "$TEMP_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Clone failed"
    exit 1
fi

# Install configuration files
echo "Installing configuration files..."
mkdir -p "$TARGET_DIR/zsh"
mkdir -p "$TARGET_DIR/nvim"
mkdir -p "$TARGET_DIR/btop"

cp -r "$TEMP_DIR/zsh/"* "$TARGET_DIR/zsh/" 2>/dev/null || echo "No zsh configs found"
cp -r "$TEMP_DIR/nvim/"* "$TARGET_DIR/nvim/" 2>/dev/null || echo "No nvim configs found"
cp -r "$TEMP_DIR/btop/"* "$TARGET_DIR/btop/" 2>/dev/null || echo "No btop configs found"

# Clean up temporary files
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Configure .zshrc
if [ -f "$ZSHRC" ]; then
    cp "$ZSHRC" "$ZSHRC.backup.$(date +%Y%m%d_%H%M%S)"
fi

if ! grep -q "LOAD MODULAR CONFIGURATIONS" "$ZSHRC" 2>/dev/null; then
    cat >> "$ZSHRC" << 'EOF'
# ============================================
# PROMPT CONFIGURATION
# ============================================
export PROMPT="%F{214}%~%f $ "

# ============================================
# LOAD MODULAR CONFIGURATIONS
# ============================================
# Source all .zsh files from ~/.config/zsh/
for config_file in ~/.config/zsh/*.zsh; do
  [ -f "$config_file" ] && source "$config_file"
done
EOF
    echo ".zshrc configured!"
fi

# INSTALL BREW PACKAGES
if command -v brew &> /dev/null; then
    echo "Installing zsh plugins and tools..."
    brew install eza || echo "Failed to install eza"
    brew install nvim || echo "Failed to install nvim"
    brew install btop || echo "Failed to install btop"
    brew install eyed3 || echo "Failed to install eyed3"
    brew install fastfetch || echo "Failed to install fastfetch"
    brew install zsh-autosuggestions || echo "Failed to install zsh-autosuggestions"
    brew install zsh-syntax-highlighting || echo "Failed to install zsh-syntax-highlighting"
    brew tap teamookla/speedtest
    brew update
    brew install speedtest --force || echo "Failed to install speedtest"
else
    echo "Warning: Homebrew not found. Please install it first."
fi

echo "Setup complete! Restart your terminal or run: source ~/.zshrc"