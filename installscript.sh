#!/bin/bash

sudo apt update -y && sudo apt upgrade -y

#installing BUILD-ESSENTIAL
read -p "Do you want to install build-essential? (y/n/a/q) " choice
case "$choice" in
  y|Y)
    echo "----| Installing build-essential |-----"
    sudo apt-get install -y build-essential
    ;;
  a|A)
    install_all=true
    echo "----| Installing build-essential |-----"
    sudo apt-get install -y build-essential
    ;;
  n|N)
    ;;
  q|Q)
    exit 0
    ;;
  *)
    echo "Invalid choice"
    ;;
esac

#installing BRAVE BROWSER
if [ "$install_all" = true ] || read -p "Do you want to install Brave Browser? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "-----| Installing BRAVE BROWSER |-----"
  sudo apt install apt-transport-https curl -y
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
  sudo apt update -y
  sudo apt install brave-browser -y
fi

#installing GOOGLE CHROME
if [ "$install_all" = true ] || read -p "Do you want to install Google Chrome? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "----| Installing GOOGLE CHROME |-----"
  sudo apt update -y
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i google-chrome-stable_current_amd64.deb
fi

#installing VISUAL STUDIO CODE
if [ "$install_all" = true ] || read -p "Do you want to install Visual Studio Code? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "----| Installing VISUAL STUDIO CODE |-----"
  sudo apt-get install wget gpg -y
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
  rm -f packages.microsoft.gpg
  sudo apt install apt-transport-https -y
  sudo apt update -y
  sudo apt install code -y
fi

#installing DISCORD
if [ "$install_all" = true ] || read -p "Do you want to install Discord? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "----| Installing DISCORD |-----"
  sudo snap install discord
fi

#installing VLC
if [ "$install_all" = true ] || read -p "Do you want to install VLC? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "----| Installing VLC |-----"
  sudo apt install vlc -y
fi

#installing ANYDESK
if [ "$install_all" = true ] || read -p "Do you want to install AnyDesk? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "----| Installing ANYDESK |-----"
  wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo apt-key add -
  echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
  sudo apt update
  sudo apt install anydesk -y
fi

#installing FILEZILLA
if [ "$install_all" = true ] || read -p "Do you want to install FileZilla? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "----| Installing FILEZILLA |-----"
  sudo apt-get update
  sudo apt-get install filezilla -y
fi

#installing GITHUB DESKTOP
if [ "$install_all" = true ] || read -p "Do you want to install GitHub Desktop? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "----| Installing GITHUB DESKTOP |-----"
  sudo wget https://github.com/shiftkey/desktop/releases/download/release-3.1.1-linux1/GitHubDesktop-linux-3.1.1-linux1.deb
  sudo apt-get install gdebi-core -y
  sudo gdebi GitHubDesktop-linux-3.1.1-linux1.deb
fi

#installing VIRTUAL BOX
if [ "$install_all" = true ] || read -p "Do you want to install VirtualBox? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "----| Installing VIRTUAL BOX |-----"
  sudo apt-get update
  sudo apt-get install virtualbox -y
fi

#installing PYTHON3
if [ "$install_all" = true ] || read -p "Do you want to install Python3? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "----| Installing PYTHON3 |-----"
  sudo apt-get install -y python3
fi

#installing NET-TOOLS
if [ "$install_all" = true ] || read -p "Do you want to install net-tools? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "----| Installing NET-TOOLS |-----"
  sudo apt-get install -y net-tools
fi

#installing GIT
if [ "$install_all" = true ] || read -p "Do you want to install Git? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "----| Installing GIT |-----"
  sudo apt-get install -y git
fi

#installing GIT CLI
if [ "$install_all" = true ] || read -p "Do you want to install Git CLI? (y/n/q) " choice && [ "$choice" = "y" ]; then
  echo "----| Installing GIT CLI |-----"
  sudo apt install -y gh
fi

#installing MONITORING APPS
if [ "$install_all" = true ] || read -p "Do you want to install monitoring apps (nvtop, htop, sysstat, fping, traceroute, nmap)? (y/n/q) " choice && [ "$choice" = "y" ]; then
 echo "----| Installing MONITORING APPS |-----"
 sudo apt-get install nvtop htop nmap -y
 sudo apt install sysstat fping traceroute -y
fi

#installing NODE JS
if [ "$install_all" = true ] || read -p "Do you want to install Node.js v18.x? (y/n/q) " choice && [ "$choice" = "y" ]; then
 echo "----| Installing NODE JS |-----"
 sudo snap install node --classic
fi

# installing Wireshark
if [ "$install_all" = true ] || read -p "Do you want to install Wireshark? (y/n/q) " choice && [ "$choice" = "y" ]; then
 echo "----| Installing Wireshark |----"
 sudo add-apt-repository ppa:wireshark-dev/stable
 sudo apt-get update
 sudo apt-get install wireshark -y
fi

# Installing SSH
if [ "$install_all" = true ] || read -p "Do you want to install SSH? (y/n/q) " choice && [ "$choice" = "y" ]; then
 echo "----| Installing SSH |----"
 sudo apt install openssh-client openssh-server -y
fi

# Installing Telnet
if [ "$install_all" = true ] || read -p "Do you want to install Telnet? (y/n/q) " choice && [ "$choice" = "y" ]; then
 echo "----| Installing Telnet |----"
 sudo apt install telnetd -y
fi

# Installing Java JDK & JRE 17
if [ "$install_all" = true ] || read -p "Do you want to install Java JDK & JRE 17? (y/n/q) " choice && [ "$choice" = "y" ]; then
 echo "----| Installing Java JDK & JRE 17 |----"
 sudo apt install openjdk-17-jdk openjdk-17-jre -y
fi

sudo apt autoremove

echo "To configure: git"
echo "git config --global user.name '<Your Name>'"
echo "git config --global user.email '<Your Email>'"

echo "To configure: gh (GitHub CLI)"
echo "gh config login"