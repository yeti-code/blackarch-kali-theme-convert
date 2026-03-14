#!/bin/bash

#===============================================================================
# Kali Linux to BlackArch Theme Converter
# This script transforms Kali Linux desktop to resemble BlackArch Linux
#===============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_banner() {
    echo -e "${RED}"
    cat << "EOF"
    ____  __           __   ___              __       ________                      
   / __ )/ /___ ______/ /__/   |  __________/ /_     /_  __/ /_  ___  ____ ___  ___ 
  / __  / / __ `/ ___/ //_/ /| | / ___/ ___/ __ \     / / / __ \/ _ \/ __ `__ \/ _ \
 / /_/ / / /_/ / /__/ ,< / ___ |/ /  / /__/ / / /    / / / / / /  __/ / / / / /  __/
/_____/_/\__,_/\___/_/|_/_/  |_/_/   \___/_/ /_/    /_/ /_/ /_/\___/_/ /_/ /_/\___/ 
                                                                                    
                    Kali Linux to BlackArch Theme Converter
EOF
    echo -e "${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_kali() {
    if ! grep -q "Kali" /etc/os-release 2>/dev/null; then
        print_warning "This doesn't appear to be Kali Linux. Continue anyway? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

get_real_user() {
    if [[ -n "$SUDO_USER" ]]; then
        REAL_USER="$SUDO_USER"
    else
        REAL_USER="$USER"
    fi
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
}

install_packages() {
    print_status "Updating package lists..."
    apt update -qq

    print_status "Installing required packages..."
    
    # Install packages one by one to handle failures gracefully
    PACKAGES=(
        fluxbox
        openbox
        obconf
        lxappearance
        arc-theme
        numix-gtk-theme
        papirus-icon-theme
        lightdm-gtk-greeter-settings
        feh
        rofi
        compton
        picom
        alacritty
        neofetch
        conky-std
        polybar
        dunst
    )
    
    for pkg in "${PACKAGES[@]}"; do
        if apt install -y "$pkg" 2>&1; then
            print_status "Installed: $pkg"
        else
            print_warning "Failed to install: $pkg (continuing...)"
        fi
    done
}

download_wallpapers() {
    print_status "Downloading BlackArch wallpapers..."
    
    WALLPAPER_DIR="$REAL_HOME/Pictures/wallpapers/blackarch"
    mkdir -p "$WALLPAPER_DIR"
    
    # Download multiple BlackArch wallpapers
    WALLPAPERS=(
        "https://raw.githubusercontent.com/BlackArch/blackarch-artwork/master/wallpaper/wallpaper-NINJARCH-code.png"
    )
    
    for url in "${WALLPAPERS[@]}"; do
        filename=$(basename "$url")
        if wget -q -O "$WALLPAPER_DIR/$filename" "$url" 2>/dev/null; then
            print_status "Downloaded: $filename"
        else
            print_warning "Could not download: $filename"
        fi
    done
    
    # Create a simple black wallpaper with red accent as fallback
    if command -v convert &> /dev/null; then
        convert -size 1920x1080 xc:black \
            -fill '#1a1a1a' -draw "rectangle 0,0 1920,5" \
            -fill '#ff0000' -draw "rectangle 0,1075 1920,1080" \
            "$WALLPAPER_DIR/blackarch-minimal.png" 2>/dev/null || true
    fi
    
    chown -R "$REAL_USER:$REAL_USER" "$WALLPAPER_DIR"
}

configure_gtk_theme() {
    print_status "Configuring GTK theme..."
    
    # GTK 2.0
    GTK2_RC="$REAL_HOME/.gtkrc-2.0"
    cat > "$GTK2_RC" << 'EOF'
gtk-theme-name="Arc-Dark"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Sans 10"
gtk-cursor-theme-name="Adwaita"
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintslight"
gtk-xft-rgba="rgb"
EOF
    chown "$REAL_USER:$REAL_USER" "$GTK2_RC"
    
    # GTK 3.0
    GTK3_DIR="$REAL_HOME/.config/gtk-3.0"
    mkdir -p "$GTK3_DIR"
    cat > "$GTK3_DIR/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF
    chown -R "$REAL_USER:$REAL_USER" "$GTK3_DIR"
}

configure_lightdm() {
    print_status "Configuring LightDM login screen..."
    
    LIGHTDM_CONF="/etc/lightdm/lightdm-gtk-greeter.conf"
    WALLPAPER="$REAL_HOME/Pictures/wallpapers/blackarch/wallpaper-NINJARCH-code.png"
    
    # Fallback if wallpaper doesn't exist
    if [[ ! -f "$WALLPAPER" ]]; then
        WALLPAPER="#000000"
    fi
    
    cat > "$LIGHTDM_CONF" << EOF
[greeter]
background=$WALLPAPER
theme-name=Arc-Dark
icon-theme-name=Papirus-Dark
font-name=Sans 11
xft-antialias=true
xft-dpi=96
xft-hintstyle=slight
xft-rgba=rgb
indicators=~host;~spacer;~clock;~spacer;~session;~language;~a11y;~power
clock-format=%H:%M
position=50%,center 50%,center
screensaver-timeout=60
default-user-image=#emblem-default
EOF
}

configure_openbox() {
    print_status "Configuring Openbox..."
    
    OB_DIR="$REAL_HOME/.config/openbox"
    mkdir -p "$OB_DIR"
    
    # Openbox autostart
    cat > "$OB_DIR/autostart" << 'EOF'
# Set wallpaper
feh --bg-scale ~/Pictures/wallpapers/blackarch/wallpaper-NINJARCH-code.png &

# Compositor for transparency
picom -b &

# Panel
~/.config/polybar/launch.sh &

# Notification daemon
dunst &

# Network manager applet (if available)
nm-applet &
EOF
    
    # Openbox menu
    cat > "$OB_DIR/menu.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
<menu id="root-menu" label="BlackArch Menu">
  <item label="Terminal">
    <action name="Execute"><execute>alacritty</execute></action>
  </item>
  <item label="File Manager">
    <action name="Execute"><execute>thunar</execute></action>
  </item>
  <item label="Web Browser">
    <action name="Execute"><execute>firefox-esr</execute></action>
  </item>
  <separator />
  <menu id="apps-menu" label="Applications">
    <item label="Text Editor">
      <action name="Execute"><execute>mousepad</execute></action>
    </item>
    <item label="Burp Suite">
      <action name="Execute"><execute>burpsuite</execute></action>
    </item>
    <item label="Metasploit">
      <action name="Execute"><execute>alacritty -e msfconsole</execute></action>
    </item>
  </menu>
  <menu id="settings-menu" label="Settings">
    <item label="Appearance">
      <action name="Execute"><execute>lxappearance</execute></action>
    </item>
    <item label="Openbox Config">
      <action name="Execute"><execute>obconf</execute></action>
    </item>
  </menu>
  <separator />
  <item label="Reconfigure">
    <action name="Reconfigure" />
  </item>
  <item label="Exit">
    <action name="Exit" />
  </item>
</menu>
</openbox_menu>
EOF
    
    # Openbox rc.xml (theme and keybindings)
    cat > "$OB_DIR/rc.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <theme>
    <name>Arc-Dark</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>yes</animateIconify>
    <font place="ActiveWindow"><name>Sans</name><size>10</size><weight>Bold</weight></font>
    <font place="InactiveWindow"><name>Sans</name><size>10</size><weight>Bold</weight></font>
    <font place="MenuHeader"><name>Sans</name><size>10</size><weight>Normal</weight></font>
    <font place="MenuItem"><name>Sans</name><size>10</size><weight>Normal</weight></font>
    <font place="ActiveOnScreenDisplay"><name>Sans</name><size>10</size><weight>Bold</weight></font>
    <font place="InactiveOnScreenDisplay"><name>Sans</name><size>10</size><weight>Bold</weight></font>
  </theme>
  <desktops><number>4</number><firstdesk>1</firstdesk></desktops>
  <keyboard>
    <keybind key="W-Return"><action name="Execute"><execute>alacritty</execute></action></keybind>
    <keybind key="W-d"><action name="Execute"><execute>rofi -show drun</execute></action></keybind>
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
    <keybind key="W-Left"><action name="UnmaximizeFull"/><action name="MoveResizeTo"><x>0</x><y>0</y><width>50%</width><height>100%</height></action></keybind>
    <keybind key="W-Right"><action name="UnmaximizeFull"/><action name="MoveResizeTo"><x>50%</x><y>0</y><width>50%</width><height>100%</height></action></keybind>
    <keybind key="W-Up"><action name="Maximize"/></keybind>
    <keybind key="W-Down"><action name="Iconify"/></keybind>
    <keybind key="W-q"><action name="Close"/></keybind>
  </keyboard>
  <mouse><context name="Frame"><mousebind button="A-Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind><mousebind button="A-Left" action="Drag"><action name="Move"/></mousebind></context></mouse>
</openbox_config>
EOF
    
    chown -R "$REAL_USER:$REAL_USER" "$OB_DIR"
}

configure_fluxbox() {
    print_status "Configuring Fluxbox..."
    
    FB_DIR="$REAL_HOME/.fluxbox"
    mkdir -p "$FB_DIR"
    
    # Fluxbox init
    cat > "$FB_DIR/init" << 'EOF'
session.screen0.toolbar.visible: true
session.screen0.toolbar.placement: BottomCenter
session.screen0.toolbar.widthPercent: 100
session.screen0.toolbar.height: 24
session.screen0.toolbar.tools: prevworkspace, workspacename, nextworkspace, iconbar, systemtray, clock
session.styleFile: /usr/share/fluxbox/styles/arch/dark
session.menuFile: ~/.fluxbox/menu
session.keyFile: ~/.fluxbox/keys
EOF
    
    # Fluxbox startup
    cat > "$FB_DIR/startup" << 'EOF'
#!/bin/bash
feh --bg-scale ~/Pictures/wallpapers/blackarch/wallpaper-NINJARCH-code.png &
picom -b &
nm-applet &
exec fluxbox
EOF
    chmod +x "$FB_DIR/startup"
    
    # Fluxbox menu
    cat > "$FB_DIR/menu" << 'EOF'
[begin] (BlackArch)
  [exec] (Terminal) {alacritty}
  [exec] (File Manager) {thunar}
  [exec] (Browser) {firefox-esr}
  [separator]
  [submenu] (Security Tools)
    [exec] (Burp Suite) {burpsuite}
    [exec] (Metasploit) {alacritty -e msfconsole}
    [exec] (Nmap) {alacritty -e nmap --help}
    [exec] (Wireshark) {wireshark}
  [end]
  [submenu] (Settings)
    [exec] (Appearance) {lxappearance}
    [config] (Fluxbox Config)
  [end]
  [separator]
  [restart] (Restart)
  [exit] (Exit)
[end]
EOF
    
    # Fluxbox keys
    cat > "$FB_DIR/keys" << 'EOF'
# Super + Enter = Terminal (try alacritty, fallback to x-terminal-emulator)
Mod4 Return :Exec alacritty || x-terminal-emulator
Mod4 t :Exec alacritty || x-terminal-emulator

# Super + D = App launcher
Mod4 d :Exec rofi -show drun

# Window management
Mod1 Tab :NextWindow {groups} (workspace=[current])
Mod1 Shift Tab :PrevWindow {groups} (workspace=[current])
Mod4 q :Close
Mod4 m :Maximize
Mod4 n :Minimize
Mod4 f :Fullscreen

# Workspace switching
Mod4 1 :Workspace 1
Mod4 2 :Workspace 2
Mod4 3 :Workspace 3
Mod4 4 :Workspace 4

# Right-click menu
OnDesktop Mouse3 :RootMenu

# Scroll on desktop to change workspace
OnDesktop Mouse4 :PrevWorkspace
OnDesktop Mouse5 :NextWorkspace

# Click on titlebar actions
OnTitlebar Double Mouse1 :Maximize
OnTitlebar Mouse3 :WindowMenu
EOF
    
    chown -R "$REAL_USER:$REAL_USER" "$FB_DIR"
}

configure_alacritty() {
    print_status "Configuring Alacritty terminal..."
    
    ALACRITTY_DIR="$REAL_HOME/.config/alacritty"
    mkdir -p "$ALACRITTY_DIR"
    
    cat > "$ALACRITTY_DIR/alacritty.toml" << 'EOF'
[window]
padding = { x = 10, y = 10 }
decorations = "full"
opacity = 0.95
title = "BlackArch Terminal"

[font]
size = 11.0

[font.normal]
family = "monospace"
style = "Regular"

[font.bold]
family = "monospace"
style = "Bold"

[colors.primary]
background = "#0d0d0d"
foreground = "#d0d0d0"

[colors.cursor]
text = "#0d0d0d"
cursor = "#ff0000"

[colors.normal]
black   = "#1a1a1a"
red     = "#ff0000"
green   = "#00ff00"
yellow  = "#ffff00"
blue    = "#0066ff"
magenta = "#cc00ff"
cyan    = "#00ffff"
white   = "#d0d0d0"

[colors.bright]
black   = "#4d4d4d"
red     = "#ff3333"
green   = "#33ff33"
yellow  = "#ffff33"
blue    = "#3399ff"
magenta = "#ff33ff"
cyan    = "#33ffff"
white   = "#ffffff"

[selection]
save_to_clipboard = true
EOF
    
    chown -R "$REAL_USER:$REAL_USER" "$ALACRITTY_DIR"
}

configure_rofi() {
    print_status "Configuring Rofi launcher..."
    
    ROFI_DIR="$REAL_HOME/.config/rofi"
    mkdir -p "$ROFI_DIR"
    
    cat > "$ROFI_DIR/config.rasi" << 'EOF'
configuration {
    modi: "drun,run,window";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    font: "Sans 12";
    display-drun: "Apps";
    display-run: "Run";
    display-window: "Windows";
}

* {
    background:     #0d0d0dE6;
    background-alt: #1a1a1aE6;
    foreground:     #FFFFFF;
    selected:       #ff0000;
    active:         #00ff00;
    urgent:         #ff0000;
}

window {
    width: 600px;
    border: 2px;
    border-color: @selected;
    border-radius: 8px;
    background-color: @background;
}

mainbox {
    background-color: transparent;
    children: [ inputbar, listview ];
    spacing: 10px;
    padding: 20px;
}

inputbar {
    background-color: @background-alt;
    border-radius: 4px;
    padding: 10px;
    children: [ prompt, entry ];
}

prompt {
    background-color: transparent;
    text-color: @selected;
    padding: 0 10px 0 0;
}

entry {
    background-color: transparent;
    text-color: @foreground;
    placeholder: "Search...";
    placeholder-color: #666666;
}

listview {
    background-color: transparent;
    columns: 1;
    lines: 8;
    spacing: 5px;
}

element {
    background-color: transparent;
    padding: 10px;
    border-radius: 4px;
}

element selected {
    background-color: @selected;
    text-color: @background;
}

element-icon {
    size: 24px;
    padding: 0 10px 0 0;
}

element-text {
    background-color: transparent;
    text-color: inherit;
}
EOF
    
    chown -R "$REAL_USER:$REAL_USER" "$ROFI_DIR"
}

configure_polybar() {
    print_status "Configuring Polybar panel..."
    
    POLYBAR_DIR="$REAL_HOME/.config/polybar"
    mkdir -p "$POLYBAR_DIR"
    
    cat > "$POLYBAR_DIR/config.ini" << 'EOF'
[colors]
background = #0d0d0d
background-alt = #1a1a1a
foreground = #ffffff
primary = #ff0000
secondary = #666666
alert = #ff0000
disabled = #4d4d4d

[bar/blackarch]
width = 100%
height = 24pt
radius = 0
background = ${colors.background}
foreground = ${colors.foreground}
line-size = 2pt
border-size = 0pt
border-color = #00000000
padding-left = 1
padding-right = 1
module-margin = 1
separator = |
separator-foreground = ${colors.disabled}
font-0 = "Sans:size=10;2"
font-1 = "Sans:size=10:weight=bold;2"
modules-left = xworkspaces
modules-center = date
modules-right = pulseaudio memory cpu wlan eth tray
cursor-click = pointer
cursor-scroll = ns-resize
enable-ipc = true

[module/tray]
type = internal/tray
tray-spacing = 8pt

[module/xworkspaces]
type = internal/xworkspaces
label-active = %name%
label-active-background = ${colors.background-alt}
label-active-underline= ${colors.primary}
label-active-padding = 1
label-occupied = %name%
label-occupied-padding = 1
label-urgent = %name%
label-urgent-background = ${colors.alert}
label-urgent-padding = 1
label-empty = %name%
label-empty-foreground = ${colors.disabled}
label-empty-padding = 1

[module/pulseaudio]
type = internal/pulseaudio
format-volume-prefix = "VOL "
format-volume-prefix-foreground = ${colors.primary}
format-volume = <label-volume>
label-volume = %percentage%%
label-muted = muted
label-muted-foreground = ${colors.disabled}

[module/memory]
type = internal/memory
interval = 2
format-prefix = "RAM "
format-prefix-foreground = ${colors.primary}
label = %percentage_used:2%%

[module/cpu]
type = internal/cpu
interval = 2
format-prefix = "CPU "
format-prefix-foreground = ${colors.primary}
label = %percentage:2%%

[module/wlan]
type = internal/network
interface-type = wireless
interval = 5
format-connected = <label-connected>
label-connected = %{F#ff0000}WLAN%{F-} %essid%
format-disconnected =
label-disconnected =

[module/eth]
type = internal/network
interface-type = wired
interval = 5
format-connected = <label-connected>
label-connected = %{F#ff0000}ETH%{F-} %local_ip%
format-disconnected =
label-disconnected =

[module/date]
type = internal/date
interval = 1
date = %Y-%m-%d %H:%M:%S
label = %date%
label-foreground = ${colors.primary}

[settings]
screenchange-reload = true
pseudo-transparency = true
EOF

    # Polybar launch script
    cat > "$POLYBAR_DIR/launch.sh" << 'EOF'
#!/bin/bash
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
polybar blackarch 2>&1 | tee -a /tmp/polybar.log & disown
EOF
    chmod +x "$POLYBAR_DIR/launch.sh"
    
    chown -R "$REAL_USER:$REAL_USER" "$POLYBAR_DIR"
}

configure_bash() {
    print_status "Configuring Bash prompt..."
    
    BASHRC="$REAL_HOME/.bashrc"
    
    # Backup existing bashrc
    if [[ -f "$BASHRC" ]]; then
        cp "$BASHRC" "$BASHRC.backup.$(date +%Y%m%d%H%M%S)"
    fi
    
    # Add BlackArch-style prompt
    cat >> "$BASHRC" << 'EOF'

# BlackArch-style prompt
export PS1='\[\e[0;31m\]┌──[\[\e[1;31m\]\u\[\e[0;31m\]@\[\e[1;31m\]\h\[\e[0;31m\]]-[\[\e[1;37m\]\w\[\e[0;31m\]]\n\[\e[0;31m\]└──╼ \[\e[1;31m\]\$\[\e[0m\] '

# BlackArch-style aliases
alias ls='ls --color=auto'
alias ll='ls -la --color=auto'
alias grep='grep --color=auto'
alias cls='clear'
alias update='sudo apt update && sudo apt upgrade -y'

# Neofetch on terminal start (optional - uncomment to enable)
# neofetch
EOF
    
    chown "$REAL_USER:$REAL_USER" "$BASHRC"
}

configure_neofetch() {
    print_status "Configuring Neofetch..."
    
    NEOFETCH_DIR="$REAL_HOME/.config/neofetch"
    mkdir -p "$NEOFETCH_DIR"
    
    cat > "$NEOFETCH_DIR/config.conf" << 'EOF'
print_info() {
    info title
    info underline
    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Uptime" uptime
    info "Packages" packages
    info "Shell" shell
    info "Resolution" resolution
    info "DE" de
    info "WM" wm
    info "Terminal" term
    info "CPU" cpu
    info "GPU" gpu
    info "Memory" memory
    info cols
}

title_fqdn="off"
kernel_shorthand="on"
distro_shorthand="off"
os_arch="on"
uptime_shorthand="on"
memory_percent="on"
package_managers="on"
shell_path="off"
shell_version="on"
speed_type="bios_limit"
speed_shorthand="off"
cpu_brand="on"
cpu_speed="on"
cpu_cores="logical"
cpu_temp="off"
gpu_brand="on"
gpu_type="all"
refresh_rate="off"
gtk_shorthand="off"
gtk2="on"
gtk3="on"
colors=(1 7 1 1 7 7)
bold="on"
underline_enabled="on"
underline_char="-"
separator=":"
color_blocks="on"
block_range=(0 15)
block_width=3
block_height=1
col_offset="auto"
bar_char_elapsed="-"
bar_char_total="="
bar_border="on"
bar_length=15
bar_color_elapsed="distro"
bar_color_total="distro"
cpu_display="off"
memory_display="off"
battery_display="off"
disk_display="off"
image_backend="ascii"
image_source="auto"
ascii_distro="auto"
ascii_colors=(1 1 1 1 1 1)
ascii_bold="on"
image_loop="off"
thumbnail_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/thumbnails/neofetch"
crop_mode="normal"
crop_offset="center"
image_size="auto"
gap=3
yoffset=0
xoffset=0
background_color=
stdout="off"
EOF
    
    chown -R "$REAL_USER:$REAL_USER" "$NEOFETCH_DIR"
}

configure_picom() {
    print_status "Configuring Picom compositor..."
    
    PICOM_CONF="$REAL_HOME/.config/picom.conf"
    
    cat > "$PICOM_CONF" << 'EOF'
# Shadow
shadow = true;
shadow-radius = 12;
shadow-offset-x = -7;
shadow-offset-y = -7;
shadow-opacity = 0.6;
shadow-exclude = [
    "name = 'Notification'",
    "class_g = 'Conky'",
    "class_g ?= 'Notify-osd'",
    "class_g = 'Cairo-clock'",
    "_GTK_FRAME_EXTENTS@:c"
];

# Fading
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
fade-delta = 5;

# Opacity
inactive-opacity = 0.95;
frame-opacity = 0.9;
inactive-opacity-override = false;
active-opacity = 1.0;
focus-exclude = [ "class_g = 'Cairo-clock'" ];
opacity-rule = [
    "90:class_g = 'Alacritty'",
    "95:class_g = 'URxvt'"
];

# Corners
corner-radius = 8;
rounded-corners-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'"
];

# Background blurring
blur-method = "dual_kawase";
blur-strength = 5;
blur-background-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'",
    "_GTK_FRAME_EXTENTS@:c"
];

# General
backend = "glx";
vsync = true;
mark-wmwin-focused = true;
mark-ovredir-focused = true;
detect-rounded-corners = true;
detect-client-opacity = true;
detect-transient = true;
use-damage = true;
log-level = "warn";
EOF
    
    chown "$REAL_USER:$REAL_USER" "$PICOM_CONF"
}

configure_dunst() {
    print_status "Configuring Dunst notifications..."
    
    DUNST_DIR="$REAL_HOME/.config/dunst"
    mkdir -p "$DUNST_DIR"
    
    cat > "$DUNST_DIR/dunstrc" << 'EOF'
[global]
    monitor = 0
    follow = mouse
    width = 300
    height = 100
    origin = top-right
    offset = 10x50
    scale = 0
    notification_limit = 5
    progress_bar = true
    indicate_hidden = yes
    transparency = 10
    separator_height = 2
    padding = 10
    horizontal_padding = 10
    text_icon_padding = 0
    frame_width = 2
    frame_color = "#ff0000"
    separator_color = frame
    sort = yes
    font = Sans 10
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    min_icon_size = 0
    max_icon_size = 32
    sticky_history = yes
    history_length = 20
    browser = /usr/bin/firefox-esr
    always_run_script = true
    title = Dunst
    class = Dunst
    corner_radius = 8
    ignore_dbusclose = false
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[urgency_low]
    background = "#0d0d0d"
    foreground = "#888888"
    timeout = 5

[urgency_normal]
    background = "#0d0d0d"
    foreground = "#ffffff"
    timeout = 10

[urgency_critical]
    background = "#1a1a1a"
    foreground = "#ff0000"
    frame_color = "#ff0000"
    timeout = 0
EOF
    
    chown -R "$REAL_USER:$REAL_USER" "$DUNST_DIR"
}

create_xsession() {
    print_status "Creating X session entries..."
    
    # Openbox session
    cat > /usr/share/xsessions/blackarch-openbox.desktop << 'EOF'
[Desktop Entry]
Name=BlackArch Openbox
Comment=BlackArch-themed Openbox session
Exec=openbox-session
Type=Application
EOF
    
    # Fluxbox session
    cat > /usr/share/xsessions/blackarch-fluxbox.desktop << 'EOF'
[Desktop Entry]
Name=BlackArch Fluxbox
Comment=BlackArch-themed Fluxbox session
Exec=startfluxbox
Type=Application
EOF
}

print_summary() {
    echo ""
    print_status "Installation complete!"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}                         BlackArch Theme Applied!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Configured components:"
    echo "  • GTK 2.0 and GTK 3.0 themes (Arc-Dark)"
    echo "  • Icon theme (Papirus-Dark)"
    echo "  • LightDM login screen"
    echo "  • Openbox window manager"
    echo "  • Fluxbox window manager"
    echo "  • Alacritty terminal"
    echo "  • Rofi application launcher"
    echo "  • Tint2 panel"
    echo "  • Picom compositor"
    echo "  • Dunst notifications"
    echo "  • Bash prompt"
    echo "  • Neofetch"
    echo ""
    echo "To use the new theme:"
    echo "  1. Log out of your current session"
    echo "  2. At the login screen, select 'BlackArch Openbox' or 'BlackArch Fluxbox'"
    echo "  3. Log in and enjoy your new BlackArch-style desktop!"
    echo ""
    echo "Keyboard shortcuts (Openbox/Fluxbox):"
    echo "  • Super + Enter    : Open terminal"
    echo "  • Super + D        : Open application launcher (Rofi)"
    echo "  • Super + Q        : Close window"
    echo "  • Alt + Tab        : Switch windows"
    echo ""
    echo -e "${YELLOW}Note: A backup of your .bashrc was created before modifications.${NC}"
    echo ""
}

#===============================================================================
# Main
#===============================================================================

main() {
    print_banner
    check_root
    check_kali
    get_real_user
    
    print_status "Starting BlackArch theme installation for user: $REAL_USER"
    echo ""
    
    install_packages
    download_wallpapers
    configure_gtk_theme
    configure_lightdm
    configure_openbox
    configure_fluxbox
    configure_alacritty
    configure_rofi
    configure_polybar
    configure_bash
    configure_neofetch
    configure_picom
    configure_dunst
    create_xsession
    
    print_summary
}

main "$@"
