#!/usr/bin/env bash
# ============================================================
#  Lola Stories — Co-founder Bootstrap
#  Usage:
#    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Lola-Stories/bootstrap/main/install.sh)"
# ============================================================
set -euo pipefail

# ── Pretty output ────────────────────────────────────────────
say()   { printf "\033[1;34m▶\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m✓\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m!\033[0m %s\n" "$*"; }
fail()  { printf "\033[1;31m✗\033[0m %s\n" "$*" >&2; exit 1; }

# ── Sanity ───────────────────────────────────────────────────
[[ "$(uname -s)" == "Darwin" ]] || fail "This script is macOS-only."

# ── Locate the repo ──────────────────────────────────────────
# When piped from curl, $0 is "bash" — clone the repo so we have
# the Brewfile / zshrc / gitconfig.template alongside us.
REPO_URL="https://github.com/Lola-Stories/bootstrap.git"
REPO_DIR="$HOME/.lola-bootstrap"

if [[ -f "${BASH_SOURCE[0]:-}" && -f "$(dirname "${BASH_SOURCE[0]}")/Brewfile" ]]; then
  BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  say "Cloning bootstrap repo to $REPO_DIR"
  if [[ -d "$REPO_DIR/.git" ]]; then
    git -C "$REPO_DIR" pull --ff-only || warn "git pull failed, using existing checkout"
  else
    # git is part of Xcode CLT, which we install below if missing.
    if ! command -v git >/dev/null 2>&1; then
      say "Installing Xcode Command Line Tools (needed for git)"
      xcode-select --install 2>/dev/null || true
      until xcode-select -p >/dev/null 2>&1; do sleep 5; done
    fi
    git clone --depth 1 "$REPO_URL" "$REPO_DIR"
  fi
  BOOTSTRAP_DIR="$REPO_DIR"
fi

# ── Banner ───────────────────────────────────────────────────
cat <<'BANNER'

  ╭──────────────────────────────────────────╮
  │   Lola Stories — Co-founder Bootstrap    │
  │   This will take 15–30 minutes.          │
  ╰──────────────────────────────────────────╯

BANNER

# ── Prompt for identity ──────────────────────────────────────
say "Tell me about you (used for git config + SSH key)"
read -rp "  Full name (e.g. Ada Lovelace): " FULL_NAME
read -rp "  Email (the one tied to your GitHub account): " EMAIL
read -rp "  GitHub username: " GH_USER
[[ -z "$FULL_NAME" || -z "$EMAIL" || -z "$GH_USER" ]] && fail "All three fields are required."

# ── Xcode CLT (if not already installed above) ───────────────
if ! xcode-select -p >/dev/null 2>&1; then
  say "Installing Xcode Command Line Tools"
  xcode-select --install 2>/dev/null || true
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
fi
ok "Xcode Command Line Tools present"

# ── Homebrew ─────────────────────────────────────────────────
if ! command -v brew >/dev/null 2>&1; then
  say "Installing Homebrew (non-interactive)"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Prime brew env for this script
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
ok "Homebrew ready ($(brew --prefix))"

# ── Brewfile ─────────────────────────────────────────────────
say "Installing CLIs and apps from Brewfile (this is the long step)"
brew bundle install --file="$BOOTSTRAP_DIR/Brewfile" || warn "Some packages may have failed — review output above."
ok "Brewfile complete"

# ── zshrc ────────────────────────────────────────────────────
say "Linking ~/.zshrc"
if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%s)"
  warn "Backed up existing ~/.zshrc"
fi
ln -sfn "$BOOTSTRAP_DIR/zshrc" "$HOME/.zshrc"

if [[ ! -f "$HOME/.zshrc.local" ]]; then
  cat > "$HOME/.zshrc.local" <<'EOF'
# Local overrides — not tracked in git.
# Put personal tokens, machine-specific PATH additions, secret env vars here.
# export NPM_TOKEN=...
EOF
  ok "Created ~/.zshrc.local stub"
fi

# ── gitconfig ────────────────────────────────────────────────
say "Writing ~/.gitconfig"
sed -e "s|__FULL_NAME__|${FULL_NAME}|" \
    -e "s|__EMAIL__|${EMAIL}|" \
    "$BOOTSTRAP_DIR/gitconfig.template" > "$HOME/.gitconfig"
ok "Git configured for ${FULL_NAME} <${EMAIL}>"

# ── SSH key ──────────────────────────────────────────────────
SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ ! -f "$SSH_KEY" ]]; then
  say "Generating SSH key (ed25519)"
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || ssh-add "$SSH_KEY"
  ok "SSH key generated at $SSH_KEY"
else
  ok "SSH key already exists at $SSH_KEY"
fi

# ── GitHub auth + key upload ─────────────────────────────────
if ! gh auth status >/dev/null 2>&1; then
  say "Authenticating gh (a browser window will open)"
  gh auth login --hostname github.com --git-protocol ssh --web
fi
if ! gh ssh-key list 2>/dev/null | grep -q "$(awk '{print $2}' "$SSH_KEY.pub")"; then
  gh ssh-key add "$SSH_KEY.pub" --title "$(scutil --get ComputerName 2>/dev/null || hostname)" || warn "Could not upload SSH key — add it manually at https://github.com/settings/keys"
fi
ok "GitHub authenticated as $(gh api user --jq .login 2>/dev/null || echo '?')"

# ── Claude Code ──────────────────────────────────────────────
if ! command -v claude >/dev/null 2>&1; then
  say "Installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code install failed — install manually from claude.com/download"
fi
command -v claude >/dev/null 2>&1 && ok "Claude Code installed"

# ── Done ─────────────────────────────────────────────────────
cat <<EOF

  ╭──────────────────────────────────────────╮
  │   Bootstrap complete                     │
  ╰──────────────────────────────────────────╯

  Next steps (manual):
    1.  Open 1Password → sign in to your Lola Stories account.
    2.  Open Slack, Notion, Discord, Cursor, Claude Code → sign in.
    3.  Authenticate Infisical (self-hosted, see Marlin):
          infisical login --domain https://infisical.lumitra.co
    4.  Restart your terminal so ~/.zshrc takes effect.
    5.  Clone the lola-stories repo:
          gh repo clone Lola-Stories/lola-stories ~/software-dev/lola-stories

EOF
