
# install linuxbrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# add linuxbrew to path
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/fanwenlin/.zprofile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# install linuxbrew dependency
sudo apt-get update && sudo apt-get install build-essential

# insall gcc
brew install gcc

# install node
brew install node@18

# node environment parameter
echo 'export PATH="/home/linuxbrew/.linuxbrew/opt/node@18/bin:$PATH"' >> ~/.zshrc
echo 'export LDFLAGS="-L/home/linuxbrew/.linuxbrew/opt/node@18/lib"' >> ~/.zshrc
echo 'export CPPFLAGS="-I/home/linuxbrew/.linuxbrew/opt/node@18/include"' >> ~/.zshrc

# golang
brew install go@1.18

# go environment parameter
echo 'export PATH="/home/fanwenlin/.linuxbrew/opt/go@1.18/bin:$PATH"' >> ~/.zshrc
