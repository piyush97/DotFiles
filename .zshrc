# Piyush's Modern ZSH Configuration
# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme configuration
ZSH_THEME="powerlevel10k/powerlevel10k"

# History configuration
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt HIST_BEEP

# Plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  brew
  npm
  node
  yarn
  docker
  kubectl
  gh
  fzf
  web-search
  z
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ===== ENVIRONMENT VARIABLES =====
export EDITOR='code'
export BROWSER='librewolf'
export TERMINAL='warp'

# Language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Path configuration
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Node version manager (if using n or nvm)
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"

# Go configuration
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"

# ===== ALIASES =====
# General
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch -a'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gf='git fetch'
alias gl='git pull'
alias gp='git push'
alias gst='git status'
alias glog='git log --oneline --decorate --graph'
alias glogfull='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'

# Modern CLI tools
alias cat='bat'
alias find='fd'
alias ls='eza --icons'
alias ll='eza -alF --icons'
alias la='eza -a --icons'
alias tree='eza --tree --icons'
alias du='dust'
alias df='duf'
alias top='htop'
alias ps='procs'

# Docker
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dexec='docker exec -it'

# Kubernetes
alias k='kubectl'
alias kns='kubectl config set-context --current --namespace'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'

# Development
alias c='code'
alias v='nvim'
alias vim='nvim'
alias py='python3'
alias pip='pip3'
alias serve='python3 -m http.server'
alias jsonpp='python3 -m json.tool'

# Network
alias myip='curl ipinfo.io/ip'
alias localip='ipconfig getifaddr en0'
alias ports='netstat -tulanp'

# System
alias reload='source ~/.zshrc'
alias zshconfig='code ~/.zshrc'
alias cleanup='brew cleanup && npm cache clean --force && docker system prune -f'
alias update='brew update && brew upgrade && brew cleanup'

# ===== FUNCTIONS =====
# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Git commit with message
gcmsg() {
    git commit -m "$1"
}

# Quick project navigation
proj() {
    cd ~/projects/$1
}

# Kill process by name
killbyname() {
    ps aux | grep "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
}

# Weather
weather() {
    local city=${1:-"San Francisco"}
    curl -s "wttr.in/$city?format=3"
}

# ===== FZF Configuration =====
if command -v fzf >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview 'bat --color=always --style=header,grid --line-range :300 {}'"
fi

# ===== Load Additional Configurations =====
# Load powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Load local zsh configuration if it exists
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Load work-specific configuration if it exists
[[ -f ~/.zshrc.work ]] && source ~/.zshrc.work

# ===== Auto-completion =====
autoload -U compinit
compinit

# Case insensitive tab completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Colored tab completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Menu-style completion
zstyle ':completion:*' menu select

# Use cache for completions
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path ~/.zsh/cache/

# ===== Key Bindings =====
# Use emacs key bindings
bindkey -e

# Search history
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

# Edit command line
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Word movement
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ===== Startup Message =====
echo "🚀 Welcome back, Piyush! Ready to code?"