#!/bin/bash

# Error handling
set -euo pipefail
trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

# Function to handle errors
error_handler() {
    local exit_code=$1
    local line_no=$2
    local bash_lineno=$3
    local last_command=$4
    local func_trace=$5
    whiptail --title "Error" --msgbox "An error occurred:\nExit code: $exit_code\nLine: $line_no\nCommand: $last_command" 10 60
}

# Function to check dependencies
check_dependencies() {
    local deps=("wget" "curl" "gpg" "apt-transport-https")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$dep" 2>/dev/null | grep -q "install ok installed"; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        if whiptail --title "Missing Dependencies" --yesno "The following dependencies need to be installed: ${missing_deps[*]}\nInstall them now?" 10 60; then
            sudo apt update
            for dep in "${missing_deps[@]}"; do
                sudo apt install -y "$dep"
            done
        else
            exit 1
        fi
    fi
}

# Function to display the banner
display_banner() {
    clear
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
    sleep 1
}

# Function to check if whiptail is installed
check_whiptail() {
    if ! command -v whiptail >/dev/null 2>&1; then
        echo "Installing whiptail..."
        sudo apt-get update
        sudo apt-get install whiptail -y
    fi
}

# Function to update system packages
update_system() {
    {
        echo 10
        sudo apt update 2>&1
        echo 50
        sudo apt upgrade -y 2>&1
        echo 90
        sudo apt autoremove -y 2>&1
        echo 100
    } | whiptail --title "System Update" --gauge "Updating system packages..." 6 60 0
}

# Function to create category menus
select_category() {
    local choice
    choice=$(whiptail --title "Software Installation Menu" --menu "Choose a category:" 20 60 10 \
        "1" "Web Browsers" \
        "2" "Development Tools" \
        "3" "Communication Tools" \
        "4" "Media & Utilities" \
        "5" "Network Tools" \
        "6" "Programming Languages" \
        "7" "Review & Install Selected" \
        "8" "Exit" 3>&1 1>&2 2>&3)
    echo $choice
}

# Functions for each category
select_browsers() {
    local choices
    choices=$(whiptail --title "Web Browsers" --checklist "Select browsers to install:" 15 60 5 \
        "brave" "Brave Browser" OFF \
        "chrome" "Google Chrome" OFF 3>&1 1>&2 2>&3)
    echo $choices
}

select_dev_tools() {
    local choices
    choices=$(whiptail --title "Development Tools" --checklist "Select development tools to install:" 15 60 8 \
        "build-essential" "Build Essential" OFF \
        "vscode" "Visual Studio Code" OFF \
        "git" "Git" OFF \
        "git-cli" "GitHub CLI" OFF \
        "github-desktop" "GitHub Desktop" OFF \
        "miniconda" "Miniconda" OFF 3>&1 1>&2 2>&3)
    echo $choices
}

select_communication() {
    local choices
    choices=$(whiptail --title "Communication Tools" --checklist "Select communication tools to install:" 15 60 5 \
        "discord" "Discord" OFF \
        "anydesk" "AnyDesk" OFF 3>&1 1>&2 2>&3)
    echo $choices
}

select_media_utils() {
    local choices
    choices=$(whiptail --title "Media & Utilities" --checklist "Select utilities to install:" 15 60 5 \
        "vlc" "VLC Media Player" OFF \
        "filezilla" "FileZilla" OFF \
        "virtualbox" "VirtualBox" OFF 3>&1 1>&2 2>&3)
    echo $choices
}

select_network_tools() {
    local choices
    choices=$(whiptail --title "Network Tools" --checklist "Select network tools to install:" 15 60 8 \
        "net-tools" "Net Tools" OFF \
        "wireshark" "Wireshark" OFF \
        "ssh" "SSH Client/Server" OFF \
        "telnet" "Telnet" OFF \
        "monitoring" "Monitoring Tools" OFF 3>&1 1>&2 2>&3)
    echo $choices
}

select_programming() {
    local choices
    choices=$(whiptail --title "Programming Languages" --checklist "Select languages to install:" 15 60 5 \
        "python3" "Python 3" OFF \
        "nodejs" "Node.js" OFF \
        "java" "Java JDK & JRE 17" OFF 3>&1 1>&2 2>&3)
    echo $choices
}

# Installation functions for each software
declare -A selected_software
declare -A installation_status

install_brave() {
    if ! command -v brave-browser &> /dev/null; then
        curl -fsS https://dl.brave.com/install.sh | sh
    fi
}

install_chrome() {
    if ! command -v google-chrome &> /dev/null; then
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo dpkg -i google-chrome-stable_current_amd64.deb
        sudo apt-get install -f -y
        rm google-chrome-stable_current_amd64.deb
    fi
}

install_build_essential() {
    sudo apt-get install build-essential -y
}

install_vscode() {
    if ! command -v code &> /dev/null; then
        sudo apt-get install wget gpg -y
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f packages.microsoft.gpg
        sudo apt install apt-transport-https
        sudo apt update
        sudo apt install code -y
    fi
}

install_git() {
    sudo apt-get install git -y
}

install_git_cli() {
    sudo apt install gh -y
}

install_github_desktop() {
    wget -qO - https://apt.packages.shiftkey.dev/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/shiftkey-packages.gpg > /dev/null
    sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/shiftkey-packages.gpg] https://apt.packages.shiftkey.dev/ubuntu/ any main" > /etc/apt/sources.list.d/shiftkey-packages.list'
    sudo apt update && sudo apt install github-desktop -y
}

install_discord() {
    sudo snap install discord
}

install_anydesk() {
    wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo apt-key add -
    echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
    sudo apt update
    sudo apt install anydesk -y
}

install_vlc() {
    sudo apt install vlc -y
}

install_filezilla() {
    sudo apt-get install filezilla -y
}

install_virtualbox() {
    sudo apt-get install virtualbox -y
}

install_net_tools() {
    sudo apt-get install net-tools -y
}

install_wireshark() {
    sudo add-apt-repository ppa:wireshark-dev/stable -y
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y wireshark
}

install_ssh() {
    sudo apt install openssh-client openssh-server -y
}

install_telnet() {
    sudo apt install telnetd -y
}

install_monitoring() {
    sudo apt-get install nvtop htop nmap sysstat fping traceroute -y
}

install_python3() {
    sudo apt-get install python3 python3-pip -y
}

install_nodejs() {
    sudo snap install node --classic
}

install_java() {
    sudo apt install openjdk-17-jdk openjdk-17-jre -y
}

install_miniconda() {
    mkdir -p ~/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
    rm ~/miniconda3/miniconda.sh
    source ~/miniconda3/bin/activate
    conda init --all
}

# Function to review selections before installation
review_selections() {
    local msg="Selected software for installation:\n\n"
    local count=0
    
    for software in "${!selected_software[@]}"; do
        if [ "${selected_software[$software]}" = "true" ]; then
            count=$((count + 1))
            msg+="$count. $software\n"
        fi
    done
    
    if [ $count -eq 0 ]; then
        whiptail --title "Review" --msgbox "No software selected for installation." 8 40
        return 1
    else
        if whiptail --title "Review" --yesno "$msg\nProceed with installation?" 20 60; then
            return 0
        else
            return 1
        fi
    fi
}

# Function to process installations
process_installations() {
    local total=${#selected_software[@]}
    local current=0
    local success_count=0
    local failed_count=0
    local failed_apps=""

    for software in "${!selected_software[@]}"; do
        if [ "${selected_software[$software]}" = "true" ]; then
            current=$((current + 1))
            percent=$((current * 100 / total))
            
            {
                echo $percent
                case $software in
                    "brave")
                        install_brave
                        ;;
                    "chrome")
                        install_chrome
                        ;;
                    "build-essential")
                        install_build_essential
                        ;;
                    "vscode")
                        install_vscode
                        ;;
                    "git")
                        install_git
                        ;;
                    "git-cli")
                        install_git_cli
                        ;;
                    "github-desktop")
                        install_github_desktop
                        ;;
                    "discord")
                        install_discord
                        ;;
                    "anydesk")
                        install_anydesk
                        ;;
                    "vlc")
                        install_vlc
                        ;;
                    "filezilla")
                        install_filezilla
                        ;;
                    "virtualbox")
                        install_virtualbox
                        ;;
                    "net-tools")
                        install_net_tools
                        ;;
                    "wireshark")
                        install_wireshark
                        ;;
                    "ssh")
                        install_ssh
                        ;;
                    "telnet")
                        install_telnet
                        ;;
                    "monitoring")
                        install_monitoring
                        ;;
                    "python3")
                        install_python3
                        ;;
                    "nodejs")
                        install_nodejs
                        ;;
                    "java")
                        install_java
                        ;;
                    "miniconda")
                        install_miniconda
                        ;;
                esac
            } | whiptail --title "Installing Software" --gauge "Installing $software..." 6 60 $percent

            if [ $? -eq 0 ]; then
                success_count=$((success_count + 1))
            else
                failed_count=$((failed_count + 1))
                failed_apps+="$software "
            fi
        fi
    done

    # Display installation summary
    local summary="Installation Summary:\n"
    summary+="Successfully installed: $success_count\n"
    if [ $failed_count -gt 0 ]; then
        summary+="Failed installations: $failed_count\n"
        summary+="Failed apps: $failed_apps\n"
    fi
    whiptail --title "Installation Complete" --msgbox "$summary" 12 60
}

# Main script execution
main() {
    display_banner
    check_whiptail
    check_dependencies
    update_system

    while true; do
        choice=$(select_category)
        case $choice in
            1) # Web Browsers
                selections=$(select_browsers)
                for item in $selections; do
                    selected_software[${item//\"/}]=true
                done
                ;;
            2) # Development Tools
                selections=$(select_dev_tools)
                for item in $selections; do
                    selected_software[${item//\"/}]=true
                done
                ;;
            3) # Communication Tools
                selections=$(select_communication)
                for item in $selections; do
                    selected_software[${item//\"/}]=true
                done
                ;;
            4) # Media & Utilities
                selections=$(select_media_utils)
                for item in $selections; do
                    selected_software[${item//\"/}]=true
                done
                ;;
            5) # Network Tools
                selections=$(select_network_tools)
                for item in $selections; do
                    selected_software[${item//\"/}]=true
                done
                ;;
            6) # Programming Languages
                selections=$(select_programming)
                for item in $selections; do
                    selected_software[${item//\"/}]=true
                done
                ;;
            7) # Review & Install
                if review_selections; then
                    process_installations
                fi
                ;;
            8) # Exit
                if whiptail --title "Exit" --yesno "Are you sure you want to exit?" 8 40; then
                    clear
                    echo "Thank you for using the installation script! <3"
                    echo "Follow @thatbackendguy for more! <3"
                    echo ""
                    echo "===> For configuring git <==="
                    echo "git config --global user.name '<Your Name>'"
                    echo "git config --global user.email '<Your Email>'"
                    echo ""
                    echo "===> For configuring GitHub CLI <==="
                    echo "gh auth login"
                    echo ""
                    echo "===> LINKS <==="
                    echo ""
                    echo "Website ==> https://www.thatbackendguy.com/"
                    echo "GitHub  ==> https://www.github.com/thatbackendguy/"
                    echo "YouTube ==> https://www.youtube.com/@ThatBackendGuy/"
                    exit 0
                fi
                ;;
            *)
                whiptail --title "Invalid Option" --msgbox "Please select a valid option" 8 40
                ;;
        esac
    done
}

# Execute main function
main