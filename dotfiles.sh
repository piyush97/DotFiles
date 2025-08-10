#!/bin/bash

# Dotfiles Management Script
# A helper utility for managing dotfiles installation, updates, and maintenance
# Version: 1.0
# Author: Piyush Mehta

set -euo pipefail
IFS=$'\n\t'

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/install.conf.yaml"
readonly BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Usage information
usage() {
    cat << EOF
${BOLD}Dotfiles Management Utility${NC}

${BOLD}USAGE:${NC}
    $(basename "$0") [COMMAND] [OPTIONS]

${BOLD}COMMANDS:${NC}
    install [profile]    Install dotfiles with specified profile
                        Profiles: minimal, standard, complete (default: standard)
    
    update              Update all installed packages and tools
    
    backup              Create a backup of current dotfiles
    
    restore [backup]    Restore from a backup directory
    
    health              Run health checks on installed tools
    
    link                Create/update symbolic links for dotfiles
    
    unlink              Remove symbolic links (keeps original files)
    
    clean               Clean up old backups and temporary files
    
    doctor              Diagnose and fix common issues
    
    status              Show installation status

${BOLD}OPTIONS:${NC}
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --dry-run       Show what would be done without making changes
    -f, --force         Force operation without prompts
    --no-backup         Skip backup creation

${BOLD}EXAMPLES:${NC}
    $(basename "$0") install complete    # Full installation
    $(basename "$0") update              # Update everything
    $(basename "$0") backup              # Backup current dotfiles
    $(basename "$0") health              # Check system health
    $(basename "$0") doctor              # Fix common issues

EOF
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

log_header() {
    echo -e "\n${PURPLE}━━━ $1 ━━━${NC}\n"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Parse YAML config file (basic implementation)
parse_yaml() {
    local prefix=$2
    local s='[[:space:]]*'
    local w='[a-zA-Z0-9_]*'
    local fs=$(echo @|tr @ '\034')
    
    sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
    awk -F$fs '{
        indent = length($1)/2;
        vname[indent] = $2;
        for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
        }
    }'
}

# Install command
cmd_install() {
    local profile="${1:-standard}"
    
    log_header "Installing Dotfiles (Profile: $profile)"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    # Run main installation script
    if [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
        log_info "Running installation script..."
        bash "${SCRIPT_DIR}/install.sh" --profile "$profile"
    else
        log_error "Installation script not found"
        exit 1
    fi
    
    log_success "Installation complete!"
}

# Update command
cmd_update() {
    log_header "Updating Packages and Tools"
    
    # Update Homebrew
    if command_exists brew; then
        log_info "Updating Homebrew..."
        brew update
        brew upgrade
        brew cleanup
        log_success "Homebrew updated"
    fi
    
    # Update npm packages
    if command_exists npm; then
        log_info "Updating npm packages..."
        npm update -g
        log_success "npm packages updated"
    fi
    
    # Update pip packages
    if command_exists pip3; then
        log_info "Updating pip packages..."
        pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U 2>/dev/null || true
        log_success "pip packages updated"
    fi
    
    # Update Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Updating Oh My Zsh..."
        (cd "$HOME/.oh-my-zsh" && git pull --rebase --stat origin master)
        log_success "Oh My Zsh updated"
    fi
    
    log_success "All updates complete!"
}

# Backup command
cmd_backup() {
    log_header "Creating Dotfiles Backup"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup dotfiles
    local dotfiles=(".zshrc" ".gitconfig" ".gitignore_global" ".p10k.zsh" ".gitmessage")
    for file in "${dotfiles[@]}"; do
        if [[ -f "$HOME/$file" ]]; then
            cp "$HOME/$file" "$BACKUP_DIR/"
            log_success "Backed up $file"
        fi
    done
    
    # Backup .config directory
    if [[ -d "$HOME/.config" ]]; then
        cp -r "$HOME/.config" "$BACKUP_DIR/"
        log_success "Backed up .config directory"
    fi
    
    log_success "Backup created at: $BACKUP_DIR"
}

# Restore command
cmd_restore() {
    local backup_dir="${1:-}"
    
    if [[ -z "$backup_dir" ]]; then
        # List available backups
        log_header "Available Backups"
        ls -la "$HOME"/.dotfiles_backup_* 2>/dev/null || {
            log_warn "No backups found"
            exit 1
        }
        echo
        read -p "Enter backup directory name: " backup_dir
    fi
    
    if [[ ! -d "$HOME/$backup_dir" ]]; then
        log_error "Backup directory not found: $HOME/$backup_dir"
        exit 1
    fi
    
    log_header "Restoring from Backup"
    
    # Restore files
    cp -r "$HOME/$backup_dir"/* "$HOME/"
    
    log_success "Restored from $backup_dir"
}

# Health check command
cmd_health() {
    log_header "System Health Check"
    
    local checks_passed=0
    local checks_failed=0
    
    # Define health checks
    declare -a checks=(
        "brew:Homebrew"
        "git:Git"
        "starship:Starship Prompt"
        "node:Node.js"
        "python3:Python"
        "code:VS Code"
        "nvim:Neovim"
    )
    
    for check in "${checks[@]}"; do
        IFS=':' read -r cmd name <<< "$check"
        if command_exists "$cmd"; then
            version=$($cmd --version 2>&1 | head -n1)
            log_success "$name: $version"
            ((checks_passed++))
        else
            log_warn "$name: Not installed"
            ((checks_failed++))
        fi
    done
    
    echo
    log_info "Health check complete: $checks_passed passed, $checks_failed missing"
    
    if [[ $checks_failed -gt 0 ]]; then
        log_warn "Run '$(basename "$0") doctor' to fix issues"
    fi
}

# Link command
cmd_link() {
    log_header "Creating Symbolic Links"
    
    local dotfiles_dir="$SCRIPT_DIR"
    
    # Link dotfiles
    for file in "$dotfiles_dir"/.*; do
        basename="$(basename "$file")"
        if [[ "$basename" != "." && "$basename" != ".." && "$basename" != ".git" && "$basename" != ".config" ]]; then
            if [[ -f "$file" ]]; then
                ln -sf "$file" "$HOME/$basename"
                log_success "Linked $basename"
            fi
        fi
    done
    
    # Link .config contents
    mkdir -p "$HOME/.config"
    for config_dir in "$dotfiles_dir"/.config/*; do
        if [[ -d "$config_dir" ]] || [[ -f "$config_dir" ]]; then
            basename="$(basename "$config_dir")"
            ln -sf "$config_dir" "$HOME/.config/$basename"
            log_success "Linked .config/$basename"
        fi
    done
    
    log_success "All symbolic links created"
}

# Unlink command
cmd_unlink() {
    log_header "Removing Symbolic Links"
    
    local dotfiles_dir="$SCRIPT_DIR"
    
    # Remove dotfile links
    for file in "$dotfiles_dir"/.*; do
        basename="$(basename "$file")"
        link_path="$HOME/$basename"
        if [[ -L "$link_path" ]]; then
            rm "$link_path"
            log_success "Removed link: $basename"
        fi
    done
    
    # Remove .config links
    for config_dir in "$dotfiles_dir"/.config/*; do
        basename="$(basename "$config_dir")"
        link_path="$HOME/.config/$basename"
        if [[ -L "$link_path" ]]; then
            rm "$link_path"
            log_success "Removed link: .config/$basename"
        fi
    done
    
    log_success "All symbolic links removed"
}

# Clean command
cmd_clean() {
    log_header "Cleaning Up"
    
    # Clean old backups (keep last 5)
    local backup_count=$(ls -d "$HOME"/.dotfiles_backup_* 2>/dev/null | wc -l)
    if [[ $backup_count -gt 5 ]]; then
        log_info "Removing old backups (keeping last 5)..."
        ls -dt "$HOME"/.dotfiles_backup_* | tail -n +6 | xargs rm -rf
        log_success "Old backups removed"
    fi
    
    # Clean Homebrew
    if command_exists brew; then
        log_info "Cleaning Homebrew cache..."
        brew cleanup -s
        log_success "Homebrew cache cleaned"
    fi
    
    # Clean npm cache
    if command_exists npm; then
        log_info "Cleaning npm cache..."
        npm cache clean --force
        log_success "npm cache cleaned"
    fi
    
    log_success "Cleanup complete"
}

# Doctor command
cmd_doctor() {
    log_header "Dotfiles Doctor"
    
    local issues_fixed=0
    
    # Check and fix Homebrew
    if ! command_exists brew; then
        log_warn "Homebrew not installed"
        read -p "Install Homebrew? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            ((issues_fixed++))
        fi
    fi
    
    # Check and fix symbolic links
    log_info "Checking symbolic links..."
    local broken_links=0
    for link in "$HOME"/.* "$HOME"/.config/*; do
        if [[ -L "$link" ]] && [[ ! -e "$link" ]]; then
            log_warn "Broken link: $link"
            ((broken_links++))
        fi
    done
    
    if [[ $broken_links -gt 0 ]]; then
        read -p "Fix broken links? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cmd_link
            ((issues_fixed++))
        fi
    fi
    
    # Check shell configuration
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_warn "Default shell is not zsh"
        read -p "Change default shell to zsh? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            chsh -s "$(which zsh)"
            ((issues_fixed++))
        fi
    fi
    
    if [[ $issues_fixed -gt 0 ]]; then
        log_success "Fixed $issues_fixed issue(s)"
    else
        log_success "No issues found!"
    fi
}

# Status command
cmd_status() {
    log_header "Dotfiles Status"
    
    # Git status
    if [[ -d "${SCRIPT_DIR}/.git" ]]; then
        log_info "Repository status:"
        (cd "$SCRIPT_DIR" && git status --short --branch)
    fi
    
    echo
    
    # Installation status
    log_info "Installation status:"
    cmd_health
    
    echo
    
    # Link status
    log_info "Symbolic links:"
    local link_count=0
    for link in "$HOME"/.* "$HOME"/.config/*; do
        if [[ -L "$link" ]]; then
            ((link_count++))
        fi
    done
    log_success "$link_count symbolic links active"
}

# Main script logic
main() {
    local command="${1:-}"
    shift || true
    
    case "$command" in
        install)
            cmd_install "$@"
            ;;
        update)
            cmd_update "$@"
            ;;
        backup)
            cmd_backup "$@"
            ;;
        restore)
            cmd_restore "$@"
            ;;
        health)
            cmd_health "$@"
            ;;
        link)
            cmd_link "$@"
            ;;
        unlink)
            cmd_unlink "$@"
            ;;
        clean)
            cmd_clean "$@"
            ;;
        doctor)
            cmd_doctor "$@"
            ;;
        status)
            cmd_status "$@"
            ;;
        -h|--help|help|"")
            usage
            exit 0
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"