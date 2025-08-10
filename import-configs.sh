#!/bin/bash

# Script to import configs from ~/.config/ to dotfiles repository
# Safe configs only - no sensitive data

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Source and destination
readonly SOURCE_DIR="$HOME/.config"
readonly DEST_DIR="$(pwd)/.config"

echo -e "${BLUE}Config Import Utility${NC}"
echo -e "${BLUE}=====================${NC}\n"

# List of common safe configs to import
declare -a SAFE_CONFIGS=(
    "alacritty"      # Terminal emulator
    "bat"            # Better cat
    "btop"           # System monitor
    "fish"           # Fish shell
    "gh"             # GitHub CLI
    "git"            # Git configs
    "htop"           # System monitor
    "karabiner"      # Keyboard customizer
    "kitty"          # Terminal emulator
    "lazygit"        # Git UI
    "lsd"            # Better ls
    "mc"             # Midnight Commander
    "neofetch"       # System info
    "nvim"           # Neovim
    "raycast"        # Launcher
    "starship"       # Prompt (already have)
    "tmux"           # Terminal multiplexer
    "warp"           # Warp terminal
    "wezterm"        # Terminal emulator
    "yabai"          # Window manager
    "zellij"         # Terminal workspace
    "aerospace"      # Window manager
)

# Configs to always skip (contain sensitive data)
declare -a SKIP_CONFIGS=(
    "1Password"
    "github-copilot"
    "hub"
    "op"
    "gcloud"
    "aws"
    "azure"
    "docker"
    "kubectl"
)

echo -e "${YELLOW}Scanning ~/.config/ directory...${NC}\n"

# Check what configs exist
found_configs=()
for config in "$SOURCE_DIR"/*; do
    if [[ -d "$config" ]] || [[ -f "$config" ]]; then
        basename=$(basename "$config")
        
        # Skip if in skip list
        skip=false
        for skip_item in "${SKIP_CONFIGS[@]}"; do
            if [[ "$basename" == "$skip_item" ]]; then
                skip=true
                break
            fi
        done
        
        if [[ "$skip" == "false" ]]; then
            found_configs+=("$basename")
        fi
    fi
done

if [[ ${#found_configs[@]} -eq 0 ]]; then
    echo -e "${RED}No config directories found in ~/.config/${NC}"
    exit 1
fi

echo -e "${GREEN}Found ${#found_configs[@]} config directories:${NC}"
printf '%s\n' "${found_configs[@]}" | column

echo -e "\n${YELLOW}Select configs to import:${NC}"
echo "1) Import all safe configs (recommended)"
echo "2) Import only common configs"
echo "3) Select individually"
echo "4) Cancel"

read -p "Choice [1-4]: " choice

case $choice in
    1)
        # Import all found configs except sensitive ones
        configs_to_import=("${found_configs[@]}")
        ;;
    2)
        # Import only configs in SAFE_CONFIGS that exist
        configs_to_import=()
        for config in "${SAFE_CONFIGS[@]}"; do
            if [[ -d "$SOURCE_DIR/$config" ]] || [[ -f "$SOURCE_DIR/$config" ]]; then
                configs_to_import+=("$config")
            fi
        done
        ;;
    3)
        # Interactive selection
        configs_to_import=()
        for config in "${found_configs[@]}"; do
            read -p "Import $config? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                configs_to_import+=("$config")
            fi
        done
        ;;
    4)
        echo "Cancelled"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

if [[ ${#configs_to_import[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No configs selected for import${NC}"
    exit 0
fi

echo -e "\n${BLUE}Importing ${#configs_to_import[@]} configs...${NC}"

# Create destination directory if needed
mkdir -p "$DEST_DIR"

# Import selected configs
imported=0
skipped=0
for config in "${configs_to_import[@]}"; do
    source_path="$SOURCE_DIR/$config"
    dest_path="$DEST_DIR/$config"
    
    # Check if already exists in repo
    if [[ -e "$dest_path" ]]; then
        echo -e "${YELLOW}⚠ $config already exists, skipping${NC}"
        ((skipped++))
        continue
    fi
    
    # Copy config
    if [[ -d "$source_path" ]]; then
        # Directory - copy recursively
        cp -r "$source_path" "$dest_path"
        echo -e "${GREEN}✓ Imported directory: $config${NC}"
    elif [[ -f "$source_path" ]]; then
        # File - copy directly
        cp "$source_path" "$dest_path"
        echo -e "${GREEN}✓ Imported file: $config${NC}"
    else
        echo -e "${RED}✗ Skipped (unknown type): $config${NC}"
        ((skipped++))
        continue
    fi
    
    ((imported++))
    
    # Clean sensitive data if any
    if [[ -d "$dest_path" ]]; then
        # Remove any .git directories
        find "$dest_path" -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true
        
        # Remove cache directories
        find "$dest_path" -name "cache" -type d -exec rm -rf {} + 2>/dev/null || true
        find "$dest_path" -name "Cache" -type d -exec rm -rf {} + 2>/dev/null || true
        
        # Remove log files
        find "$dest_path" -name "*.log" -type f -delete 2>/dev/null || true
        
        # Remove temporary files
        find "$dest_path" -name "*.tmp" -type f -delete 2>/dev/null || true
        find "$dest_path" -name "*.swp" -type f -delete 2>/dev/null || true
    fi
done

echo -e "\n${GREEN}Import complete!${NC}"
echo -e "  Imported: $imported"
echo -e "  Skipped: $skipped"

# Update .gitignore if needed
echo -e "\n${BLUE}Updating .gitignore...${NC}"
for config in "${configs_to_import[@]}"; do
    # Add cache/sensitive patterns for each config
    echo -e "\n# $config specific ignores" >> .gitignore
    echo ".config/$config/cache/" >> .gitignore
    echo ".config/$config/Cache/" >> .gitignore
    echo ".config/$config/*.log" >> .gitignore
    echo ".config/$config/*.tmp" >> .gitignore
done

echo -e "${GREEN}✓ Updated .gitignore${NC}"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Review imported configs for sensitive data"
echo "2. Run: git status to see changes"
echo "3. Run: git add .config/<config-name> for each config"
echo "4. Commit with meaningful messages"
echo "5. Update documentation if needed"