sudo apt-get install zsh

# install oh-my-zsh
sh -c "$(curl -fsSL <https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh>)" 


# -----------------------------------------------------------------------------------------------------
# install plugins

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# zsh-gutosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# zsh-completions
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# auto jump
git clone git://github.com/wting/autojump.git
cd autojump && ./install.py

# the fuck
brew install thefuck
echo "export PATH="/home/linuxbrew/.linuxbrew/bin/:\$PATH"" >> ~/.zshrc
echo "eval \$(thefuck --alias)" >> ~/.zshrc
echo "alias fk='fuck'" >> ~/.zshrc
