ARG BASE_IMAGE=mcr.microsoft.com/devcontainers/base:ubuntu
FROM ${BASE_IMAGE}

ARG USERNAME=vscode
ARG NODE_MAJOR=18
ARG GO_VERSION=1.18.10
ENV DEBIAN_FRONTEND=noninteractive

# Base tools and dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git sudo zsh locales \
        build-essential unzip \
        zsh-autosuggestions zsh-syntax-highlighting \
        autojump thefuck \
    && rm -rf /var/lib/apt/lists/*

# Configure locale (optional but nice in devcontainers)
RUN sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Install Node.js 18 via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Go ${GO_VERSION}
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -o /tmp/go.tgz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf /tmp/go.tgz \
    && rm /tmp/go.tgz
ENV GOROOT=/usr/local/go
ENV GOPATH=/home/${USERNAME}/go
ENV PATH=${GOROOT}/bin:${GOPATH}/bin:${PATH}

# Set Zsh as default shell for ${USERNAME}
RUN chsh -s /usr/bin/zsh ${USERNAME}

# Install Oh My Zsh (unattended) for ${USERNAME} (skip if already present)
USER ${USERNAME}
ENV ZSH=/home/${USERNAME}/.oh-my-zsh
RUN if [ ! -d "$ZSH" ]; then \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" '' --unattended; \
    fi \
    && mkdir -p "$ZSH/custom/plugins" "$ZSH/custom/themes"

# Enable plugins: git, zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions (via apt package)
RUN sed -i 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' /home/${USERNAME}/.zshrc \
    && cat <<EOF >> /home/${USERNAME}/.zshrc
# thefuck alias (guarded)
if command -v thefuck >/dev/null 2>&1; then
  eval "\$(thefuck --alias)"
fi
alias fk='fuck'

# Go env
export GOROOT=/usr/local/go
export GOPATH="/home/${USERNAME}/go"
export PATH="\$GOROOT/bin:\$GOPATH/bin:\$PATH"
EOF

# Optional: fzf installation (non-interactive)
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
    && ~/.fzf/install --key-bindings --completion --no-bash --no-fish --no-update-rc

# Copy repo dotfiles (e.g., .gitconfig) into container user home if present
USER root
COPY .gitconfig /tmp/.gitconfig
RUN if [ -s /tmp/.gitconfig ]; then cp /tmp/.gitconfig /home/${USERNAME}/.gitconfig && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.gitconfig; fi \
    && rm -f /tmp/.gitconfig

USER ${USERNAME}
WORKDIR /workspaces
SHELL ["/usr/bin/zsh", "-lc"]

# Final echo for clarity when building
RUN echo "Dev container ready with Node.js ${NODE_MAJOR} and Go ${GO_VERSION}."
