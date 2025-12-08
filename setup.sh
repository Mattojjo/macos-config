# Configuration
REPO_URL="https://github.com/Mattojjo/macos-config.git"
TEMP_DIR="/tmp/config"
TARGET_DIR="$HOME/.config"

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
    
    echo "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
fi

echo "Setup complete!"