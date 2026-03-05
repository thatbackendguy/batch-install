#!/bin/bash
set -euo pipefail

# thatbackendguy's Linux Software Installer
# https://www.thatbackendguy.com/

# ─── Colours ─────────────────────────────────────────────────────────────────
BOLD='\033[1m'
ACCENT='\033[38;2;255;77;77m'
INFO='\033[38;2;136;146;176m'
SUCCESS='\033[38;2;0;229;204m'
WARN='\033[38;2;255;176;32m'
ERROR='\033[38;2;230;57;70m'
MUTED='\033[38;2;90;100;128m'
NC='\033[0m'

# ─── Temp-file tracking ──────────────────────────────────────────────────────
TMPFILES=()
cleanup_tmpfiles() {
    local f
    for f in "${TMPFILES[@]:-}"; do rm -rf "$f" 2>/dev/null || true; done
}
trap cleanup_tmpfiles EXIT

mktempfile() {
    local f; f="$(mktemp)"; TMPFILES+=("$f"); echo "$f"
}

# ─── UI helpers ──────────────────────────────────────────────────────────────
ui_info()     { echo -e "${MUTED}·${NC} $*"; }
ui_warn()     { echo -e "${WARN}!${NC} $*" >&2; }
ui_success()  { echo -e "${SUCCESS}✓${NC} $*"; }
ui_error()    { echo -e "${ERROR}✗${NC} $*" >&2; }
ui_section()  { echo ""; echo -e "${ACCENT}${BOLD}$*${NC}"; }
ui_stage()    { echo ""; echo -e "${ACCENT}${BOLD}══  $*  ══${NC}"; echo ""; }
ui_kv()       { echo -e "${MUTED}$1:${NC} $2"; }
ui_celebrate(){ echo -e "${SUCCESS}${BOLD}$*${NC}"; }

# ─── Quiet step runner ───────────────────────────────────────────────────────
# Suppresses output on success; prints a log tail on failure.
# Do NOT use for steps that need interactive stdin (EULA dialogs etc.).
run_quiet_step() {
    local title="$1"; shift
    local log; log="$(mktempfile)"
    ui_info "$title ..."
    if "$@" >"$log" 2>&1; then return 0; fi
    ui_error "${title} failed"
    [[ -s "$log" ]] && tail -n 40 "$log" >&2 || true
    return 1
}

# ─── Privilege helper ────────────────────────────────────────────────────────
is_root() { [[ "$(id -u)" -eq 0 ]]; }

maybe_sudo() {
    if is_root; then "$@"; else sudo "$@"; fi
}

# ─── Package Registry ────────────────────────────────────────────────────────
# Each entry: "key|Display Label|supported_distros"
# supported_distros: "all", "debian", "fedora", or space-separated combo.
# The key must exactly match the install_<key> function name.

PKGS_BROWSERS=(
    "brave|Brave Browser|all"
    "chrome|Google Chrome|debian"
    "chromium|Chromium|all"
    "opera|Opera Browser|debian"
    "tor|Tor Browser Launcher|debian"
)

PKGS_DEV=(
    "git|Git|all"
    "vscode|Visual Studio Code|all"
    "build-essential|Build Essential / Dev Tools|all"
    "make|GNU Make|all"
    "neovim|Neovim|all"
    "tmux|Tmux|all"
    "git-cli|GitHub CLI|all"
    "docker|Docker Engine|all"
    "postman|Postman API Client|all"
    "miniconda|Miniconda (Python env manager)|all"
)

PKGS_COMM=(
    "discord|Discord|all"
    "slack|Slack|debian"
    "zoom|Zoom|debian"
    "teams|Microsoft Teams|debian"
    "telegram|Telegram Desktop|all"
    "signal|Signal Desktop|debian"
)

PKGS_MEDIA=(
    "vlc|VLC Media Player|all"
    "gimp|GIMP Image Editor|all"
    "obs|OBS Studio|all"
    "kdenlive|Kdenlive Video Editor|all"
    "handbrake|HandBrake|all"
    "spotify|Spotify|debian"
    "filezilla|FileZilla FTP Client|all"
)

PKGS_NETWORK=(
    "net-tools|Net Tools (ifconfig, netstat)|all"
    "wireshark|Wireshark|all"
    "ssh|OpenSSH Client + Server|all"
    "openvpn|OpenVPN|all"
    "tailscale|Tailscale VPN|all"
    "telnet|Telnet|all"
    "monitoring|Monitoring Suite (htop, nmap, fping...)|all"
)

PKGS_LANG=(
    "python3|Python 3 + pip|all"
    "nodejs|Node.js 18.x|all"
    "go|Go Language|all"
    "rust|Rust (via rustup)|all"
    "java|Java JDK & JRE 17|all"
)

# Recommended preset — keys must exist in the registries above.
RECOMMENDED_PKGS=(
    "git" "vscode" "build-essential" "neovim" "tmux"
    "python3" "nodejs" "vlc" "monitoring"
)

# ─── Installed-state detection ───────────────────────────────────────────────
# Returns 0 (true) if the package is already on the system.
pkg_is_installed() {
    local key="$1"
    case "$key" in
        # Browsers
        brave)            command -v brave-browser      &>/dev/null ;;
        chrome)           command -v google-chrome      &>/dev/null ;;
        chromium)         command -v chromium-browser   &>/dev/null \
                       || command -v chromium           &>/dev/null ;;
        opera)            command -v opera              &>/dev/null ;;
        tor)              command -v torbrowser-launcher &>/dev/null ;;
        # Dev
        git)              command -v git                &>/dev/null ;;
        vscode)           command -v code               &>/dev/null ;;
        build-essential)  command -v gcc                &>/dev/null ;;
        make)             command -v make               &>/dev/null ;;
        neovim)           command -v nvim               &>/dev/null ;;
        tmux)             command -v tmux               &>/dev/null ;;
        git-cli)          command -v gh                 &>/dev/null ;;
        docker)           command -v docker             &>/dev/null ;;
        postman)          command -v postman            &>/dev/null ;;
        miniconda)        [[ -d "$HOME/miniconda3" ]]               ;;
        # Comm
        discord)          command -v discord            &>/dev/null ;;
        slack)            command -v slack              &>/dev/null ;;
        zoom)             command -v zoom               &>/dev/null ;;
        teams)            command -v teams              &>/dev/null ;;
        telegram)         command -v telegram-desktop   &>/dev/null ;;
        signal)           command -v signal-desktop     &>/dev/null ;;
        # Media
        vlc)              command -v vlc                &>/dev/null ;;
        gimp)             command -v gimp               &>/dev/null ;;
        obs)              command -v obs                &>/dev/null ;;
        kdenlive)         command -v kdenlive           &>/dev/null ;;
        handbrake)        command -v ghb                &>/dev/null ;;
        spotify)          command -v spotify            &>/dev/null ;;
        filezilla)        command -v filezilla          &>/dev/null ;;
        # Network
        net-tools)        command -v ifconfig           &>/dev/null ;;
        wireshark)        command -v wireshark          &>/dev/null ;;
        ssh)              command -v ssh                &>/dev/null ;;
        openvpn)          command -v openvpn            &>/dev/null ;;
        tailscale)        command -v tailscale          &>/dev/null ;;
        telnet)           command -v telnet             &>/dev/null ;;
        monitoring)       command -v htop               &>/dev/null ;;
        # Languages
        python3)          command -v python3            &>/dev/null ;;
        nodejs)           command -v node               &>/dev/null ;;
        go)               command -v go                 &>/dev/null ;;
        rust)             command -v rustc              &>/dev/null ;;
        java)             command -v java               &>/dev/null ;;
        *)                return 1 ;;
    esac
}

# Returns 0 if the package entry's distro list covers the current DISTRO.
pkg_supported() {
    local distros="$1"
    [[ "$distros" == "all" ]]         && return 0
    [[ "$distros" == *"$DISTRO"* ]]   && return 0
    return 1
}

# ─── Banner ──────────────────────────────────────────────────────────────────
display_banner() {
    clear
    echo -e "${ACCENT}${BOLD}"
    echo " _   _           _   _                _                  _                   "
    echo "| | | |         | | | |              | |                | |                  "
    echo "| |_| |__   __ _| |_| |__   __ _  ___| | _____ _ __   __| | __ _ _   _ _   _"
    echo "| __| '_ \\ / _\` | __| '_ \\ / _\` |/ __| |/ / _ \\ '_ \\ / _\` |/ _\` | | | | | |"
    echo "| |_| | | | (_| | |_| |_) | (_| | (__|   <  __/ | | | (_| | (_| | |_| | |_| |"
    echo " \\__|_| |_|\\__,_|\\__|_.__/ \\__,_|\\___|_|\\_\\___|_| |_|\\__,_|\\__, |\\__,_|\\__, |"
    echo "                                                              __/ |        __/ |"
    echo "                                                             |___/        |___/ "
    echo -e "${NC}${INFO}  Linux Software Installer  ·  @thatbackendguy${NC}"
    echo ""
    sleep 1
}

# ─── Root / whiptail / distro bootstrap ──────────────────────────────────────
DISTRO="debian"

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        case "${ID:-}" in
            fedora|centos|rhel) DISTRO="fedora" ;;
            arch|manjaro)       DISTRO="arch"   ;;
            *)                  DISTRO="debian" ;;
        esac
    fi
    ui_kv "Detected distro" "$DISTRO"
}

check_whiptail() {
    command -v whiptail >/dev/null 2>&1 && return 0
    ui_info "whiptail not found — installing..."
    run_quiet_step "Installing whiptail" maybe_sudo apt-get install -y whiptail
    if ! command -v whiptail >/dev/null 2>&1; then
        ui_error "Failed to install whiptail.  Run: sudo apt-get install whiptail"
        exit 1
    fi
    ui_success "whiptail installed"
}

check_root() {
    is_root || return 0
    ui_warn "Running as root is not recommended."
    echo -e "${INFO}Safer to run as a regular user with sudo privileges.${NC}"
    echo ""
    read -r -p "Continue anyway? [y/N] " confirm </dev/tty
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 1; }
}

check_dependencies() {
    local deps=("wget" "curl" "gpg" "apt-transport-https" "software-properties-common")
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null && \
           ! dpkg-query -W -f='${Status}' "$dep" 2>/dev/null | grep -q "install ok installed"; then
            missing+=("$dep")
        fi
    done
    if [[ ${#missing[@]} -eq 0 ]]; then
        ui_success "All base dependencies satisfied"
        return 0
    fi
    ui_info "Missing: ${missing[*]}"
    if whiptail --title "Missing Dependencies" \
                --yesno "These packages are needed:\n\n  ${missing[*]}\n\nInstall them now?" \
                12 60 3>&1 1>&2 2>&3; then
        run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
        for dep in "${missing[@]}"; do
            run_quiet_step "Installing $dep" maybe_sudo apt-get install -y "$dep"
        done
        ui_success "Dependencies installed"
    else
        ui_error "Cannot continue without required dependencies."; exit 1
    fi
}

update_system() {
    if ! whiptail --title "System Update" \
                  --yesno "Update system packages before installing?" \
                  8 60 3>&1 1>&2 2>&3; then
        ui_info "System update skipped"; return 0
    fi
    ui_stage "Updating system packages"
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Checking for updates"      maybe_sudo dnf check-update || true
        run_quiet_step "Upgrading packages"        maybe_sudo dnf upgrade -y
        run_quiet_step "Removing unused packages"  maybe_sudo dnf autoremove -y
    else
        run_quiet_step "Updating package index"    maybe_sudo apt-get update -qq
        run_quiet_step "Upgrading packages"        maybe_sudo apt-get upgrade -y
        run_quiet_step "Removing unused packages"  maybe_sudo apt-get autoremove -y
    fi
    ui_success "System update complete"
}

# ─── Selection state ─────────────────────────────────────────────────────────
declare -A selected_software=()

count_selected() {
    local n=0
    local sw
    for sw in "${!selected_software[@]}"; do
        [[ "${selected_software[$sw]:-}" == "true" ]] && n=$((n + 1))
    done
    echo "$n"
}

# ─── Generic checklist handler ───────────────────────────────────────────────
# Builds a whiptail checklist from a named package array, honouring:
#   • distro filtering  (unsupported entries hidden)
#   • already-installed labelling  ([installed] suffix, pre-checked)
#   • persistent prior selection   (previously checked items stay ON)
# After the user confirms, it updates selected_software for every key that
# belongs to this category (handling both selection AND deselection).
handle_category() {
    local title="$1"
    local prompt="$2"
    local -n _cat_arr="$3"   # nameref — requires bash 4.3+

    local wt_args=()
    for entry in "${_cat_arr[@]}"; do
        local key label distros
        IFS='|' read -r key label distros <<< "$entry"
        pkg_supported "$distros" || continue

        local display="$label"
        local state="OFF"

        if pkg_is_installed "$key"; then
            display+=" [installed]"
            state="ON"      # pre-check installed packages
        fi
        # Honour prior selection (e.g. user re-enters same category)
        [[ "${selected_software[$key]:-}" == "true" ]] && state="ON"

        wt_args+=("$key" "$display" "$state")
    done

    if [[ ${#wt_args[@]} -eq 0 ]]; then
        whiptail --title "$title" \
                 --msgbox "No packages available for your distro ($DISTRO)." \
                 8 56 3>&1 1>&2 2>&3
        return 0
    fi

    local list_h=$(( ${#wt_args[@]} / 3 ))
    local height=$(( list_h + 8 ))
    [[ $height -lt 12 ]] && height=12
    [[ $height -gt 24 ]] && height=24
    [[ $list_h -gt $((height - 8)) ]] && list_h=$((height - 8))

    local raw exit_code
    set +e
    raw=$(whiptail --title "$title" \
                   --checklist "$prompt\n(Space = toggle, Enter = confirm, Esc = cancel)" \
                   "$height" 74 "$list_h" \
                   "${wt_args[@]}" \
                   3>&1 1>&2 2>&3)
    exit_code=$?
    set -e

    # ESC / Cancel → leave selections completely unchanged
    [[ $exit_code -ne 0 ]] && return 0

    # Build a set of what is now checked
    local -A newly_checked=()
    local item clean
    for item in $raw; do
        clean="${item//\"/}"
        [[ -n "$clean" ]] && newly_checked["$clean"]=1
    done

    # Update selected_software for every key that belongs to this category
    for entry in "${_cat_arr[@]}"; do
        local key distros
        IFS='|' read -r key _ distros <<< "$entry"
        pkg_supported "$distros" || continue

        if [[ -n "${newly_checked[$key]:-}" ]]; then
            selected_software["$key"]="true"
        else
            # Key was visible but unchecked — remove it from the queue
            unset "selected_software[$key]" 2>/dev/null || true
        fi
    done
}

# ─── Recommended preset ──────────────────────────────────────────────────────
apply_recommended() {
    local msg="These packages will be queued for install:\n\n"
    local pkg
    for pkg in "${RECOMMENDED_PKGS[@]}"; do
        if pkg_is_installed "$pkg"; then
            msg+="  • $pkg  [already installed]\n"
        else
            msg+="  • $pkg\n"
        fi
    done

    if whiptail --title "⚡ Quick Install — Recommended" \
                --yesno "${msg}\nQueue all of the above?" \
                22 62 3>&1 1>&2 2>&3; then
        for pkg in "${RECOMMENDED_PKGS[@]}"; do
            selected_software["$pkg"]="true"
        done
        local n="${#RECOMMENDED_PKGS[@]}"
        whiptail --title "Quick Install" \
                 --msgbox "✓ $n packages queued.\n\nVisit categories to add more,\nor choose  'Review & Install'  when ready." \
                 11 58 3>&1 1>&2 2>&3
    fi
}

# ─── Review & Edit screen ────────────────────────────────────────────────────
# Shows a checklist of everything queued so far.
# The user can UNCHECK items to remove them before installing.
review_and_edit() {
    local wt_args=()
    local sw
    for sw in "${!selected_software[@]}"; do
        [[ "${selected_software[$sw]:-}" != "true" ]] && continue
        local suffix=""
        pkg_is_installed "$sw" && suffix=" [installed]"
        wt_args+=("$sw" "${sw}${suffix}" "ON")
    done

    if [[ ${#wt_args[@]} -eq 0 ]]; then
        whiptail --title "Nothing Selected" \
                 --msgbox "No software queued yet.\n\nUse categories 1-6 or the Quick Install preset." \
                 10 58 3>&1 1>&2 2>&3
        return 1
    fi

    local list_h=$(( ${#wt_args[@]} / 3 ))
    local height=$(( list_h + 10 ))
    [[ $height -lt 12 ]] && height=12
    [[ $height -gt 24 ]] && height=24
    [[ $list_h -gt $((height - 10)) ]] && list_h=$((height - 10))

    local raw exit_code
    set +e
    raw=$(whiptail --title "Review & Edit Queue" \
                   --checklist "Uncheck items to remove them before installing:" \
                   "$height" 68 "$list_h" \
                   "${wt_args[@]}" \
                   3>&1 1>&2 2>&3)
    exit_code=$?
    set -e

    # ESC / Cancel → do nothing
    [[ $exit_code -ne 0 ]] && return 1

    # Reset the entire selection, then restore only what was checked
    for sw in "${!selected_software[@]}"; do
        unset "selected_software[$sw]" 2>/dev/null || true
    done
    local item clean
    for item in $raw; do
        clean="${item//\"/}"
        [[ -n "$clean" ]] && selected_software["$clean"]="true"
    done

    local n; n="$(count_selected)"
    if [[ $n -eq 0 ]]; then
        whiptail --title "Queue Empty" \
                 --msgbox "All items were unchecked — nothing to install." \
                 8 52 3>&1 1>&2 2>&3
        return 1
    fi

    # Final confirmation
    local msg="Ready to install $n package(s):\n\n"
    for sw in "${!selected_software[@]}"; do
        [[ "${selected_software[$sw]:-}" == "true" ]] && msg+="  • $sw\n"
    done
    whiptail --title "Confirm Installation" \
             --yesno "${msg}\nProceed?" \
             22 60 3>&1 1>&2 2>&3
}

# ─── Main menu ───────────────────────────────────────────────────────────────
# Shows a count badge on the Review item so users always see how many
# packages are queued without having to enter the review screen.
select_category() {
    local n; n="$(count_selected)"
    local review_label="Review & Install Selected"
    [[ $n -gt 0 ]] && review_label="Review & Install  ($n selected)"

    whiptail --title "Software Installation Menu" \
             --menu "Choose a category:" 22 68 12 \
        "0" "⚡  Quick Install — Recommended preset" \
        "1" "🌐  Web Browsers" \
        "2" "🔧  Development Tools" \
        "3" "💬  Communication Tools" \
        "4" "🎬  Media & Utilities" \
        "5" "🌐  Network Tools" \
        "6" "📦  Programming Languages" \
        "7" "✅  ${review_label}" \
        "8" "🚪  Exit" \
        3>&1 1>&2 2>&3 || true
}

# ─── Installation functions ───────────────────────────────────────────────────
# Rules:
#   • Every function name must be install_<key> where <key> matches the registry.
#   • Non-interactive steps go through run_quiet_step (output hidden on success).
#   • ANY step that might prompt the user (EULA, debconf, licence dialogs) must
#     run directly — NO output redirection — so stdin/stdout stay on the terminal.

# — Browsers ——————————————————————————————————————————————————————————————————

install_brave() {
    command -v brave-browser &>/dev/null && { ui_info "brave: already installed"; return 0; }
    curl -fsS https://dl.brave.com/install.sh | sh
}

install_chrome() {
    command -v google-chrome &>/dev/null && { ui_info "chrome: already installed"; return 0; }
    local deb; deb="$(mktempfile)"
    run_quiet_step "Downloading Chrome" \
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O "$deb"
    maybe_sudo dpkg -i "$deb"
    run_quiet_step "Fixing dependencies" maybe_sudo apt-get install -f -y
}


install_chromium() {
    { command -v chromium-browser &>/dev/null || command -v chromium &>/dev/null; } \
        && { ui_info "chromium: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing chromium" maybe_sudo dnf install -y chromium
    else
        run_quiet_step "Installing chromium" maybe_sudo apt-get install -y chromium-browser
    fi
}

install_opera() {
    command -v opera &>/dev/null && { ui_info "opera: already installed"; return 0; }
    run_quiet_step "Fetching Opera keyring" \
        bash -c "wget -qO- https://deb.opera.com/archive.key | sudo apt-key add -"
    echo "deb https://deb.opera.com/opera-stable/ stable non-free" \
        | maybe_sudo tee /etc/apt/sources.list.d/opera-stable.list >/dev/null
    run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
    maybe_sudo apt-get install -y opera-stable
}

install_tor() {
    command -v torbrowser-launcher &>/dev/null && { ui_info "tor: already installed"; return 0; }
    run_quiet_step "Adding Tor PPA" \
        maybe_sudo add-apt-repository -y ppa:micahflee/ppa
    run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
    run_quiet_step "Installing torbrowser-launcher" \
        maybe_sudo apt-get install -y torbrowser-launcher
}

# — Development ———————————————————————————————————————————————————————————————

install_git() {
    command -v git &>/dev/null && { ui_info "git: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing git" maybe_sudo dnf install -y git
    else
        run_quiet_step "Installing git" maybe_sudo apt-get install -y git
    fi
}

install_vscode() {
    command -v code &>/dev/null && { ui_info "vscode: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Importing VS Code GPG key" \
            maybe_sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        printf '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n' \
            | maybe_sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
        maybe_sudo dnf install -y code
    else
        local tmp_gpg; tmp_gpg="$(mktempfile)"
        run_quiet_step "Fetching VS Code GPG key" \
            bash -c "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > '$tmp_gpg'"
        maybe_sudo install -D -o root -g root -m 644 "$tmp_gpg" \
            /etc/apt/keyrings/packages.microsoft.gpg
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
            | maybe_sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
        run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
        maybe_sudo apt-get install -y code
    fi
}

install_build-essential() {
    if [[ "$DISTRO" == "fedora" ]]; then
        maybe_sudo dnf group install -y "Development Tools"
    else
        run_quiet_step "Installing build-essential" \
            maybe_sudo apt-get install -y build-essential
    fi
}

install_make() {
    command -v make &>/dev/null && { ui_info "make: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing make" maybe_sudo dnf install -y make
    else
        run_quiet_step "Installing make" maybe_sudo apt-get install -y make
    fi
}

install_neovim() {
    command -v nvim &>/dev/null && { ui_info "neovim: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing neovim" maybe_sudo dnf install -y neovim
    else
        run_quiet_step "Adding Neovim PPA" \
            maybe_sudo add-apt-repository -y ppa:neovim-ppa/stable
        run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
        run_quiet_step "Installing neovim" maybe_sudo apt-get install -y neovim
    fi
}

install_tmux() {
    command -v tmux &>/dev/null && { ui_info "tmux: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing tmux" maybe_sudo dnf install -y tmux
    else
        run_quiet_step "Installing tmux" maybe_sudo apt-get install -y tmux
    fi
}

install_git-cli() {
    command -v gh &>/dev/null && { ui_info "gh: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Adding GitHub CLI repo" \
            maybe_sudo dnf install -y 'dnf-command(config-manager)'
        maybe_sudo dnf config-manager --add-repo \
            https://cli.github.com/packages/rpm/gh-cli.repo
        run_quiet_step "Installing gh" maybe_sudo dnf install -y gh
    else
        run_quiet_step "Fetching GitHub CLI keyring" \
            bash -c "curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
                | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
        maybe_sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
            | maybe_sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
        run_quiet_step "Installing gh" maybe_sudo apt-get install -y gh
    fi
}

install_docker() {
    command -v docker &>/dev/null && { ui_info "docker: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Adding Docker repo" \
            maybe_sudo dnf config-manager --add-repo \
                https://download.docker.com/linux/fedora/docker-ce.repo
        run_quiet_step "Installing Docker" \
            maybe_sudo dnf install -y docker-ce docker-ce-cli containerd.io \
                docker-buildx-plugin docker-compose-plugin
    else
        run_quiet_step "Fetching Docker keyring" \
            bash -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
                | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
        echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
            | maybe_sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
        run_quiet_step "Installing Docker" \
            maybe_sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
                docker-buildx-plugin docker-compose-plugin
    fi
    maybe_sudo systemctl enable --now docker 2>/dev/null || true
    maybe_sudo usermod -aG docker "$USER" 2>/dev/null || true
    ui_info "Log out and back in (or run 'newgrp docker') to use Docker without sudo"
}

install_postman() {
    command -v postman &>/dev/null && { ui_info "postman: already installed"; return 0; }
    if command -v snap &>/dev/null; then
        maybe_sudo snap install postman
    else
        # Fallback: download tarball and install to /opt
        local tmp; tmp="$(mktemp -d)"; TMPFILES+=("$tmp")
        run_quiet_step "Downloading Postman" \
            wget -q "https://dl.pstmn.io/download/latest/linux64" -O "$tmp/postman.tar.gz"
        run_quiet_step "Extracting Postman" \
            tar -xzf "$tmp/postman.tar.gz" -C "$tmp"
        maybe_sudo mv "$tmp/Postman" /opt/Postman
        maybe_sudo ln -sf /opt/Postman/Postman /usr/local/bin/postman
        ui_info "Postman installed to /opt/Postman"
    fi
}

install_miniconda() {
    [[ -d "$HOME/miniconda3" ]] && { ui_info "miniconda: already installed"; return 0; }
    mkdir -p "$HOME/miniconda3"
    local installer="$HOME/miniconda3/miniconda.sh"
    run_quiet_step "Downloading Miniconda installer" \
        wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
             -O "$installer"
    bash "$installer" -b -u -p "$HOME/miniconda3"
    rm -f "$installer"
    export PATH="$HOME/miniconda3/bin:$PATH"
    if ! grep -q "# >>> conda initialize >>>" "$HOME/.bashrc" 2>/dev/null; then
        "$HOME/miniconda3/bin/conda" init bash
        command -v zsh &>/dev/null && "$HOME/miniconda3/bin/conda" init zsh
    fi
    ui_info "Miniconda ready — run 'source ~/.bashrc' or restart your terminal"
}

# — Communication ——————————————————————————————————————————————————————————————

install_discord() {
    command -v discord &>/dev/null && { ui_info "discord: already installed"; return 0; }
    if command -v snap &>/dev/null; then
        maybe_sudo snap install discord
    elif [[ "$DISTRO" == "fedora" ]]; then
        maybe_sudo dnf install -y https://download.discord.com/app/stable/linux/discord.tar.gz
    else
        local deb; deb="$(mktempfile)"
        run_quiet_step "Downloading Discord" \
            wget -q "https://discord.com/api/download?platform=linux&format=deb" -O "$deb"
        maybe_sudo apt-get install -y "$deb"
    fi
}

install_slack() {
    command -v slack &>/dev/null && { ui_info "slack: already installed"; return 0; }
    if command -v snap &>/dev/null; then
        maybe_sudo snap install slack --classic
    else
        local deb; deb="$(mktempfile)"
        run_quiet_step "Downloading Slack" \
            wget -q "https://downloads.slack-edge.com/desktop-releases/linux/x64/latest/slack-desktop-latest-amd64.deb" \
                 -O "$deb"
        maybe_sudo apt-get install -y "$deb"
    fi
}

install_zoom() {
    command -v zoom &>/dev/null && { ui_info "zoom: already installed"; return 0; }
    local deb; deb="$(mktempfile)"
    run_quiet_step "Downloading Zoom" \
        wget -q "https://zoom.us/client/latest/zoom_amd64.deb" -O "$deb"
    maybe_sudo apt-get install -y "$deb"
    run_quiet_step "Fixing dependencies" maybe_sudo apt-get install -f -y
}

install_teams() {
    command -v teams &>/dev/null && { ui_info "teams: already installed"; return 0; }
    if command -v snap &>/dev/null; then
        maybe_sudo snap install teams-for-linux
    else
        run_quiet_step "Importing Teams GPG key" \
            bash -c "curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
                | sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg"
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/ms-teams stable main" \
            | maybe_sudo tee /etc/apt/sources.list.d/teams.list >/dev/null
        run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
        run_quiet_step "Installing teams" maybe_sudo apt-get install -y teams
    fi
}

install_telegram() {
    command -v telegram-desktop &>/dev/null && { ui_info "telegram: already installed"; return 0; }
    if command -v snap &>/dev/null; then
        maybe_sudo snap install telegram-desktop
    elif [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing telegram" maybe_sudo dnf install -y telegram-desktop
    else
        run_quiet_step "Installing telegram" maybe_sudo apt-get install -y telegram-desktop
    fi
}

install_signal() {
    command -v signal-desktop &>/dev/null && { ui_info "signal: already installed"; return 0; }
    run_quiet_step "Fetching Signal keyring" \
        bash -c "wget -qO- https://updates.signal.org/desktop/apt/keys.asc \
            | sudo apt-key add -"
    echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" \
        | maybe_sudo tee /etc/apt/sources.list.d/signal-xenial.list >/dev/null
    run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
    run_quiet_step "Installing signal-desktop" \
        maybe_sudo apt-get install -y signal-desktop
}

# — Media & Utilities ——————————————————————————————————————————————————————————

install_vlc() {
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing vlc" maybe_sudo dnf install -y vlc
    else
        run_quiet_step "Installing vlc" maybe_sudo apt-get install -y vlc
    fi
}

install_gimp() {
    command -v gimp &>/dev/null && { ui_info "gimp: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing gimp" maybe_sudo dnf install -y gimp
    else
        run_quiet_step "Installing gimp" maybe_sudo apt-get install -y gimp
    fi
}

install_obs() {
    command -v obs &>/dev/null && { ui_info "obs: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing OBS" maybe_sudo dnf install -y obs-studio
    else
        run_quiet_step "Adding OBS PPA" \
            maybe_sudo add-apt-repository -y ppa:obsproject/obs-studio
        run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
        run_quiet_step "Installing OBS" maybe_sudo apt-get install -y obs-studio
    fi
}

install_kdenlive() {
    command -v kdenlive &>/dev/null && { ui_info "kdenlive: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing kdenlive" maybe_sudo dnf install -y kdenlive
    else
        run_quiet_step "Installing kdenlive" maybe_sudo apt-get install -y kdenlive
    fi
}

install_handbrake() {
    command -v ghb &>/dev/null && { ui_info "handbrake: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing HandBrake" maybe_sudo dnf install -y HandBrake-gui
    else
        run_quiet_step "Adding HandBrake PPA" \
            maybe_sudo add-apt-repository -y ppa:stebbins/handbrake-releases
        run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
        run_quiet_step "Installing HandBrake" maybe_sudo apt-get install -y handbrake-gtk
    fi
}

install_spotify() {
    command -v spotify &>/dev/null && { ui_info "spotify: already installed"; return 0; }
    if command -v snap &>/dev/null; then
        maybe_sudo snap install spotify
    else
        run_quiet_step "Fetching Spotify keyring" \
            bash -c "curl -fsSL https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg \
                | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg"
        echo "deb http://repository.spotify.com stable non-free" \
            | maybe_sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null
        run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
        run_quiet_step "Installing spotify" maybe_sudo apt-get install -y spotify-client
    fi
}

install_filezilla() {
    command -v filezilla &>/dev/null && { ui_info "filezilla: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing filezilla" maybe_sudo dnf install -y filezilla
    else
        run_quiet_step "Installing filezilla" maybe_sudo apt-get install -y filezilla
    fi
}

# — Network Tools ——————————————————————————————————————————————————————————————

install_net-tools() {
    command -v ifconfig &>/dev/null && { ui_info "net-tools: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing net-tools" maybe_sudo dnf install -y net-tools
    else
        run_quiet_step "Installing net-tools" maybe_sudo apt-get install -y net-tools
    fi
}

install_wireshark() {
    command -v wireshark &>/dev/null && { ui_info "wireshark: already installed"; return 0; }
    # Wireshark shows a debconf dialog about non-root packet capture — run directly.
    ui_info "Wireshark may ask about non-root packet capture — please respond below:"
    if [[ "$DISTRO" == "fedora" ]]; then
        maybe_sudo dnf install -y wireshark
    else
        run_quiet_step "Adding Wireshark PPA" \
            maybe_sudo add-apt-repository -y ppa:wireshark-dev/stable
        run_quiet_step "Updating package index" maybe_sudo apt-get update -qq
        maybe_sudo apt-get install -y wireshark
    fi
}

install_ssh() {
    command -v ssh &>/dev/null && { ui_info "ssh: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing OpenSSH" \
            maybe_sudo dnf install -y openssh-server openssh-clients
    else
        run_quiet_step "Installing OpenSSH" \
            maybe_sudo apt-get install -y openssh-client openssh-server
    fi
}

install_openvpn() {
    command -v openvpn &>/dev/null && { ui_info "openvpn: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing openvpn" maybe_sudo dnf install -y openvpn
    else
        run_quiet_step "Installing openvpn" maybe_sudo apt-get install -y openvpn
    fi
}

install_tailscale() {
    command -v tailscale &>/dev/null && { ui_info "tailscale: already installed"; return 0; }
    local setup; setup="$(mktempfile)"
    run_quiet_step "Fetching Tailscale install script" \
        curl -fsSL https://tailscale.com/install.sh -o "$setup"
    # The official script is interactive (asks for sudo) — run directly.
    sh "$setup"
}

install_telnet() {
    command -v telnet &>/dev/null && { ui_info "telnet: already installed"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing telnet" \
            maybe_sudo dnf install -y telnet telnet-server
    else
        run_quiet_step "Installing telnet" maybe_sudo apt-get install -y telnetd
    fi
}

install_monitoring() {
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing monitoring suite" \
            maybe_sudo dnf install -y htop nmap sysstat fping traceroute
    else
        run_quiet_step "Installing monitoring suite" \
            maybe_sudo apt-get install -y nvtop htop nmap sysstat fping traceroute
    fi
}

# — Programming Languages ——————————————————————————————————————————————————————

install_python3() {
    command -v python3 &>/dev/null \
        && { ui_info "python3: already installed ($(python3 --version 2>&1))"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing python3" \
            maybe_sudo dnf install -y python3 python3-pip
    else
        run_quiet_step "Installing python3" \
            maybe_sudo apt-get install -y python3 python3-pip
    fi
}

install_nodejs() {
    command -v node &>/dev/null \
        && { ui_info "nodejs: already installed ($(node --version))"; return 0; }
    if command -v snap &>/dev/null; then
        maybe_sudo snap install node --classic
    else
        local setup; setup="$(mktempfile)"
        if [[ "$DISTRO" == "fedora" ]]; then
            run_quiet_step "Fetching NodeSource script" \
                curl -fsSL https://rpm.nodesource.com/setup_18.x -o "$setup"
            maybe_sudo bash "$setup"
            run_quiet_step "Installing nodejs" maybe_sudo dnf install -y nodejs
        else
            run_quiet_step "Fetching NodeSource script" \
                curl -fsSL https://deb.nodesource.com/setup_18.x -o "$setup"
            maybe_sudo bash "$setup"
            run_quiet_step "Installing nodejs" maybe_sudo apt-get install -y nodejs
        fi
    fi
}

install_go() {
    command -v go &>/dev/null \
        && { ui_info "go: already installed ($(go version 2>&1))"; return 0; }
    local latest_ver
    latest_ver="$(curl -fsSL https://go.dev/VERSION?m=text 2>/dev/null | head -1 || echo 'go1.22.0')"
    local tarball="${latest_ver}.linux-amd64.tar.gz"
    local tmp; tmp="$(mktempfile)"
    run_quiet_step "Downloading Go ${latest_ver}" \
        wget -q "https://dl.google.com/go/${tarball}" -O "$tmp"
    maybe_sudo rm -rf /usr/local/go
    run_quiet_step "Installing Go to /usr/local/go" \
        maybe_sudo tar -C /usr/local -xzf "$tmp"
    # Add to PATH for current session
    export PATH="$PATH:/usr/local/go/bin"
    local shell_rc="$HOME/.bashrc"
    if ! grep -q '/usr/local/go/bin' "$shell_rc" 2>/dev/null; then
        echo 'export PATH="$PATH:/usr/local/go/bin"' >> "$shell_rc"
    fi
    ui_info "Go installed — run 'source ~/.bashrc' or restart terminal"
}

install_rust() {
    command -v rustc &>/dev/null \
        && { ui_info "rust: already installed ($(rustc --version 2>&1))"; return 0; }
    local setup; setup="$(mktempfile)"
    run_quiet_step "Fetching rustup installer" \
        curl -fsSL https://sh.rustup.rs -o "$setup"
    # rustup is interactive — run directly so it can prompt the user.
    ui_info "rustup will ask how to proceed — press Enter to accept the default:"
    sh "$setup"
}

install_java() {
    command -v java &>/dev/null \
        && { ui_info "java: already installed ($(java -version 2>&1 | head -1))"; return 0; }
    if [[ "$DISTRO" == "fedora" ]]; then
        run_quiet_step "Installing Java 17" \
            maybe_sudo dnf install -y java-17-openjdk java-17-openjdk-devel
    else
        run_quiet_step "Installing Java 17" \
            maybe_sudo apt-get install -y openjdk-17-jdk openjdk-17-jre
    fi
}



# ─── Installation loop ───────────────────────────────────────────────────────
process_installations() {
    local total; total="$(count_selected)"

    if [[ $total -eq 0 ]]; then
        whiptail --title "Nothing to do" --msgbox "No software selected." \
                 8 40 3>&1 1>&2 2>&3
        return 0
    fi

    ui_stage "Installing $total package(s)"

    local current=0 success_count=0 failed_count=0
    local failed_list=()
    local sw

    for sw in "${!selected_software[@]}"; do
        [[ "${selected_software[$sw]:-}" != "true" ]] && continue

        current=$((current + 1))
        ui_section "[$current/$total] $sw"

        local fn="install_${sw}"
        if ! declare -f "$fn" >/dev/null 2>&1; then
            ui_warn "No install function for '$sw' — skipping"
            failed_count=$((failed_count + 1)); failed_list+=("$sw"); continue
        fi

        # Run with full terminal access (stdin wired to /dev/tty) so that
        # interactive prompts, EULA dialogs, and debconf questions work.
        local install_ok=0
        set +e
        "$fn" </dev/tty
        install_ok=$?
        set -e

        if [[ $install_ok -eq 0 ]]; then
            ui_success "$sw installed"
            success_count=$((success_count + 1))
        else
            ui_error "$sw failed (exit $install_ok)"
            failed_count=$((failed_count + 1)); failed_list+=("$sw")
        fi
    done

    echo ""
    ui_celebrate "Installation complete"
    ui_kv "Succeeded" "$success_count"
    ui_kv "Failed"    "$failed_count"
    [[ ${#failed_list[@]} -gt 0 ]] && ui_warn "Failed: ${failed_list[*]}"
    echo ""

    local summary="Installation Summary\n\n"
    summary+="  Succeeded : $success_count\n"
    summary+="  Failed    : $failed_count\n"
    [[ ${#failed_list[@]} -gt 0 ]] && summary+="\nFailed:\n  ${failed_list[*]}"
    whiptail --title "Done" --msgbox "$summary" 14 60 3>&1 1>&2 2>&3
}

# ─── Footer ──────────────────────────────────────────────────────────────────
show_footer() {
    clear
    echo ""
    ui_celebrate "Thanks for using thatbackendguy's installer!  <3"
    echo ""
    echo -e "${INFO}Follow @thatbackendguy:${NC}"
    ui_kv "Website" "https://www.thatbackendguy.com/"
    ui_kv "GitHub"  "https://www.github.com/thatbackendguy/"
    ui_kv "YouTube" "https://www.youtube.com/@ThatBackendGuy/"
    echo ""
    echo -e "${ACCENT}${BOLD}Post-install tips${NC}"
    echo -e "${MUTED}Configure git:${NC}"
    echo "  git config --global user.name  '<Your Name>'"
    echo "  git config --global user.email '<Your Email>'"
    echo ""
    echo -e "${MUTED}Authenticate GitHub CLI:${NC}"
    echo "  gh auth login"
    echo ""
}

# ─── Main ────────────────────────────────────────────────────────────────────
main() {
    display_banner
    detect_distro
    check_whiptail   # bootstrap before any whiptail call
    check_root
    check_dependencies
    update_system

    local choice
    while true; do
        choice="$(select_category)"

        case "$choice" in
            0) apply_recommended ;;
            1) handle_category "🌐 Web Browsers"           \
                               "Select browsers to install:" PKGS_BROWSERS ;;
            2) handle_category "🔧 Development Tools"      \
                               "Select dev tools to install:" PKGS_DEV ;;
            3) handle_category "💬 Communication Tools"    \
                               "Select communication tools:" PKGS_COMM ;;
            4) handle_category "🎬 Media & Utilities"      \
                               "Select media tools to install:" PKGS_MEDIA ;;
            5) handle_category "🌐 Network Tools"          \
                               "Select network tools:" PKGS_NETWORK ;;
            6) handle_category "📦 Programming Languages"  \
                               "Select languages to install:" PKGS_LANG ;;
            7) if review_and_edit; then
                   process_installations
               fi ;;
            8) if whiptail --title "Exit" \
                           --yesno "Are you sure you want to exit?" \
                           8 40 3>&1 1>&2 2>&3; then
                   show_footer; exit 0
               fi ;;
            *) if [[ -z "$choice" ]]; then
                   if whiptail --title "Exit" \
                               --yesno "No selection made. Exit?" \
                               8 40 3>&1 1>&2 2>&3; then
                       show_footer; exit 0
                   fi
               else
                   whiptail --title "Invalid Option" \
                            --msgbox "Please select a valid option." \
                            8 40 3>&1 1>&2 2>&3
               fi ;;
        esac
    done
}

main
