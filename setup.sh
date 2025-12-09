# Configuration
REPO_URL="https://github.com/Mattojjo/macos-config.git"
TEMP_DIR="/tmp/config"
TARGET_DIR="$HOME/.config"
ZSHRC="$HOME/.zshrc"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're running from a local clone (scripts dir exists)
if [ -d "$SCRIPT_DIR/scripts" ]; then
    echo "Running from local repository..."
    
    bash "$SCRIPT_DIR/scripts/clone.sh"
    if [ $? -ne 0 ]; then
        echo "Error: Clone failed"
        exit 1
    fi
    
    bash "$SCRIPT_DIR/scripts/install.sh"
    if [ $? -ne 0 ]; then
        echo "Error: Install failed"
        exit 1
    fi
else
    # Running standalone (via curl)
    echo "Running standalone setup..."
    
    echo "Cloning configuration repository..."
    git clone "$REPO_URL" "$TEMP_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Clone failed"
        exit 1
    fi
    
    echo "Installing configuration files..."
    cp -r "$TEMP_DIR"/* "$TARGET_DIR"/
    if [ $? -ne 0 ]; then
        echo "Error: Install failed"
        exit 1
    fi

    echo "Writing zshrc"

    
    echo "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
fi

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
    echo "Installing zsh plugins..."
    brew install eza # Modern replacement for 'ls'
    brew install nvim # Neovim
    brew insatll eye-d3 # Eye-D3 for managing ID3 tags in audio files
    brew insatll fastfetch # FastFetch for system information
    brew install zsh-autosuggestions
    brew install zsh-syntax-highlighting
else
    echo "Warning: Homebrew not found. Please install it first."
fi


echo "Setup complete!"