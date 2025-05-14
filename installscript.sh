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
    
    # Ensure whiptail is available for error display
    if command -v whiptail >/dev/null 2>&1; then
        whiptail --title "Error" --msgbox "An error occurred:\nExit code: $exit_code\nLine: $line_no\nCommand: $last_command" 10 60
    else
        echo "Error occurred:"
        echo "Exit code: $exit_code"
        echo "Line: $line_no"
        echo "Command: $last_command"
    fi
}

# Function to check dependencies
check_dependencies() {
    local deps=("wget" "curl" "gpg" "apt-transport-https" "software-properties-common")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null && ! dpkg-query -W -f='${Status}' "$dep" 2>/dev/null | grep -q "install ok installed"; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        if whiptail --title "Missing Dependencies" --yesno "The following dependencies need to be installed: ${missing_deps[*]}\nInstall them now?" 10 60; then
            echo "Installing dependencies: ${missing_deps[*]}"
            sudo apt-get update
            for dep in "${missing_deps[@]}"; do
                sudo apt-get install -y "$dep"
            done
        else
            echo "Dependencies installation cancelled. Exiting."
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
        sudo apt-get install -y whiptail
        
        # Verify installation
        if ! command -v whiptail >/dev/null 2>&1; then
            echo "Failed to install whiptail. Please install it manually with:"
            echo "sudo apt-get install whiptail"
            exit 1
        fi
    fi
}

# Function to detect Linux distribution
detect_distro() {
    # Default to Ubuntu/Debian
    DISTRO="debian"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "fedora" || "$ID" == "centos" || "$ID" == "rhel" ]]; then
            DISTRO="fedora"
        elif [[ "$ID" == "arch" || "$ID" == "manjaro" ]]; then
            DISTRO="arch"
        fi
    fi
    
    echo "Detected distribution type: $DISTRO"
}

# Function to update system packages
update_system() {
    {
        echo 10
        if [ "$DISTRO" == "fedora" ]; then
            sudo dnf check-update 2>&1 || true
        else
            sudo apt-get update 2>&1
        fi
        echo 50
        
        if [ "$DISTRO" == "fedora" ]; then
            sudo dnf upgrade -y 2>&1
        else
            sudo apt-get upgrade -y 2>&1
        fi
        echo 90
        
        if [ "$DISTRO" == "fedora" ]; then
            sudo dnf autoremove -y 2>&1
        else
            sudo apt-get autoremove -y 2>&1
        fi
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
    echo "$choice"
}

# Functions for each category
select_browsers() {
    local choices
    choices=$(whiptail --title "Web Browsers" --checklist "Select browsers to install:" 15 60 5 \
        "brave" "Brave Browser" OFF \
        "chrome" "Google Chrome" OFF 3>&1 1>&2 2>&3)
    echo "$choices"
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
    echo "$choices"
}

select_communication() {
    local choices
    choices=$(whiptail --title "Communication Tools" --checklist "Select communication tools to install:" 15 60 5 \
        "discord" "Discord" OFF \
        "anydesk" "AnyDesk" OFF 3>&1 1>&2 2>&3)
    echo "$choices"
}

select_media_utils() {
    local choices
    choices=$(whiptail --title "Media & Utilities" --checklist "Select utilities to install:" 15 60 5 \
        "vlc" "VLC Media Player" OFF \
        "filezilla" "FileZilla" OFF \
        "virtualbox" "VirtualBox" OFF 3>&1 1>&2 2>&3)
    echo "$choices"
}

select_network_tools() {
    local choices
    choices=$(whiptail --title "Network Tools" --checklist "Select network tools to install:" 15 60 8 \
        "net-tools" "Net Tools" OFF \
        "wireshark" "Wireshark" OFF \
        "ssh" "SSH Client/Server" OFF \
        "telnet" "Telnet" OFF \
        "monitoring" "Monitoring Tools" OFF 3>&1 1>&2 2>&3)
    echo "$choices"
}

select_programming() {
    local choices
    choices=$(whiptail --title "Programming Languages" --checklist "Select languages to install:" 15 60 5 \
        "python3" "Python 3" OFF \
        "nodejs" "Node.js" OFF \
        "java" "Java JDK & JRE 17" OFF 3>&1 1>&2 2>&3)
    echo "$choices"
}

# Installation functions for each software
declare -A selected_software
declare -A installation_status

install_brave() {
    echo "Installing Brave browser..."
    if ! command -v brave-browser &> /dev/null; then
        sudo apt-get install apt-transport-https curl -y
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
        sudo apt-get update
        sudo apt-get install brave-browser -y
    else
        echo "Brave browser is already installed."
    fi
}

install_chrome() {
    echo "Installing Google Chrome..."
    if ! command -v google-chrome &> /dev/null; then
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo apt-get install -y ./google-chrome-stable_current_amd64.deb
        sudo apt-get install -f -y
        rm -f google-chrome-stable_current_amd64.deb
    else
        echo "Google Chrome is already installed."
    fi
}

install_build_essential() {
    echo "Installing build-essential..."
    if [ "$DISTRO" == "fedora" ]; then
        sudo dnf group install "Development Tools" -y
    else
        sudo apt-get install build-essential -y
    fi
}

install_vscode() {
    echo "Installing Visual Studio Code..."
    if ! command -v code &> /dev/null; then
        if [ "$DISTRO" == "debian" ]; then
            sudo apt-get install wget gpg -y
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            rm -f packages.microsoft.gpg
            sudo apt-get update
            sudo apt-get install code -y
        elif [ "$DISTRO" == "fedora" ]; then
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo dnf check-update
            sudo dnf install code -y
        fi
    else
        echo "Visual Studio Code is already installed."
    fi
}

install_git() {
    echo "Installing Git..."
    if [ "$DISTRO" == "fedora" ]; then
        sudo dnf install git -y
    else
        sudo apt-get install git -y
    fi
}

install_git_cli() {
    echo "Installing GitHub CLI..."
    if ! command -v gh &> /dev/null; then
        if [ "$DISTRO" == "debian" ]; then
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update
            sudo apt-get install gh -y
        elif [ "$DISTRO" == "fedora" ]; then
            sudo dnf install 'dnf-command(config-manager)' -y
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install gh -y
        fi
    else
        echo "GitHub CLI is already installed."
    fi
}

install_github_desktop() {
    echo "Installing GitHub Desktop..."
    if ! command -v github-desktop &> /dev/null; then
        if [ "$DISTRO" == "debian" ]; then
            wget -qO - https://apt.packages.shiftkey.dev/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/shiftkey-packages.gpg > /dev/null
            sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/shiftkey-packages.gpg] https://apt.packages.shiftkey.dev/ubuntu/ any main" > /etc/apt/sources.list.d/shiftkey-packages.list'
            sudo apt-get update
            sudo apt-get install github-desktop -y
        elif [ "$DISTRO" == "fedora" ]; then
            sudo rpm --import https://apt.packages.shiftkey.dev/gpg.key
            sudo sh -c 'echo -e "[shiftkey-packages]\nname=GitHub Desktop\nbaseurl=https://rpm.packages.shiftkey.dev/rpm/\nenabled=1\ngpgcheck=1\ngpgkey=https://rpm.packages.shiftkey.dev/gpg.key" > /etc/yum.repos.d/shiftkey-packages.repo'
            sudo dnf install github-desktop -y
        fi
    else
        echo "GitHub Desktop is already installed."
    fi
}

install_discord() {
    echo "Installing Discord..."
    if ! command -v discord &> /dev/null; then
        if command -v snap &> /dev/null; then
            sudo snap install discord
        else
            # Fallback if snap is not available
            if [ "$DISTRO" == "debian" ]; then
                wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"
                sudo apt-get install -y ./discord.deb
                rm -f discord.deb
            elif [ "$DISTRO" == "fedora" ]; then
                sudo dnf install -y https://download.discord.com/app/stable/linux/discord.tar.gz
            fi
        fi
    else
        echo "Discord is already installed."
    fi
}

install_anydesk() {
    echo "Installing AnyDesk..."
    if ! command -v anydesk &> /dev/null; then
        if [ "$DISTRO" == "debian" ]; then
            wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo apt-key add -
            echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
            sudo apt-get update
            sudo apt-get install anydesk -y
        elif [ "$DISTRO" == "fedora" ]; then
            sudo dnf install -y https://download.anydesk.com/linux/anydesk_6.2.0-1_x86_64.rpm
        fi
    else
        echo "AnyDesk is already installed."
    fi
}

install_vlc() {
    echo "Installing VLC media player..."
    if [ "$DISTRO" == "fedora" ]; then
        sudo dnf install vlc -y
    else
        sudo apt-get install vlc -y
    fi
}

install_filezilla() {
    echo "Installing FileZilla..."
    if [ "$DISTRO" == "fedora" ]; then
        sudo dnf install filezilla -y
    else
        sudo apt-get install filezilla -y
    fi
}

install_virtualbox() {
    echo "Installing VirtualBox..."
    if [ "$DISTRO" == "fedora" ]; then
        sudo dnf install VirtualBox -y
    else
        sudo apt-get install virtualbox -y
    fi
}

install_net_tools() {
    echo "Installing net-tools..."
    if [ "$DISTRO" == "fedora" ]; then
        sudo dnf install net-tools -y
    else
        sudo apt-get install net-tools -y
    fi
}

install_wireshark() {
    echo "Installing Wireshark..."
    if [ "$DISTRO" == "debian" ]; then
        sudo add-apt-repository ppa:wireshark-dev/stable -y
        sudo apt-get update
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y wireshark
    elif [ "$DISTRO" == "fedora" ]; then
        sudo dnf install wireshark -y
    fi
}

install_ssh() {
    echo "Installing SSH client/server..."
    if [ "$DISTRO" == "fedora" ]; then
        sudo dnf install openssh-server openssh-clients -y
    else
        sudo apt-get install openssh-client openssh-server -y
    fi
}

install_telnet() {
    echo "Installing Telnet..."
    if [ "$DISTRO" == "fedora" ]; then
        sudo dnf install telnet telnet-server -y
    else
        sudo apt-get install telnetd -y
    fi
}

install_monitoring() {
    echo "Installing monitoring tools..."
    if [ "$DISTRO" == "fedora" ]; then
        sudo dnf install htop nmap sysstat fping traceroute -y
        # nvtop may need additional repos on Fedora
    else
        sudo apt-get install nvtop htop nmap sysstat fping traceroute -y
    fi
}

install_python3() {
    echo "Installing Python 3..."
    if [ "$DISTRO" == "fedora" ]; then
        sudo dnf install python3 python3-pip -y
    else
        sudo apt-get install python3 python3-pip -y
    fi
}

install_nodejs() {
    echo "Installing Node.js..."
    if command -v snap &> /dev/null; then
        sudo snap install node --classic
    else
        # Fallback if snap is not available
        if [ "$DISTRO" == "debian" ]; then
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif [ "$DISTRO" == "fedora" ]; then
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            sudo dnf install -y nodejs
        fi
    fi
}

install_java() {
    echo "Installing Java JDK & JRE 17..."
    if [ "$DISTRO" == "fedora" ]; then
        sudo dnf install java-17-openjdk java-17-openjdk-devel -y
    else
        sudo apt-get install openjdk-17-jdk openjdk-17-jre -y
    fi
}

install_miniconda() {
    echo "Installing Miniconda..."
    if [ ! -d ~/miniconda3 ]; then
        mkdir -p ~/miniconda3
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
        bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
        rm -f ~/miniconda3/miniconda.sh
        # Add to path for current session
        export PATH="$HOME/miniconda3/bin:$PATH"
        
        # Add initialization to ~/.bashrc if not already present
        if ! grep -q "# >>> conda initialize >>>" ~/.bashrc; then
            ~/miniconda3/bin/conda init bash
            # Also initialize for zsh if it exists
            if command -v zsh &> /dev/null; then
                ~/miniconda3/bin/conda init zsh
            fi
        fi
        
        echo "Miniconda installed. Please restart your terminal or run 'source ~/.bashrc' to complete setup."
    else
        echo "Miniconda is already installed."
    fi
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
    local total=0
    for software in "${!selected_software[@]}"; do
        if [ "${selected_software[$software]}" = "true" ]; then
            total=$((total + 1))
        fi
    done
    
    if [ $total -eq 0 ]; then
        whiptail --title "Installation" --msgbox "No software selected for installation." 8 40
        return
    fi
    
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
                
                # Store the output and error in variables
                output=$(install_"${software}" 2>&1) || {
                    echo "Failed to install $software: $output"
                    failed_count=$((failed_count + 1))
                    failed_apps+="$software "
                    continue
                }
                
                success_count=$((success_count + 1))
                
            } | whiptail --title "Installing Software" --gauge "Installing $software... ($current/$total)" 8 70 $percent
        fi
    done

    # Display installation summary
    local summary="Installation Summary:\n"
    summary+="Successfully installed: $success_count\n"
    if [ $failed_count -gt 0 ]; then
        summary+="Failed installations: $failed_count\n"
        summary+="Failed apps: $failed_apps\n"
        summary+="\nCheck the terminal output for more details."
    fi
    whiptail --title "Installation Complete" --msgbox "$summary" 12 60
}

# Function to check if running as root and warn if needed
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        whiptail --title "Warning" --yesno "Running this script as root is not recommended. It's better to run as a regular user with sudo privileges.\n\nDo you want to continue anyway?" 10 70
        
        if [ $? -ne 0 ]; then
            echo "Script execution cancelled."
            exit 1
        fi
    fi
}

# Main script execution
main() {
    display_banner
    check_root
    detect_distro
    check_whiptail
    check_dependencies
    update_system

    while true; do
        choice=$(select_category)
        case $choice in
            1) # Web Browsers
                selections=$(select_browsers)
                for item in $selections; do
                    # Remove quotes from the item
                    clean_item=$(echo "$item" | sed 's/"//g')
                    selected_software["$clean_item"]=true
                done
                ;;
            2) # Development Tools
                selections=$(select_dev_tools)
                for item in $selections; do
                    clean_item=$(echo "$item" | sed 's/"//g')
                    selected_software["$clean_item"]=true
                done
                ;;
            3) # Communication Tools
                selections=$(select_communication)
                for item in $selections; do
                    clean_item=$(echo "$item" | sed 's/"//g')
                    selected_software["$clean_item"]=true
                done
                ;;
            4) # Media & Utilities
                selections=$(select_media_utils)
                for item in $selections; do
                    clean_item=$(echo "$item" | sed 's/"//g')
                    selected_software["$clean_item"]=true
                done
                ;;
            5) # Network Tools
                selections=$(select_network_tools)
                for item in $selections; do
                    clean_item=$(echo "$item" | sed 's/"//g')
                    selected_software["$clean_item"]=true
                done
                ;;
            6) # Programming Languages
                selections=$(select_programming)
                for item in $selections; do
                    clean_item=$(echo "$item" | sed 's/"//g')
                    selected_software["$clean_item"]=true
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
            *) # No selection or ESC pressed
                if [ -z "$choice" ]; then
                    if whiptail --title "Exit" --yesno "No selection made. Do you want to exit?" 8 40; then
                        clear
                        echo "Thank you for using the installation script!"
                        exit 0
                    fi
                else
                    whiptail --title "Invalid Option" --msgbox "Please select a valid option" 8 40
                fi
                ;;
        esac
    done
}

# Execute main function
main