#! /bin/bash


# Setting color variables
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)

# Resets the style
reset=`tput sgr0`

# Color-echo
# arg $1 = message
# arg $2 = Color
cecho() {
  echo "${2}${1}${reset}"
  return
}

echo ""
cecho "###############################################" $red
cecho "#        DO NOT RUN THIS SCRIPT BLINDLY       #" $red
cecho "#         YOU'LL PROBABLY REGRET IT...        #" $red
cecho "#                                             #" $red
cecho "#              READ IT THOROUGHLY             #" $red
cecho "#         AND EDIT TO SUIT YOUR NEEDS         #" $red
cecho "###############################################" $red
echo ""

CONTINUE=false

echo ""
cecho "Have you read through the script you're about to run and " $red
cecho "understood that it will make changes to your computer? (y/n)" $red
read -r response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  CONTINUE=true
fi

if ! $CONTINUE; then
  cecho "Please go read the script, it only takes a few minutes" $red
  exit
fi

# Here we go.. ask for the administrator password upfront and run a
# keep-alive to update existing `sudo` time stamp until script has finished
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


##############################
# Prerequisite: Install Brew #
##############################

echo "############ Installing brew ############"

if test ! $(which brew)
then
	## Don't prompt for confirmation when installing homebrew
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null
fi

# Latest brew, install brew cask
brew upgrade
brew update
brew tap homebrew/cask


#############################################
### Generate ssh keys & add to ssh-agent
### See: https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/
#############################################

echo "############ Generating ssh keys, adding to ssh-agent ############"
read -p 'Input email for ssh key: ' useremail

echo "Use default ssh file location, enter a passphrase: "
ssh-keygen -t rsa -b 4096 -C "$useremail"  # will prompt for password
eval "$(ssh-agent -s)"

# Now that sshconfig is synced add key to ssh-agent and
# store passphrase in keychain
ssh-add -K ~/.ssh/id_rsa

# If you're using macOS Sierra 10.12.2 or later, you will need to modify your ~/.ssh/config file to automatically load keys into the ssh-agent and store passphrases in your keychain.

if [ -e ~/.ssh/config ]
then
    echo "ssh config already exists. Skipping adding osx specific settings... "
else
	echo "Writing osx specific settings to ssh config... "
  cat << EOT >> ~/.ssh/config
	Host *
		AddKeysToAgent yes
		UseKeychain yes
		IdentityFile ~/.ssh/id_rsa
EOT
fi


# Copy shh key to clipboard and prompt user to add to their github account
pbcopy < ~/.ssh/id_rsa.pub
echo "Your SSH key has been copied to your clipboard!"
cecho "**********IMPORTANT**********" $red
echo "Please visit"
cecho "https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account" $blue
echo "to add keys to your account! Type yes when ready to continue"
read -r pause


# zsh settings
echo "############ Installing zsh ############"
# Install zsh
brew install zsh
# Change zsh to default shell
chsh -s $(which zsh)

## Install oh my zsh
echo ""
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Create .zprofile
echo "############ Creating .zprofile && adding settings ############"
touch ~/.zprofile

# add to .zprofile
cat << _EOF_ >> ~/.zprofile
# virtualenv setup
source /usr/local/bin/virtualenvwrapper.sh
export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"
export PATH=$PATH:/usr/local/Cellar/openssl/1.0.2r/bin/
export PATH=$PATH:/usr/local/Cellar/postgresql\@9.6/9.6.13/bin/

# Fixing 'Locale Error' - UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

#Pyenv PATH
export PATH="~/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Setting path for custom shell functions
export PATH="$PATH:~/Projects/bash_scripts/"
export PATH="$PATH:~/Projects/computer_setup/"
export PATH="$PATH:~/Projects/neutron_scripts/"

# PATH for pipenv
export PATH="$PATH:~/.local/bin"

# alias for postgres docker container
alias positron_database="sudo docker run --rm --name=pg-docker-9.3 -e POSTGRES_PASSWORD=postgres -d -p 5432:5432 -v ~/Library/Developer/docker/volumes/postgres:/var/lib/postgresql/data postgres:9.3"

# alias for back command
alias back="source back"

# alias for stat command
# alias stat="stat -x"

# alias for history search
alias hs="history | grep"

# alias for export DJANGO_SETTINGS_MODULE
alias dj_settings="export DJANGO_SETTINGS_MODULE="

# alias for starting proton tenant_command shell inside pipenv shell
alias proton_shell="pipenv shell 'python manage.py tenant_command shell --schema=neutron'"

# alias for deleting all migrations in current directory
alias delete_migrations="find . -path '*/migrations/*.py' -not -name '__init__.py' -delete"

_EOF_


##############################
# Install via Brew           #
##############################

echo "############ Starting brew app install ############"

### Developer Tools
brew cask install iterm2
brew cask install dash


### Development
brew cask install docker
brew cask install postman

brew cask install pycharm
brew cask install evernote
brew cask install google-chrome
brew cask install alfred
brew cask install flux
brew cask install slack

### Run Brew Cleanup
brew cleanup

# pip packages
pip install virtualenv
pip install virtualenvwrapper

### Python
pip3 install python
pip3 install pyenv
pip3 install pipenv


######################################
# Install few global python packages #
######################################

echo "Installing global Python packages..."

pip3 install --upgrade pip


#########################################
# Add Personal Github Repos to Projects #
#########################################

cd ~/Projects/

# Personal Portfolio Project
git clone git@github.com:zackcpetersen/portfolio.git

# Custom bash scripts
git clone git@github.com:zackcpetersen/bash_scripts.git

# Coding Challenges
git clone git@github.com:zackcpetersen/coding_challenges.git

# Data Structures and Algorithms
git clone git@github.com:zackcpetersen/data_structures_algorithms.git

# Raspberry Pi
git clone git@github.com:zackcpetersen/raspberry_pi.git

# This very setup script
git clone git@github.com:zackcpetersen/computer_setup.git



###############################
# Setting Up Neutron Projects #
###############################

if [[ ! -d "$HOME/Projects" ]]; then
  echo "############ Creating PROJECTS Directory - $HOME/Projects/ ############"
  mkdir "$HOME/Projects/"
else
  echo "############ PROJECTS Directory already exists ############"
fi

echo "############ Navigating to PROJECTS Directory to setup Neutron Projects ############"
cd "$HOME/Projects"

##############################
# Pyenv Settings             #
##############################

echo "############ Setting up Pyenv ############"
echo "Installing Python 2.7.3, 3.5.3, 3.7.6, 3.8.1"

pyenv install 2.7.3 -v
pyenv install 3.5.3 -v
pyenv install 3.7.6 -v
pyenv install 3.8.1 -v

echo "Set Global Python version to 3.7.6"
pyenv global 3.7.6

read -p "Do you want to setup projects for Neutron, Positron, and Proton? [y/n]" response

if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo "Installing project - Neutron"
  echo "Where would you like to clone ORIGIN from?"
  read -p "(Please insert the full copied URL for the NEUTRON (Proton V2) Project) -- SSH --" neutron_origin
  read -p "What would you like your remote to be called? (usually your name)" neutron_remote_name
  read -p "Please insert the full copied URL for your NEUTRON (Proton V2) Project REMOTE" neutron_remote_loc

  cd "$HOME/Projects"

  git clone "$neutron_origin"

  if [[ -d "$HOME/Projects/neutron/" ]]; then
    cd "$HOME/Projects/neutron/"
    git remote add "$neutron_remote_name" "$neutron_remote_loc"
    pyenv local 3.8.1
    pipenv install --python ~/.pyenv/versions/3.8.1/bin/python
    echo "You will still need to setup your pipenv interpreter in PyCharm!"
    cecho "https://slimwiki.com/neutron-interactive/setting-up-pipenv-environment-in-pycharm" $blue
    echo "Type yes when ready to continue"
    read -r pause
    cd "$HOME/Projects"
  fi

  echo "Installing project - Positron"
  read -p "Please insert the full copied URL for the Positron Project -- SSH --" positron_origin
  read -p "What would you like your remote to be called? (usually your name)" positron_remote_name
  read -p "Please insert the full copied URL for your POSITRON Project REMOTE" positron_remote_loc
  git clone "$positron_origin"
  if [[ -d "$HOME/Projects/positron/" ]]; then
    cd "$HOME/Projects/positron/"
    git remote add "$positron_remote_name" "$positron_remote_loc"
    pyenv local 3.5.3
    echo "Setting up venv"
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.pip
    deactivate
    cd "$HOME/Projects"
  fi

  read -p "Please insert the full copied URL for the Proton (Proton V1) Project" proton_origin
  read -p "What would you like your remote to be called? (usually your name)" proton_remote_name
  read -p "Please insert the full copied URL for your PROTON Project REMOTE" proton_remote_loc
  git clone "$proton_origin"
  if [[ -d "$HOME/Projects/proton/" ]]; then
    cd "$HOME/Projects/proton/"
    git remote add "$proton_remote_name" "$proton_remote_loc"
    pyenv local 2.7.3
    echo "Proton virutalenv setup varies - this will have to be done manually"
    cd "$HOME/Projects"
  fi
fi

##################
### Finder, Dock, & Menu Items
##################
echo "Setting up default settings"
# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Minimize windows into their application’s icon
defaults write com.apple.dock minimize-to-application -bool true

# Don’t show recent applications in Dock
defaults write com.apple.dock show-recents -bool false


##################
### Text Editing / Keyboards
##################

# Disable smart quotes and smart dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false


###############################################################################
# Screenshots / Screen                                                        #
###############################################################################

# Require password immediately after sleep or screen saver begins"
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "$HOME/Desktop"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Load new settings before rebuilding the index
killall mds


###############################################################################
# Mac App Store                                                               #
###############################################################################

# Enable the automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install System data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

###############################################################################
# Photos                                                                      #
###############################################################################

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Google Chrome                                                               #
###############################################################################

# Disable the all too sensitive backswipe on trackpads
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false


echo ""
cecho "Done!" $cyan
echo ""
echo ""
cecho "################################################################################" $white
echo ""
echo ""
cecho "Note that some of these changes require a logout/restart to take effect." $red
cecho "####### TODO #######" $cyan
cecho "Remember to install oh my zsh and follow this guide! https://www.sitepoint.com/zsh-tips-tricks/" $cyan
cecho "Configure PyCharm Intrepeters, configs, & settings"
cecho "Check remotes for all github projects"
cecho "Create and setup Proton (V1) virtualenv"
echo ""
echo ""
read -p "Check for and install available OSX updates, install, and automatically restart? (y/n)? " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]] ;then
    softwareupdate -i -a --restart
fi
