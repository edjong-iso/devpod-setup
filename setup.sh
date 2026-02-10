#!/bin/sh

# Ensure tmux is configured to source the shared config
TMUX_CONF="$HOME/.tmux.conf"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SOURCE_LINE="source-file $SCRIPT_DIR/.tmux.conf"

if [ -f "$TMUX_CONF" ]; then
    if grep -Fxq "$SOURCE_LINE" "$TMUX_CONF"; then
        echo "tmux is already configured to source $SCRIPT_DIR/.tmux.conf"
    else
        echo "$SOURCE_LINE" >> "$TMUX_CONF"
        echo "Added source-file line to $TMUX_CONF"
    fi
else
    echo "$SOURCE_LINE" > "$TMUX_CONF"
    echo "Created $TMUX_CONF with source-file line"
fi

# Reload tmux configuration if tmux is running
if [ -n "$TMUX" ]; then
    tmux source-file "$TMUX_CONF"
    echo "Reloaded tmux configuration"
fi

# Update package list
sudo apt update

# install less
sudo apt install less -y 

# install NPM and gemini
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# Load nvm into the current shell session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

nvm install --lts
nvm use --lts
npm install -g @google/gemini-cli

# install zsh and Oh My Zsh
sudo apt install zsh -y

# Fix insecure directories for zsh to avoid compinit warnings
# This is a common issue when installing on some environments
if [ -d "/usr/share/zsh" ]; then
    echo "Fixing permissions for /usr/share/zsh..."
    sudo chmod -R g-w,o-w /usr/share/zsh
fi
# Also fix /usr/local/share/zsh if it exists
if [ -d "/usr/local/share/zsh" ]; then
    echo "Fixing permissions for /usr/local/share/zsh..."
    sudo chmod -R g-w,o-w /usr/local/share/zsh
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-tab-title" ]; then
    git clone https://github.com/trystan2k/zsh-tab-title "$ZSH_CUSTOM/plugins/zsh-tab-title"
fi

# Set zsh as default shell for the current user
# Try chsh first, but if it fails or isn't sufficient, configure .bashrc
sudo chsh -s $(which zsh) $USER

# Configure .bashrc to switch to zsh for interactive sessions
BASH_RC="$HOME/.bashrc"
ZSH_SWITCH="# Switch to zsh for interactive sessions
if [[ \$- == *i* ]]; then
    export SHELL=\$(which zsh)
    exec \$(which zsh) -l
fi"

if [ -f "$BASH_RC" ]; then
    if ! grep -Fq "exec \$(which zsh) -l" "$BASH_RC"; then
        echo "" >> "$BASH_RC"
        echo "$ZSH_SWITCH" >> "$BASH_RC"
        echo "Added zsh auto-switch to $BASH_RC"
    else
        echo "zsh auto-switch already present in $BASH_RC"
    fi
else
    echo "$ZSH_SWITCH" > "$BASH_RC"
    echo "Created $BASH_RC with zsh auto-switch"
fi

# Configure .zshrc
ZSH_RC="$HOME/.zshrc"
ZSH_CONFIG="# Path to your Oh My Zsh installation.
export ZSH=\"\$HOME/.oh-my-zsh\"

ZSH_THEME=\"robbyrussell\"

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-tab-title
)

source \$ZSH/oh-my-zsh.sh

# Automatically list directory contents on cd
chpwd() {
  ls -F
}

# tmux aliases
alias ta=\"tmux attach\"
alias taa=\"tmux attach -t\"
alias tad=\"tmux attach -d -t\"
alias td=\"tmux detach\"
alias ts=\"tmux new-session -s\"
alias tl=\"tmux list-sessions\"
alias tkill=\"tmux kill-server\"
alias tdel=\"tmux kill-session -t\""

# We overwrite .zshrc to ensure it matches the desired configuration
echo "$ZSH_CONFIG" > "$ZSH_RC"
echo "Configured $ZSH_RC"
