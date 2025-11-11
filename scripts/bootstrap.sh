#!/usr/bin/env bash
set -euo pipefail

# Unified non-interactive setup for Ubuntu/debian-like systems
# Installs: zsh, oh-my-zsh, plugins, fzf, autojump, thefuck, Node.js 22, Go 1.23, configures shell

USER_NAME=${SUDO_USER:-${USER}}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
ZSHRC="${USER_HOME}/.zshrc"
OHMY="${USER_HOME}/.oh-my-zsh"
ZSH_CUSTOM="${OHMY}/custom"
NODE_MAJOR=${NODE_MAJOR:-22}
GO_VERSION=${GO_VERSION:-1.23.2}
export DEBIAN_FRONTEND=noninteractive

echo "==> Running bootstrap as ${USER_NAME} (home=${USER_HOME})"

require_cmd() {
  command -v "$1" >/dev/null 2>&1
}

append_once() {
  local line="$1" file="$2"
  grep -Fqx "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

install_omz_plugin() {
  local name="$1" repo="$2"
  local dest="${ZSH_CUSTOM}/plugins/${name}"

  if [ -d "$dest/.git" ]; then
    echo "==> Updating Oh My Zsh plugin ${name}"
    sudo -u "$USER_NAME" git -C "$dest" pull --ff-only >/dev/null
  elif [ -d "$dest" ]; then
    echo "==> Oh My Zsh plugin ${name} already present (non-git), skipping"
  else
    echo "==> Installing Oh My Zsh plugin ${name}"
    sudo -u "$USER_NAME" git clone --depth 1 "$repo" "$dest"
  fi
}

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ca-certificates curl git zsh locales build-essential unzip \
  autojump thefuck

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

sudo -u "$USER_NAME" mkdir -p "${ZSH_CUSTOM}/plugins"
install_omz_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
install_omz_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
install_omz_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions"

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

# Node.js 22 via NodeSource
if ! require_cmd node || [ "$(node -v | sed 's/v//' | cut -d. -f1)" -ne "$NODE_MAJOR" ]; then
  echo "==> Installing Node.js ${NODE_MAJOR}.x"
  curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | sudo -E bash -
  sudo apt-get install -y --no-install-recommends nodejs
fi

# Go 1.23
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
append_once 'export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"' "$ZSHRC"

# Copy repo .gitconfig into user home if present
if [ -f ".gitconfig" ] && [ ! -f "${USER_HOME}/.gitconfig" ]; then
  echo "==> Installing user .gitconfig"
  sudo install -m 0644 -o "$USER_NAME" -g "$USER_NAME" .gitconfig "${USER_HOME}/.gitconfig"
fi

echo "==> Bootstrap completed"
