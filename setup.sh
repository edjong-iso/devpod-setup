#!/bin/sh

# Ensure tmux is configured to source the shared config
TMUX_CONF="$HOME/.tmux.conf"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SOURCE_LINE="source-file $SCRIPT_DIR/.tmux.conf"
REGEX="^source-file[[:space:]].*\.tmux\.conf$"

if [ -f "$TMUX_CONF" ]; then
    if grep -Fxq "$SOURCE_LINE" "$TMUX_CONF"; then
        echo "tmux is already configured to source $SCRIPT_DIR/.tmux.conf"
    elif grep -E -q "$REGEX" "$TMUX_CONF"; then
        sed -i -E "s|^source-file[[:space:]].*\.tmux\.conf$|$SOURCE_LINE|" "$TMUX_CONF"
        echo "Updated source-file line in $TMUX_CONF to point to $SCRIPT_DIR/.tmux.conf"
    else
        # Use -e to interpret \n as a real newline
        echo -e "\n$SOURCE_LINE" >> "$TMUX_CONF"
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

# Symlink AGENTS.md into each agent's expected user-level path.
# AGENTS.md is the shared source of truth; each agent looks for its own filename.
AGENTS_MD_TARGET="$SCRIPT_DIR/AGENTS.md"
link_agents_md() {
    link_path="$1"
    link_dir=$(dirname "$link_path")
    mkdir -p "$link_dir"
    if [ -L "$link_path" ]; then
        if [ "$(readlink "$link_path")" = "$AGENTS_MD_TARGET" ]; then
            echo "$link_path already symlinked to $AGENTS_MD_TARGET"
        else
            ln -sfn "$AGENTS_MD_TARGET" "$link_path"
            echo "Updated $link_path symlink to point to $AGENTS_MD_TARGET"
        fi
    elif [ -e "$link_path" ]; then
        echo "WARNING: $link_path exists and is not a symlink. Skipping to avoid clobbering."
    else
        ln -s "$AGENTS_MD_TARGET" "$link_path"
        echo "Symlinked $link_path -> $AGENTS_MD_TARGET"
    fi
}

link_agents_md "$HOME/.claude/CLAUDE.md"
# Add more here as other agents get installed, e.g.:
# link_agents_md "$HOME/.gemini/GEMINI.md"
# link_agents_md "$HOME/.codex/AGENTS.md"

# Personal Claude skills: copy each into the persistent ~/.agents/skills, then
# symlink into the user-level discovery root ~/.claude/skills. We copy (rather
# than symlink to $SCRIPT_DIR) because $SCRIPT_DIR lives under /tmp on devpods
# and would dangle after a pod restart; ~/.agents is persistence-backed.
SKILLS_SRC_DIR="$SCRIPT_DIR/skills"
AGENTS_SKILLS_DIR="$HOME/.agents/skills"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
if [ -d "$SKILLS_SRC_DIR" ]; then
    mkdir -p "$AGENTS_SKILLS_DIR" "$CLAUDE_SKILLS_DIR"
    for skill_dir in "$SKILLS_SRC_DIR"/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name=$(basename "$skill_dir")
        cp -a "$skill_dir" "$AGENTS_SKILLS_DIR/"
        link_path="$CLAUDE_SKILLS_DIR/$skill_name"
        target="$AGENTS_SKILLS_DIR/$skill_name"
        if [ -L "$link_path" ]; then
            ln -sfn "$target" "$link_path"
            echo "Updated skill symlink $link_path -> $target"
        elif [ -e "$link_path" ]; then
            echo "WARNING: $link_path exists and is not a symlink. Skipping to avoid clobbering."
        else
            ln -s "$target" "$link_path"
            echo "Symlinked skill $link_path -> $target"
        fi
    done
fi

# Update package list
sudo apt update

# install less
sudo apt install less -y 

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
ZSH_SWITCH="# Add global npm binaries to PATH
export PATH=\"/persistence/.npm-global/bin:\$PATH\"

# Switch to zsh for interactive sessions
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
ZSH_CONFIG="# Add global npm binaries to PATH
export PATH=\"/persistence/.npm-global/bin:\$PATH\"

# Path to your Oh My Zsh installation.
export ZSH=\"\$HOME/.oh-my-zsh\"

ZSH_THEME=\"robbyrussell\"

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-tab-title
)

source \$ZSH/oh-my-zsh.sh

# History configuration
export HISTFILE=\"/persistence/.zsh_history\"
export HISTSIZE=10000
export SAVEHIST=10000
setopt SHARE_HISTORY

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
