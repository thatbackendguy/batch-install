#!/bin/bash
echo "";
echo "";
echo " _   _           _   _                _                  _                   ";
echo "| | | |         | | | |              | |                | |                  ";
echo "| |_| |__   __ _| |_| |__   __ _  ___| | _____ _ __   __| | __ _ _   _ _   _ ";
echo "| __| '_ \ / _\` | __| '_ \ / _\` |/ __| |/ / _ \ '_ \ / _\` |/ _\` | | | | | | |";
echo "| |_| | | | (_| | |_| |_) | (_| | (__|   <  __/ | | | (_| | (_| | |_| | |_| |";
echo " \__|_| |_|\__,_|\__|_.__/ \__,_|\___|_|\_\___|_| |_|\__,_|\__, |\__,_|\__, |";
echo "                                                            __/ |       __/ |";
echo "                                                           |___/       |___/ ";
sleep 2

echo ""
echo "Upgrading system packages..."
sudo apt update >/dev/null 2>&1;
sudo apt upgrade -y >/dev/null 2>&1;

if [ $? -eq 0 ]; then
  echo "Packages upgraded successfully!"
  echo "";
  echo "----------------------------------";
  echo "";

  #installing BUILD-ESSENTIAL
  read -p "Do you want to install build-essential? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
      echo "----| Installing build-essential |-----"
      sudo apt-get install -y build-essential
  fi

  #installing BRAVE BROWSER
  echo ""
  read -p "Do you want to install Brave Browser? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "-----| Installing BRAVE BROWSER |-----"
    sudo apt install apt-transport-https curl -y
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt update -y
    sudo apt install brave-browser -y
  fi

  #installing GOOGLE CHROME
  echo ""
  read -p "Do you want to install Google Chrome? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "----| Installing GOOGLE CHROME |-----"
    sudo apt update -y
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i google-chrome-stable_current_amd64.deb
  fi


  #installing VISUAL STUDIO CODE
  echo ""
  read -p "Do you want to install Visual Studio Code? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
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
  echo ""
  read -p "Do you want to install Discord? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "----| Installing DISCORD |-----"
    sudo snap install discord
  fi

  #installing VLC
  echo ""
  read -p "Do you want to install VLC? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "----| Installing VLC |-----"
    sudo apt install vlc -y
  fi

  #installing ANYDESK
  echo ""
  read -p "Do you want to install AnyDesk? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "----| Installing ANYDESK |-----"
    wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo apt-key add -
    echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
    sudo apt update
    sudo apt install anydesk -y
  fi

  #installing FILEZILLA
  echo ""
  read -p "Do you want to install FileZilla? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "----| Installing FILEZILLA |-----"
    sudo apt-get update
    sudo apt-get install filezilla -y
  fi

  #installing GITHUB DESKTOP
  echo ""
  read -p "Do you want to install GitHub Desktop? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "----| Installing GITHUB DESKTOP |-----"
    wget -qO - https://apt.packages.shiftkey.dev/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/shiftkey-packages.gpg > /dev/null
    sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/shiftkey-packages.gpg] https://apt.packages.shiftkey.dev/ubuntu/ any main" > /etc/apt/sources.list.d/shiftkey-packages.list'
    sudo apt update && sudo apt install github-desktop
  fi

  #installing VIRTUAL BOX
  echo ""
  read -p "Do you want to install VirtualBox? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "----| Installing VIRTUAL BOX |-----"
    sudo apt-get update
    sudo apt-get install virtualbox -y
  fi

  #installing PYTHON3
  echo ""
  read -p "Do you want to install Python3? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "----| Installing PYTHON3 |-----"
    sudo apt-get install -y python3
  fi

  #installing NET-TOOLS
  echo ""
  read -p "Do you want to install net-tools? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "----| Installing NET-TOOLS |-----"
    sudo apt-get install -y net-tools
  fi

  #installing GIT
  echo ""
  read -p "Do you want to install Git? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "----| Installing GIT |-----"
    sudo apt-get install -y git
  fi

  #installing GIT CLI
  echo ""
  read -p "Do you want to install Git CLI? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "----| Installing GIT CLI |-----"
    sudo apt install -y gh
  fi

  #installing MONITORING APPS
  echo ""
  read -p "Do you want to install monitoring apps (nvtop, htop, sysstat, fping, traceroute, nmap)? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
  echo "----| Installing MONITORING APPS |-----"
  sudo apt-get install nvtop htop nmap -y
  sudo apt install sysstat fping traceroute -y
  fi

  #installing NODE JS
  echo ""
  read -p "Do you want to install Node.js? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
  echo "----| Installing NODE JS |-----"
  sudo snap install node --classic
  fi

  # installing Wireshark
  echo ""
  read -p "Do you want to install Wireshark? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
  echo "----| Installing Wireshark |----"
  sudo add-apt-repository ppa:wireshark-dev/stable
  sudo apt-get update
  sudo apt-get install wireshark -y
  fi

  # Installing SSH
  echo ""
  read -p "Do you want to install SSH? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
  echo "----| Installing SSH |----"
  sudo apt install openssh-client openssh-server -y
  fi

  # Installing Telnet
  echo ""
  read -p "Do you want to install Telnet? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
  echo "----| Installing Telnet |----"
  sudo apt install telnetd -y
  fi

  # Installing Java JDK & JRE 17
  echo ""
  read -p "Do you want to install Java JDK & JRE 17? (y/n) " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
  echo "----| Installing Java JDK & JRE 17 |----"
  sudo apt install openjdk-17-jdk openjdk-17-jre -y
  fi

  sudo apt autoremove >/dev/null 2>&1

  echo ""
  echo ""
  echo "-----------------"
  echo ""
  echo "To configure: git"
  echo "git config --global user.name '<Your Name>'"
  echo "git config --global user.email '<Your Email>'"

  echo ""
  echo "-----------------"
  echo ""
  echo "To configure: gh (GitHub CLI)"
  echo "gh config login"
  echo ""
  echo "-----------------"
  echo ""
else
    echo "ERROR!"
    echo "M: error occured in upgrading system packages."
fi

