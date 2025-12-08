
# MacOs
### The following comand will:
1. Clone the Repo
2. Copy all of its content to `~/.config/` path (Make sure to BackUp current configs)
3. Loads configuration to the `.zshrc` file
3. Then cleanup itself by removing the repo directory
```
curl -fsSL https://raw.githubusercontent.com/Mattojjo/config/main/setup.sh | bash
```

### Been here before
Clones and overrides files in `~/.config`, not configurations loaded

```
git clone https://github.com/Mattojjo/config.git /tmp/config && cp -r /tmp/config/* ~/.config/ && rm -rf /tmp/configs
```