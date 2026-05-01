# Lola Stories — Bootstrap

One-command setup for a new co-founder Mac.

## Run it

On a fresh macOS machine, paste this into Terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Lola-Stories/bootstrap/main/install.sh)"
```

The script prompts for your name, email, and GitHub username at the start, then runs unattended for ~20 minutes. macOS will ask for your admin password once or twice (Xcode Command Line Tools, Homebrew casks).

## What it installs

- **Homebrew** + the [Brewfile](./Brewfile): core CLIs (git, gh, jq, ripgrep, tmux), runtimes (node, nvm, pnpm, python, uv), Docker (colima), Postgres 17, Redis, Infisical CLI
- **Apps:** Cursor, VS Code, Claude desktop, Chrome, 1Password, Raycast, Slack, Notion, Obsidian, Discord, ChatGPT, Bruno, DBeaver, ngrok
- **Shell:** zsh + starship prompt + autosuggestions/syntax-highlighting plugins, sane defaults from [zshrc](./zshrc)
- **Git:** [gitconfig.template](./gitconfig.template) filled with your name/email
- **SSH:** ed25519 key generated and uploaded to GitHub via `gh ssh-key add`
- **Claude Code:** installed via official one-liner

## What's still manual

The script can't autonomously sign you into stuff — at the end it prints a checklist:

1. Open 1Password and sign in
2. Open Slack / Notion / Discord / Cursor / Claude Code and sign in
3. Run `infisical login --domain https://infisical.lumitra.co` to get access to runtime secrets
4. Clone `Lola-Stories/lola-stories`

## Re-running

The script is idempotent — re-running upgrades brews, leaves existing SSH keys alone, and skips already-installed tools. Safe to run again after edits.
