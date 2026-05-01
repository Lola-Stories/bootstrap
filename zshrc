# ============================================================
#  Lola Stories — Co-founder zshrc
#  Symlinked to ~/.zshrc by bootstrap install.sh
# ============================================================

# ── Homebrew env ─────────────────────────────────────────────
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ── PATH ─────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── nvm (lazy-loaded for fast shell startup) ─────────────────
export NVM_DIR="$HOME/.nvm"
if [[ -d "$NVM_DIR/versions/node" ]]; then
  _nvm_default_version=$(ls -1 "$NVM_DIR/versions/node" 2>/dev/null | sort -V | tail -1)
  [[ -n "$_nvm_default_version" ]] && export PATH="$NVM_DIR/versions/node/$_nvm_default_version/bin:$PATH"
  unset _nvm_default_version
fi
nvm() {
  unset -f nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
  nvm "$@"
}

# ── pnpm ─────────────────────────────────────────────────────
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# ── History ──────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt EXTENDED_HISTORY

# ── Navigation + general options ─────────────────────────────
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# ── Completion ───────────────────────────────────────────────
fpath=($(brew --prefix)/share/zsh/site-functions $fpath)
autoload -Uz compinit
_compdump="$HOME/.zcompdump"
if [[ -n "$_compdump"(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
unset _compdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# ── Key bindings ─────────────────────────────────────────────
bindkey -e

# ── Colors + aliases ─────────────────────────────────────────
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
alias ls='ls -G'
alias ll='ls -lhG'
alias la='ls -lhAG'
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Git shortcuts
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gco='git checkout'
alias gb='git branch'

# ── zsh plugins ──────────────────────────────────────────────
# Order matters:
#   1. autosuggestions (ghost-text)
#   2. syntax-highlighting (near end)
#   3. history-substring-search (after syntax-highlighting)
_brew_prefix="$(brew --prefix 2>/dev/null)"
for _plugin in \
  "$_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "$_brew_prefix/share/zsh-history-substring-search/zsh-history-substring-search.zsh"; do
  [[ -f "$_plugin" ]] && source "$_plugin"
done
unset _plugin _brew_prefix

if typeset -f history-substring-search-up >/dev/null; then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^P'   history-substring-search-up
  bindkey '^N'   history-substring-search-down
fi

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# ── Starship prompt ──────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ── Local overrides (untracked) ──────────────────────────────
# Create ~/.zshrc.local for personal tokens and machine-specific config.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
