# Dotfiles Makefile
# Simple commands for managing dotfiles

.PHONY: help install update backup restore link unlink clean doctor health status test

# Default target
help:
	@echo "Dotfiles Management Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  install    - Install dotfiles and packages (default: standard profile)"
	@echo "  minimal    - Install with minimal profile"
	@echo "  complete   - Install with complete profile"
	@echo "  update     - Update all packages and tools"
	@echo "  backup     - Create backup of current dotfiles"
	@echo "  restore    - Restore from backup"
	@echo "  link       - Create symbolic links"
	@echo "  unlink     - Remove symbolic links"
	@echo "  clean      - Clean up old backups and caches"
	@echo "  doctor     - Diagnose and fix issues"
	@echo "  health     - Check system health"
	@echo "  status     - Show installation status"
	@echo "  test       - Run tests"
	@echo ""
	@echo "Examples:"
	@echo "  make install     # Standard installation"
	@echo "  make complete    # Complete installation"
	@echo "  make update      # Update everything"
	@echo "  make doctor      # Fix issues"

# Installation targets
install:
	@./dotfiles.sh install standard

minimal:
	@./dotfiles.sh install minimal

complete:
	@./dotfiles.sh install complete

# Management targets
update:
	@./dotfiles.sh update

backup:
	@./dotfiles.sh backup

restore:
	@./dotfiles.sh restore

link:
	@./dotfiles.sh link

unlink:
	@./dotfiles.sh unlink

clean:
	@./dotfiles.sh clean

# Diagnostic targets
doctor:
	@./dotfiles.sh doctor

health:
	@./dotfiles.sh health

status:
	@./dotfiles.sh status

# Testing
test:
	@echo "Running dotfiles tests..."
	@bash -n install.sh && echo "✓ install.sh syntax valid" || echo "✗ install.sh syntax error"
	@bash -n dotfiles.sh && echo "✓ dotfiles.sh syntax valid" || echo "✗ dotfiles.sh syntax error"
	@test -f install.conf.yaml && echo "✓ Configuration file exists" || echo "✗ Configuration file missing"
	@test -d .config && echo "✓ .config directory exists" || echo "✗ .config directory missing"
	@echo "Tests complete!"

# Quick setup for new machines
quick-setup:
	@echo "Quick Setup - Installing everything..."
	@./install.sh --force
	@./dotfiles.sh link
	@./dotfiles.sh health
	@echo "Quick setup complete! Restart your terminal."

# Development helpers
edit-config:
	@$${EDITOR:-vim} install.conf.yaml

edit-install:
	@$${EDITOR:-vim} install.sh

edit-zsh:
	@$${EDITOR:-vim} .zshrc

edit-starship:
	@$${EDITOR:-vim} .config/starship/starship.toml

# Git helpers
save:
	@git add -A
	@git commit -m "Update dotfiles - $$(date '+%Y-%m-%d %H:%M')"
	@git push

pull:
	@git pull --rebase
	@./dotfiles.sh link
	@echo "Dotfiles updated and linked!"