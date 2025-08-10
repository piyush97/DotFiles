#!/bin/bash

# Piyush's Mac Setup Script
# Modern macOS setup script for development environment
# Version: 2.0
# Author: Piyush Mehta
# License: MIT

set -euo pipefail  # Exit on error, undefined variable, pipe failure
IFS=$'\n\t'       # Set Internal Field Separator for better security

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
readonly LOG_FILE="${SCRIPT_DIR}/install.log"
readonly DRY_RUN="${DRY_RUN:-false}"
readonly VERBOSE="${VERBOSE:-false}"
readonly FORCE="${FORCE:-false}"

# Colors for output with better organization
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m' # No Color

# Progress indicators
readonly SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
SPINNER_PID=""

# Enhanced logging functions with file output
log_message() {
    local level="$1"
    local message="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Log to console based on verbosity
    if [[ "$VERBOSE" == "true" ]] || [[ "$level" != "DEBUG" ]]; then
        case "$level" in
            INFO)    echo -e "${BLUE}[INFO]${NC} $message" ;;
            SUCCESS) echo -e "${GREEN}[✓]${NC} $message" ;;
            WARNING) echo -e "${YELLOW}[⚠]${NC} $message" ;;
            ERROR)   echo -e "${RED}[✗]${NC} $message" >&2 ;;
            DEBUG)   [[ "$VERBOSE" == "true" ]] && echo -e "${DIM}[DEBUG]${NC} $message" ;;
            *) echo "$message" ;;
        esac
    fi
}

log_info() { log_message "INFO" "$1"; }
log_success() { log_message "SUCCESS" "$1"; }
log_warn() { log_message "WARNING" "$1"; }
log_error() { log_message "ERROR" "$1"; }
log_debug() { log_message "DEBUG" "$1"; }

log_header() {
    local header="$1"
    local width=60
    local padding=$(( (width - ${#header} - 2) / 2 ))
    local line="$(printf '═%.0s' {1..60})"
    
    echo -e "\n${PURPLE}${line}${NC}"
    printf "${PURPLE}║%*s%s%*s║${NC}\n" $padding "" "$header" $padding ""
    echo -e "${PURPLE}${line}${NC}\n"
    
    log_message "HEADER" "$header"
}

# Progress spinner functions
start_spinner() {
    local message="${1:-Processing...}"
    if [[ "$DRY_RUN" != "true" ]]; then
        (
            i=0
            while true; do
                printf "\r${CYAN}[${SPINNER_CHARS:i++%${#SPINNER_CHARS}:1}]${NC} %s" "$message"
                sleep 0.1
            done
        ) &
        SPINNER_PID=$!
    fi
}

stop_spinner() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
        SPINNER_PID=""
        printf "\r%*s\r" "$(tput cols)" ""
    fi
}

# System validation and requirements check
check_requirements() {
    log_header "System Requirements Check"
    
    local errors=0
    
    # Check OS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only (found: $OSTYPE)"
        ((errors++))
    else
        log_success "Operating System: macOS $(sw_vers -productVersion)"
    fi
    
    # Check architecture
    local arch="$(uname -m)"
    if [[ "$arch" == "arm64" ]]; then
        log_info "Architecture: Apple Silicon (ARM64)"
        readonly HOMEBREW_PREFIX="/opt/homebrew"
    elif [[ "$arch" == "x86_64" ]]; then
        log_info "Architecture: Intel (x86_64)"
        readonly HOMEBREW_PREFIX="/usr/local"
    else
        log_warn "Unknown architecture: $arch"
    fi
    
    # Check disk space (require at least 10GB free)
    local free_space=$(df -g / | awk 'NR==2 {print $4}')
    if [[ $free_space -lt 10 ]]; then
        log_warn "Low disk space: ${free_space}GB free (recommend at least 10GB)"
    else
        log_success "Disk space: ${free_space}GB available"
    fi
    
    # Check internet connectivity
    if ! ping -c 1 -t 5 github.com &> /dev/null; then
        log_error "No internet connection detected"
        ((errors++))
    else
        log_success "Internet connection: Active"
    fi
    
    # Check if running with sudo (we shouldn't be)
    if [[ "$EUID" -eq 0 ]]; then
        log_error "Please do not run this script with sudo"
        ((errors++))
    fi
    
    if [[ $errors -gt 0 ]]; then
        log_error "System requirements check failed with $errors error(s)"
        exit 1
    fi
    
    log_success "All system requirements met"
}

# Install Xcode Command Line Tools with better error handling
install_xcode_tools() {
    log_header "Xcode Command Line Tools"
    
    if xcode-select -p &> /dev/null; then
        local xcode_version="$(xcode-select -v 2>&1 | awk '{print $NF}')"
        log_success "Xcode Command Line Tools already installed (version: $xcode_version)"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install Xcode Command Line Tools"
        return 0
    fi
    
    log_info "Installing Xcode Command Line Tools..."
    
    # Attempt automated installation
    if ! xcode-select --install 2>&1 | grep -q "install requested"; then
        # Try alternative installation method
        log_info "Attempting alternative installation method..."
        
        # Touch file to trigger installation
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        
        # Find and install the Command Line Tools package
        local cmd_line_tools=$(softwareupdate -l | 
            grep "\*.*Command Line Tools" | 
            tail -n 1 | 
            awk -F"*" '{print $2}' | 
            sed -e 's/^ *//' | 
            tr -d '\n')
        
        if [[ -n "$cmd_line_tools" ]]; then
            softwareupdate -i "$cmd_line_tools" --verbose
            rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
            log_success "Xcode Command Line Tools installed successfully"
        else
            log_error "Failed to find Xcode Command Line Tools package"
            log_warn "Please install manually from: https://developer.apple.com/download/more/"
            exit 1
        fi
    else
        log_warn "Xcode installation dialog opened. Please complete installation and run this script again."
        exit 1
    fi
}

# Install Homebrew with proper error handling and verification
install_homebrew() {
    log_header "Homebrew Package Manager"
    
    if command -v brew &> /dev/null; then
        local brew_version="$(brew --version | head -n1)"
        log_success "Homebrew already installed: $brew_version"
        
        if [[ "$DRY_RUN" != "true" ]]; then
            log_info "Updating Homebrew..."
            start_spinner "Updating Homebrew packages"
            brew update &>/dev/null
            stop_spinner
            log_success "Homebrew updated"
        fi
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install Homebrew"
        return 0
    fi
    
    log_info "Installing Homebrew..."
    
    # Download and verify installation script
    local install_script="/tmp/homebrew_install.sh"
    if ! curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$install_script"; then
        log_error "Failed to download Homebrew installation script"
        return 1
    fi
    
    # Run installation
    if ! /bin/bash "$install_script"; then
        log_error "Homebrew installation failed"
        rm -f "$install_script"
        return 1
    fi
    
    rm -f "$install_script"
    
    # Configure PATH based on architecture
    local brew_path=""
    if [[ $(uname -m) == 'arm64' ]]; then
        brew_path="/opt/homebrew/bin"
    else
        brew_path="/usr/local/bin"
    fi
    
    # Add to PATH if not already there
    if ! echo "$PATH" | grep -q "$brew_path"; then
        echo "eval \"\$(${brew_path}/brew shellenv)\"" >> ~/.zprofile
        eval "$(${brew_path}/brew shellenv)"
    fi
    
    # Verify installation
    if command -v brew &> /dev/null; then
        log_success "Homebrew installed successfully: $(brew --version | head -n1)"
    else
        log_error "Homebrew installation verification failed"
        return 1
    fi
}

# Package installation with retry logic and error handling
install_package() {
    local package="$1"
    local package_type="${2:-formula}"  # formula or cask
    local max_retries=3
    local retry_count=0
    
    # Check if already installed
    if [[ "$package_type" == "cask" ]]; then
        if brew list --cask "$package" &> /dev/null; then
            log_debug "$package already installed (cask)"
            return 0
        fi
    else
        if brew list "$package" &> /dev/null; then
            log_debug "$package already installed"
            return 0
        fi
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install $package"
        return 0
    fi
    
    # Install with retry logic
    while [[ $retry_count -lt $max_retries ]]; do
        log_debug "Installing $package (attempt $((retry_count + 1))/$max_retries)..."
        
        if [[ "$package_type" == "cask" ]]; then
            if brew install --cask "$package" &>/dev/null; then
                log_success "Installed: $package (cask)"
                return 0
            fi
        else
            if brew install "$package" &>/dev/null; then
                log_success "Installed: $package"
                return 0
            fi
        fi
        
        ((retry_count++))
        if [[ $retry_count -lt $max_retries ]]; then
            log_debug "Retrying installation of $package..."
            sleep 2
        fi
    done
    
    log_warn "Failed to install $package after $max_retries attempts"
    return 1
}

# Install Homebrew packages with parallel processing
install_brew_packages() {
    log_header "Homebrew Packages Installation"
    
    local packages=(
        # Essential tools
        "git"
        "gh"
        "curl"
        "wget"
        "tree"
        "jq"
        "yq"
        
        # Modern CLI tools
        "bat"           # Better cat
        "eza"           # Better ls
        "fd"            # Better find
        "fzf"           # Fuzzy finder
        "ripgrep"       # Better grep
        "htop"          # Better top
        "dust"          # Better du
        "duf"           # Better df
        "procs"         # Better ps
        "delta"         # Better git diff
        
        # Development tools
        "node"
        "npm"
        "yarn"
        "python@3.11"
        "python@3.12"
        "go"
        "rust"
        "bun"
        
        # Editors
        "neovim"
        "vim"
        
        # Databases
        "postgresql@15"
        "redis"
        "sqlite"
        
        # DevOps tools
        "docker"
        "docker-compose"
        "kubernetes-cli"
        "helm"
        "terraform"
        "awscli"
        
        # Other utilities
        "zsh"
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
        "mas"           # Mac App Store CLI
        "tmux"
        "imagemagick"
        "ffmpeg"
        "yt-dlp"
        "tldr"
        "thefuck"
        "z"
    )
    
    local failed_packages=()
    local total=${#packages[@]}
    local current=0
    
    log_info "Installing $total Homebrew packages..."
    
    for package in "${packages[@]}"; do
        ((current++))
        printf "[%3d/%3d] Installing: %-30s" "$current" "$total" "$package"
        
        if install_package "$package" "formula"; then
            printf "\r[%3d/%3d] ${GREEN}[✓]${NC} %-30s\n" "$current" "$total" "$package"
        else
            printf "\r[%3d/%3d] ${RED}[✗]${NC} %-30s\n" "$current" "$total" "$package"
            failed_packages+=("$package")
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warn "Failed to install ${#failed_packages[@]} package(s): ${failed_packages[*]}"
    else
        log_success "All $total Homebrew packages installed successfully"
    fi
}

# Install Homebrew Cask applications
install_brew_casks() {
    log_header "Installing Applications via Homebrew Cask"
    
    local casks=(
        # Browsers
        "librewolf"
        "ungoogled-chromium"
        "firefox"
        
        # Development
        "visual-studio-code"
        "warp"
        "postman"
        "docker"
        "github-desktop"
        
        # Utilities
        "raycast"
        "aerospace"
        "starship"  # Cross-shell prompt
        "hiddenbar"
        "stats"
        "the-unarchiver"
        "keka"
        "cleanmymac"
        
        # Media
        "vlc"
        "spotify"
        "iina"
        
        # Fonts
        "font-sf-mono"
        "font-sf-pro"
        "font-hack-nerd-font"
        "font-fira-code-nerd-font"
        "font-jetbrains-mono-nerd-font"
        "font-source-code-pro"
        
        # Communication
        "discord"
        "slack"
        "telegram"
        "whatsapp"
        
        # Design
        "figma"
        "sketch"
        
        # Security
        "1password"
        "1password-cli"
    )
    
    log_info "Installing ${#casks[@]} applications..."
    for cask in "${casks[@]}"; do
        if brew list --cask "$cask" &> /dev/null; then
            log_success "$cask already installed"
        else
            log_info "Installing $cask..."
            brew install --cask "$cask" || log_warn "Failed to install $cask"
        fi
    done
    
    log_success "All applications installed"
}

# Install Oh My Zsh
install_oh_my_zsh() {
    log_header "Installing Oh My Zsh"
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_success "Oh My Zsh already installed"
    else
        log_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh My Zsh installed"
    fi
    
    # Install Powerlevel10k theme
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ -d "$p10k_dir" ]; then
        log_success "Powerlevel10k already installed"
    else
        log_info "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
        log_success "Powerlevel10k installed"
    fi
}

# Setup dotfiles
setup_dotfiles() {
    log_header "Setting up Dotfiles"
    
    local dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Backup existing dotfiles and configs
    log_info "Backing up existing dotfiles..."
    local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup root level dotfiles
    local root_files=(".zshrc" ".gitconfig" ".gitignore_global" ".gitmessage" ".p10k.zsh")
    for file in "${root_files[@]}"; do
        if [ -f "$HOME/$file" ]; then
            cp -r "$HOME/$file" "$backup_dir/"
            log_info "Backed up $file"
        fi
    done
    
    # Backup .config directory if it exists
    if [ -d "$HOME/.config" ]; then
        cp -r "$HOME/.config" "$backup_dir/"
        log_info "Backed up .config directory"
    fi
    
    # Create necessary directories
    mkdir -p "$HOME/.config"
    
    # Symlink root level dotfiles
    log_info "Creating symlinks for dotfiles..."
    for file in "$dotfiles_dir"/.* ; do
        basename="$(basename "$file")"
        # Skip . and .. and .git and .config
        if [[ "$basename" != "." && "$basename" != ".." && "$basename" != ".git" && "$basename" != ".config" ]]; then
            if [ -f "$file" ]; then
                ln -sf "$file" "$HOME/$basename"
                log_success "Linked $basename"
            fi
        fi
    done
    
    # Symlink .config contents
    log_info "Setting up .config directory..."
    for config_dir in "$dotfiles_dir"/.config/* ; do
        if [ -d "$config_dir" ] || [ -f "$config_dir" ]; then
            basename="$(basename "$config_dir")"
            ln -sf "$config_dir" "$HOME/.config/$basename"
            log_success "Linked .config/$basename"
        fi
    done
    
    # Setup Starship prompt
    if command -v starship &> /dev/null; then
        log_info "Starship is installed, config will be linked"
    else
        log_info "Installing Starship prompt..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
    
    # Setup VS Code settings (if VS Code is installed)
    if command -v code &> /dev/null; then
        local vscode_settings_dir="$HOME/Library/Application Support/Code/User"
        if [ -d "$vscode_settings_dir" ]; then
            if [ -f "$vscode_settings_dir/settings.json" ]; then
                cp "$vscode_settings_dir/settings.json" "$backup_dir/vscode_settings.json"
                log_info "Backed up VS Code settings"
            fi
            if [ -f "$dotfiles_dir/.config/vscode/settings.json" ]; then
                ln -sf "$dotfiles_dir/.config/vscode/settings.json" "$vscode_settings_dir/settings.json"
                log_success "VS Code settings linked"
            fi
        fi
    fi
    
    log_success "Dotfiles setup complete"
}

# Configure macOS settings
configure_macos() {
    log_header "Configuring macOS Settings"
    
    log_info "Configuring system preferences..."
    
    # Show hidden files in Finder
    defaults write com.apple.finder AppleShowAllFiles YES
    
    # Show file extensions in Finder
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    # Disable the "Are you sure you want to open this application?" dialog
    defaults write com.apple.LaunchServices LSQuarantine -bool false
    
    # Set a faster keyboard repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    
    # Show the ~/Library folder
    chflags nohidden ~/Library
    
    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    
    # Enable tap to click for trackpad
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    
    # Set dock to auto-hide
    defaults write com.apple.dock autohide -bool true
    
    # Remove all default dock icons
    defaults write com.apple.dock persistent-apps -array
    
    # Restart affected applications
    killall Finder
    killall Dock
    
    log_success "macOS configuration complete"
}

# Install Node.js packages
install_node_packages() {
    log_header "Installing Global Node.js Packages"
    
    local packages=(
        "@vue/cli"
        "@angular/cli"
        "create-react-app"
        "create-next-app"
        "typescript"
        "ts-node"
        "nodemon"
        "pm2"
        "http-server"
        "live-server"
        "json-server"
        "eslint"
        "prettier"
        "commitizen"
        "semantic-release"
        "netlify-cli"
        "vercel"
        "firebase-tools"
    )
    
    log_info "Installing ${#packages[@]} Node.js packages..."
    for package in "${packages[@]}"; do
        log_info "Installing $package..."
        npm install -g "$package" || log_warn "Failed to install $package"
    done
    
    log_success "Node.js packages installed"
}

# Install Python packages
install_python_packages() {
    log_header "Installing Python Packages"
    
    local packages=(
        "pip"
        "pipenv"
        "poetry"
        "virtualenv"
        "black"
        "flake8"
        "mypy"
        "pytest"
        "jupyter"
        "requests"
        "fastapi"
        "django"
        "flask"
        "pandas"
        "numpy"
        "matplotlib"
        "seaborn"
    )
    
    log_info "Installing ${#packages[@]} Python packages..."
    for package in "${packages[@]}"; do
        log_info "Installing $package..."
        pip3 install "$package" || log_warn "Failed to install $package"
    done
    
    log_success "Python packages installed"
}

# Install VS Code extensions
install_vscode_extensions() {
    log_header "Installing VS Code Extensions"
    
    if ! command -v code &> /dev/null; then
        log_warn "VS Code not found, skipping extension installation"
        return
    fi
    
    local extensions=(
        # Themes
        "GitHub.github-vscode-theme"
        "PKief.material-icon-theme"
        "ms-vscode.vscode-typescript-next"
        
        # Languages
        "ms-python.python"
        "ms-python.black-formatter"
        "golang.Go"
        "rust-lang.rust-analyzer"
        "bradlc.vscode-tailwindcss"
        "ms-vscode.vscode-json"
        
        # Development
        "esbenp.prettier-vscode"
        "dbaeumer.vscode-eslint"
        "eamodio.gitlens"
        "formulahendry.auto-rename-tag"
        "ms-vscode.live-server"
        "ritwickdey.LiveServer"
        "christian-kohler.path-intellisense"
        "formulahendry.code-runner"
        
        # Utilities
        "streetsidesoftware.code-spell-checker"
        "ms-vsliveshare.vsliveshare"
        "gruntfuggly.todo-tree"
        "alefragnani.Bookmarks"
        "ms-vscode.hexeditor"
        
        # Docker & DevOps
        "ms-azuretools.vscode-docker"
        "ms-kubernetes-tools.vscode-kubernetes-tools"
        "HashiCorp.terraform"
        
        # Git
        "donjayamanne.githistory"
        "mhutchie.git-graph"
        
        # Markdown
        "yzhang.markdown-all-in-one"
        "bierner.markdown-mermaid"
    )
    
    log_info "Installing ${#extensions[@]} VS Code extensions..."
    for extension in "${extensions[@]}"; do
        log_info "Installing $extension..."
        code --install-extension "$extension" || log_warn "Failed to install $extension"
    done
    
    log_success "VS Code extensions installed"
}

# Final setup
final_setup() {
    log_header "Final Setup"
    
    # Change default shell to zsh if not already
    if [[ "$SHELL" != "/bin/zsh" && "$SHELL" != "/opt/homebrew/bin/zsh" ]]; then
        log_info "Changing default shell to zsh..."
        chsh -s "$(which zsh)"
        log_success "Default shell changed to zsh"
    fi
    
    # Generate SSH key if it doesn't exist
    if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        log_info "Generating SSH key..."
        read -p "Enter your email for SSH key: " email
        ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
        eval "$(ssh-agent -s)"
        ssh-add "$HOME/.ssh/id_ed25519"
        log_success "SSH key generated"
        log_info "Add this key to GitHub/GitLab:"
        cat "$HOME/.ssh/id_ed25519.pub"
    fi
    
    # Cleanup
    log_info "Cleaning up..."
    brew cleanup
    
    log_success "Setup complete! 🎉"
}

# Print summary
print_summary() {
    log_header "Setup Summary"
    
    echo -e "${GREEN}✅ Installed Applications:${NC}"
    echo "• Homebrew packages and modern CLI tools"
    echo "• Development tools (Node.js, Python, Go, Rust)"
    echo "• Essential applications (browsers, editors, utilities)"
    echo "• Oh My Zsh with Powerlevel10k theme"
    echo ""
    
    echo -e "${YELLOW}⚠️  Manual Steps Required:${NC}"
    echo "1. Configure Powerlevel10k by running: p10k configure"
    echo "2. Add SSH key to GitHub/GitLab accounts"
    echo "3. Sign in to applications and sync settings"
    echo "4. Configure Aerospace window manager"
    echo "5. Set up 1Password and import data"
    echo ""
    
    echo -e "${BLUE}ℹ️  Useful Commands:${NC}"
    echo "• Update everything: brew update && brew upgrade && npm update -g"
    echo "• Cleanup: brew cleanup && npm cache clean --force"
    echo "• Restart terminal or run: source ~/.zshrc"
    echo ""
    
    echo -e "${PURPLE}🎯 Next Steps:${NC}"
    echo "• Restart your terminal"
    echo "• Run 'p10k configure' to setup your prompt"
    echo "• Import your data and settings"
    echo "• Start coding! 🚀"
}

# Main execution
main() {
    log_header "Piyush's Mac Setup Script"
    log_info "Starting automated macOS development environment setup..."
    
    # Check if we should run in interactive mode
    if [[ "$1" == "--interactive" ]]; then
        echo "Select what you want to install:"
        echo "1) Complete setup (recommended)"
        echo "2) Essential tools only"
        echo "3) Development tools only"
        echo "4) Applications only"
        read -p "Choose option [1-4]: " option
        
        case $option in
            2) ESSENTIAL_ONLY=true ;;
            3) DEV_ONLY=true ;;
            4) APPS_ONLY=true ;;
            *) COMPLETE_SETUP=true ;;
        esac
    else
        COMPLETE_SETUP=true
    fi
    
    # Always run these
    check_macos
    install_xcode_tools
    install_homebrew
    
    if [[ "$COMPLETE_SETUP" == true || "$ESSENTIAL_ONLY" == true || "$DEV_ONLY" == true ]]; then
        install_brew_packages
        install_oh_my_zsh
        setup_dotfiles
    fi
    
    if [[ "$COMPLETE_SETUP" == true || "$APPS_ONLY" == true ]]; then
        install_brew_casks
    fi
    
    if [[ "$COMPLETE_SETUP" == true || "$DEV_ONLY" == true ]]; then
        install_node_packages
        install_python_packages
        install_vscode_extensions
    fi
    
    if [[ "$COMPLETE_SETUP" == true ]]; then
        configure_macos
    fi
    
    final_setup
    print_summary
}

# Run the script
main "$@"