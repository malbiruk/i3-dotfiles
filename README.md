# 🌐 Matrix-Inspired Sway Configuration

A sleek, minimal Sway window manager configuration with Matrix-inspired green-on-black aesthetics and dynamic wallpaper generation.

![Desktop Screenshot](20250529_01h34m23s_grim.png)

## ✨ Features

### 🚀 Application Launcher
- **Wofi** as the primary application launcher (`Mod+D`)
- Clean, minimal interface with Matrix green highlights
- Custom CSS styling for consistent theming

### 🔍 Window Management
- **Window search** with fuzzy matching (`Mod+Shift+W`)
- Quick window switching across workspaces
- Python-based window switcher with rich formatting

### 📂 File Explorer
- **Smart file finder** (`Mod+Shift+F`) - finds files by recency
- Integrates with `wofi` for seamless file navigation
- Shows file paths for easy identification

### 🔒 System Controls
- **Logout menu** (`Mod+Shift+Q`) with power options:
  - 🔒 Lock screen
  - 🚪 Logout
  - 💤 Suspend
  - 🔄 Reboot
  - ⏻ Shutdown

### 🎨 Dynamic Wallpapers
- **Auto-generated glitch wallpapers** on every login
- Matrix-inspired noise patterns in green/teal
- Python script creates unique backgrounds each session
- Subtle scan lines and distortion effects

### 🎨 Color Scheme
```
Background: #0a0c0e (Deep Black)
Primary:    #00ff00 (Matrix Green)
Secondary:  #888a85 (Muted Gray)
Accent:     #7f99a6 (Cyan-Blue)
```

### 📊 Status Bar
- **Custom bash-based status bar** with Nerd Font icons
- Real-time system monitoring:
  - 🖥️ CPU usage
  - 🧠 Memory usage (percentage + absolute)
  - 💾 Disk usage
  - 📶 Network status with signal strength
  - 🔊 Volume control
  - 🔋 Battery status (if available)
  - ⌨️ Keyboard layout
  - 📅 Date and time
  - 🪟 Current window title

### 🤲 Gesture Support
Touchpad gestures for seamless navigation:
- **Swipe right/left**: Switch workspaces
- **Swipe up**: Open window search
- **Swipe down**: Open application launcher

### ⌨️ Key Bindings

#### Core Navigation
- `Mod+Return` - Terminal (Alacritty)
- `Mod+D` - Application launcher
- `Mod+Q` - Kill focused window

#### Advanced Features  
- `Mod+Shift+W` - Window search
- `Mod+Shift+F` - File finder
- `Mod+Shift+Q` - Logout menu

#### Workspace Management
- `Mod+1-0` - Switch to workspace
- `Mod+Shift+1-0` - Move window to workspace and follow
- `Mod+Ctrl+1-0` - Move window to workspace (stay current)
- `Mod+=/−` - Next/previous workspace

#### Layout Controls
- `Mod+S/W/E` - Stacking/tabbed/split layout
- `Mod+F` - Fullscreen
- `Mod+Space` - Toggle floating

## 🛠️ Installation

### Prerequisites
```bash
# Core components
sudo pacman -S sway wofi alacritty mako grim

# Status bar dependencies  
sudo pacman -S jq networkmanager

# Wallpaper generator
sudo pacman -S python python-pip python-pillow python-numpy
```

### Setup
1. Clone this repository:
   ```bash
   git clone <repo-url> ~/.config/sway-dotfiles
   ```

2. Create symbolic links:
   ```bash
   ln -sf ~/.config/sway-dotfiles/sway ~/.config/sway
   ln -sf ~/.config/sway-dotfiles/wofi ~/.config/wofi
   ln -sf ~/.config/sway-dotfiles/alacritty ~/.config/alacritty
   ```

3. Set up wallpaper generator:
   ```bash
   cd ~/.config/sway-dotfiles/noise_wp
   python -m venv .venv
   source .venv/bin/activate
   pip install pillow numpy
   ```

4. Update paths in `sway/config` to match your username

## 🎨 Customization

### Colors
Edit the color variables in `sway/config`:
```bash
set $black  #0a0c0e
set $white  #00ff00  # Matrix green
set $grey   #888a85
```

### Status Bar
Modify `sway/scripts/status_bar_info.sh` to add/remove modules or change refresh intervals.

### Wallpaper
Adjust wallpaper generation parameters in `noise_wp/glitchy_wp.py`:
- Color intensity
- Noise patterns  
- Distortion effects
- Resolution

## 🔧 Configuration Files

- `sway/config` - Main Sway configuration
- `sway/scripts/status_bar_info.sh` - Custom status bar script
- `sway/scripts/logout_menu.sh` - Power menu script
- `sway/scripts/windows.py` - Window switcher
- `wofi/config` - Wofi launcher settings
- `wofi/style.css` - Wofi visual styling
- `noise_wp/glitchy_wp.py` - Dynamic wallpaper generator

## 🎯 Philosophy

This configuration prioritizes:
- **Minimalism** - Clean, distraction-free interface
- **Efficiency** - Keyboard-driven workflow with gesture support
- **Aesthetics** - Consistent Matrix-inspired theming
- **Functionality** - Rich system information without bloat

The green-on-black color scheme reduces eye strain while maintaining the iconic Matrix aesthetic. Every element is designed to be both functional and visually cohesive.

---

*"There is no spoon... only perfect window management."* 🥄✨