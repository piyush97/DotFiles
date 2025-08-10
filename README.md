# Piyush's Dotfiles 🚀

Modern macOS development environment with Starship prompt and automated configuration management.

## Features

- **Starship Prompt**: Fast, customizable, cross-shell prompt
- **Modern Shell**: Zsh with Oh My Zsh and Powerlevel10k theme (optional)
- **Enhanced CLI Tools**: bat, eza, fd, fzf, ripgrep, htop, and more
- **Development Ready**: Node.js, Python, Go, Rust environments
- **Code Editors**: Neovim with LSP and VS Code configurations
- **Git Workflow**: Optimized git configuration with useful aliases
- **One-Click Setup**: Automated installation script for new Mac setups

## Quick Start

```bash
# Clone the repository
git clone https://github.com/piyush97/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the installation script
./install.sh

# Or run in interactive mode to choose what to install
./install.sh --interactive
```

## What Gets Installed

### 🛠 Essential Tools
- Homebrew package manager
- Modern CLI replacements (bat, eza, fd, fzf, ripgrep)
- Git with enhanced configuration
- Oh My Zsh with Powerlevel10k theme

### 💻 Development Environment
- **Languages**: Node.js, Python, Go, Rust, Bun
- **Editors**: Neovim (with LSP), VS Code (with extensions)
- **Databases**: PostgreSQL, Redis, SQLite
- **DevOps**: Docker, Kubernetes CLI, Helm, Terraform

### 📱 Applications
- **Browsers**: LibreWolf, Ungoogled Chromium, Firefox
- **Development**: VS Code, Warp Terminal, Postman
- **Utilities**: Raycast, Aerospace, HiddenBar, Stats
- **Fonts**: SF Mono, SF Pro, Hack Nerd Font, Fira Code

### ⚙️ Configurations
- Zsh with custom aliases and functions
- Git with useful aliases and delta diff viewer
- Neovim with modern Lua configuration
- VS Code settings optimized for development
- macOS system preferences optimization

## File Structure

```
dotfiles/
├── install.sh              # Main installation script
├── .zshrc                  # Zsh configuration
├── .gitconfig              # Git configuration
├── .gitignore_global       # Global gitignore
├── .gitmessage            # Git commit template
├── .p10k.zsh              # Powerlevel10k theme config
├── Brewfile               # Homebrew bundle file
├── .config/               # Application configurations
│   ├── starship/          # Starship prompt configuration
│   │   └── starship.toml
│   ├── nvim/              # Neovim configuration
│   ├── aerospace/         # Window manager config
│   ├── alacritty/         # Terminal emulator config
│   ├── warp/              # Warp terminal config
│   ├── git/               # Additional git config
│   └── vscode/            # VS Code settings
└── packages/              # Package lists for reference
    ├── brew_list_current.txt
    ├── brew-cask_list_current.txt
    ├── npm_list_current.txt
    └── pip3_list_current.txt
```

## Manual Setup Steps

After running the installation script, complete these steps:

1. **Configure Powerlevel10k**: Run `p10k configure` to customize your prompt
2. **Add SSH key to GitHub/GitLab**: The script generates an SSH key - add the public key to your Git hosting service
3. **Sign in to applications**: Configure 1Password, Raycast, and other installed apps
4. **Configure Aerospace**: Set up your preferred window management shortcuts
5. **Import browser data**: Sign in and sync your browser profiles

## Customization

### Local Configurations
Create these files to add local/work-specific configurations without modifying the main dotfiles:

- `~/.zshrc.local` - Local zsh configuration
- `~/.zshrc.work` - Work-specific configuration  
- `~/.gitconfig.local` - Local git configuration

### Adding Packages
To add more packages to the installation:

1. Edit `install.sh` 
2. Add packages to the respective arrays:
   - `packages` array for Homebrew CLI tools
   - `casks` array for GUI applications
   - Update other package arrays as needed

## Useful Aliases & Functions

### Git Shortcuts
```bash
g           # git
gst         # git status  
gco         # git checkout
gcb         # git checkout -b
gp          # git push
gl          # git pull
glog        # git log --oneline --graph
```

### Modern CLI Tools
```bash
cat → bat   # Better cat with syntax highlighting
ls → eza    # Better ls with icons
find → fd   # Better find
grep → rg   # Better grep (ripgrep)
top → htop  # Better top
du → dust   # Better du
df → duf    # Better df
```

### Custom Functions
```bash
mkcd <dir>              # Create directory and cd into it
extract <archive>       # Extract various archive formats
weather [city]          # Get weather for city
proj <name>            # Navigate to ~/projects/<name>
```

## Updating

```bash
# Update all packages
update

# Update specific tools
brew update && brew upgrade
npm update -g
pip3 list --outdated --format=freeze | cut -d = -f 1 | xargs -n1 pip3 install -U

# Clean up
cleanup
```

## Troubleshooting

### Common Issues

**Permission Errors**: Make sure you have proper permissions and run with appropriate privileges

**Homebrew Issues**: Try running `brew doctor` to diagnose issues

**Zsh Configuration**: If there are issues, temporarily rename `.zshrc` and source the default configuration

**VS Code Extensions**: Some extensions might fail to install automatically - install them manually through the VS Code interface

### Getting Help

1. Check the console output for specific error messages
2. Review the installation logs
3. Try running individual sections of the install script
4. Create an issue in the repository with details about your system and the error

## Credits

- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zsh theme
- [Homebrew](https://brew.sh/) - Package manager for macOS
- Various CLI tools and their maintainers

---

**Happy Coding!** 🎉
