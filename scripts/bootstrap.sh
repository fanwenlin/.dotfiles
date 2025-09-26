#!/usr/bin/env bash
set -euo pipefail

# Unified non-interactive setup for Ubuntu/debian-like systems
# Installs: zsh, oh-my-zsh, plugins, fzf, autojump, thefuck, Node.js 18, Go 1.18, configures shell

USER_NAME=${SUDO_USER:-${USER}}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
ZSHRC="${USER_HOME}/.zshrc"
OHMY="${USER_HOME}/.oh-my-zsh"
NODE_MAJOR=${NODE_MAJOR:-18}
GO_VERSION=${GO_VERSION:-1.18.10}
export DEBIAN_FRONTEND=noninteractive

echo "==> Running bootstrap as ${USER_NAME} (home=${USER_HOME})"

require_cmd() {
  command -v "$1" >/dev/null 2>&1
}

append_once() {
  local line="$1" file="$2"
  grep -Fqx "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ca-certificates curl git zsh locales build-essential unzip \
  zsh-autosuggestions zsh-syntax-highlighting autojump thefuck

# Locale
sudo sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen || true
sudo locale-gen en_US.UTF-8 || true

# Default shell to zsh
if [ "$(getent passwd "$USER_NAME" | cut -d: -f7)" != "/usr/bin/zsh" ]; then
  sudo chsh -s /usr/bin/zsh "$USER_NAME" || true
fi

# Oh My Zsh (unattended)
if [ ! -d "$OHMY" ]; then
  echo "==> Installing Oh My Zsh"
  sudo -u "$USER_NAME" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" '' --unattended
fi

# Ensure .zshrc exists
sudo -u "$USER_NAME" touch "$ZSHRC"

# Enable plugins
if ! grep -q '^plugins=' "$ZSHRC"; then
  echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)" | sudo -u "$USER_NAME" tee -a "$ZSHRC" >/dev/null
else
  sudo -u "$USER_NAME" sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' "$ZSHRC"
fi

# thefuck alias
append_once "if command -v thefuck >/dev/null 2>&1; then eval \"\$(thefuck --alias)\"; fi" "$ZSHRC"
append_once "alias fk='fuck'" "$ZSHRC"

# fzf (non-interactive)
if [ ! -d "${USER_HOME}/.fzf" ]; then
  echo "==> Installing fzf"
  sudo -u "$USER_NAME" git clone --depth 1 https://github.com/junegunn/fzf.git "${USER_HOME}/.fzf"
  sudo -u "$USER_NAME" "${USER_HOME}/.fzf/install" --key-bindings --completion --no-bash --no-fish --no-update-rc
fi

# Node.js 18 via NodeSource
if ! require_cmd node || [ "$(node -v | sed 's/v//' | cut -d. -f1)" -ne "$NODE_MAJOR" ]; then
  echo "==> Installing Node.js ${NODE_MAJOR}.x"
  curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | sudo -E bash -
  sudo apt-get install -y --no-install-recommends nodejs
fi

# Go 1.18
if ! require_cmd go || ! go version | grep -q "go${GO_VERSION%%.*}"; then
  echo "==> Installing Go ${GO_VERSION}"
  tmp=$(mktemp -d)
  curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o "$tmp/go.tgz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "$tmp/go.tgz"
  rm -rf "$tmp"
fi

# Go env in zshrc
append_once "export GOROOT=/usr/local/go" "$ZSHRC"
append_once "export GOPATH=\"${USER_HOME}/go\"" "$ZSHRC"
append_once "export PATH=\"$GOROOT/bin:$GOPATH/bin:$PATH\"" "$ZSHRC"

# Copy repo .gitconfig into user home if present
if [ -f ".gitconfig" ] && [ ! -f "${USER_HOME}/.gitconfig" ]; then
  echo "==> Installing user .gitconfig"
  sudo install -m 0644 -o "$USER_NAME" -g "$USER_NAME" .gitconfig "${USER_HOME}/.gitconfig"
fi

echo "==> Bootstrap completed"
