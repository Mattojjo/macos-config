
# 🍎 macOS Config

My personal dotfiles and configuration for a fresh macOS setup. Includes configs for Neovim, Zsh, and btop.

## 📦 What's Included

| Config | Description |
|--------|-------------|
| `nvim/` | Neovim config with Lazy.nvim, Monokai Pro theme, and more |
| `zsh/` | Modular Zsh configuration (aliases, functions, plugins) |
| `btop/` | btop system monitor configuration |

## 🚀 Quick Start

### Fresh Install
Installs Homebrew packages and copies all configuration files:

```bash
curl -fsSL https://raw.githubusercontent.com/Mattojjo/macos-config/main/setup.sh | bash
```

### Update Only
Updates config files without reinstalling Homebrew packages:

```bash
curl -fsSL https://raw.githubusercontent.com/Mattojjo/macos-config/main/update.sh | bash
```

## 🍺 Homebrew Packages

The setup script installs:
- `nvim` - Neovim editor
- `btop` - System monitor
- `eza` - Modern ls replacement
- `fastfetch` - System info display
- `eyed3` - MP3 metadata editor
- `zsh-autosuggestions` - Zsh plugin
- `zsh-syntax-highlighting` - Zsh plugin
- `speedtetst` - Speed test by Ookla

## 📁 Installation Paths

Configs are installed to `~/.config/`:
```
~/.config/
├── nvim/
├── zsh/
└── btop/
```

## 🔄 Backups

The update script automatically creates timestamped backups at:
```
~/.config/backup_YYYYMMDD_HHMMSS/
```
