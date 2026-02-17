#!/usr/bin/env python3
import os
import re

# Paths
REPO_ROOT = os.path.expanduser("~/Hyprland-Arch-Config")
CONFIG_FILE = os.path.join(REPO_ROOT, "dotfiles/hypr/hyprland.conf")
OUTPUT_FILE = os.path.join(REPO_ROOT, "Keybindings.md")

# Header
HEADER = """# ⌨️ System Keybindings

This file is **automatically generated**. It serves as the single source of truth for all keybindings in this Hyprland configuration, including Shell (Zsh) and Terminal (WezTerm) shortcuts.

**Modifier Key:** `SUPER` (Windows Key)

"""

# Static bindings (Zsh, Utilities, etc. that aren't in hyprland.conf)
STATIC_BINDINGS = [
    # Shell (Zsh)
    {"category": "🐚 Shell (Zsh)", "key": "CTRL + ARROWS", "action": "Jump Words"},
    {"category": "🐚 Shell (Zsh)", "key": "SHIFT + ARROWS", "action": "Select Character/Line"},
    {"category": "🐚 Shell (Zsh)", "key": "CTRL + SHIFT + ARROWS", "action": "Select Word (Continuous)"},
    {"category": "🐚 Shell (Zsh)", "key": "CTRL + A", "action": "Select All Text"},
    {"category": "🐚 Shell (Zsh)", "key": "ALT + S", "action": "Smart Sudo (Toggle 'sudo' at start of line)"},
    {"category": "🐚 Shell (Zsh)", "key": "SHIFT + ENTER", "action": "Soft Newline"},
    
    # Utilities / Interactive
    {"category": "🛠️ Utilities & Interactive", "key": "SUPER + SHIFT + S", "action": "Screenshot (Region Selection -> Edit)"},
    {"category": "🛠️ Utilities & Interactive", "key": "CLICK (Waybar Workspace)", "action": "Switch Workspace"},
    {"category": "🛠️ Utilities & Interactive", "key": "CLICK (Waybar Network)", "action": "Toggle WiFi Connection"},
    {"category": "🛠️ Utilities & Interactive", "key": "SUPER + X", "action": "Power Menu (Lock/Suspend/Reboot/Shutdown)"}
]

def parse_key(key_part):
    key_part = key_part.replace("$mainMod", "SUPER").replace("$mod", "SUPER")
    # Clean up standardizers
    parts = [p.strip().upper() for p in key_part.split(" ") if p.strip()]
    return " + ".join(parts)

def parse_dispatcher(dispatcher, params):
    action = f"{dispatcher} {params}".strip()
    
    # Beautify common actions
    if "exec" in dispatcher:
        # Handle complex commands first
        if "swaylock" in params: return "Launch Lock Screen"
        if "gemini" in params: return "Launch Gemini CLI"
        if "yazi" in params: return "Launch Yazi File Manager"
        if "ocr_tool" in params: return "Launch OCR Tool"
        
        # General cleanup for simple commands
        cmd = params.split("/")[-1].replace(".sh", "").replace("-", " ").title()
        
        if "Wezterm" in cmd: return "Terminal (WezTerm)"
        if "Code" in cmd: return "VS Code"
        if "Thunar" in cmd: return "File Manager (Thunar)"
        if "Brave" in cmd: return "Web Browser (Brave)"
        if "Grim" in cmd: return "Screenshot"
        if "Wofi" in cmd or "Smart_Launcher" in cmd: return "App Launcher"
        if "Dnd" in cmd: return "Toggle Do Not Disturb"
        if "Clip" in cmd: return "Clipboard Manager"
        if "Powermenu" in cmd: return "Power Menu"
        if "Bluetooth" in cmd: return "Bluetooth Menu"
        if "Wifi" in cmd: return "WiFi Menu"
        
        return f"Launch {cmd}"
    
    if dispatcher == "killactive": return "Close Active Window"
    if dispatcher == "togglesplit": return "Toggle Split Direction"
    if dispatcher == "togglefloating": return "Toggle Floating Mode"
    if dispatcher == "fullscreen": return "Toggle Fullscreen"
    if dispatcher == "movefocus": return f"Move Focus {params.upper()}"
    if dispatcher == "movewindow": return f"Move Window {params.upper()}"
    if dispatcher == "workspace": return f"Switch to Workspace {params}"
    if dispatcher == "movetoworkspace": return f"Move Window to Workspace {params}"
    if dispatcher == "movetoworkspace" and params == "special": return "Move to Special Scratchpad"
    
    return action

def get_category(raw_disp, action_text):
    action_text = action_text.lower()
    raw_disp = raw_disp.lower()
    
    # Workspaces
    if "workspace" in raw_disp or "movetoworkspace" in raw_disp:
        return "🔢 Workspaces"
    
    # Window Management
    if any(x in raw_disp for x in ["movewindow", "movefocus", "killactive", "fullscreen", "togglefloating", "togglesplit", "group"]):
        return "🪟 Window Management"
    
    # System Controls (Hardware, Session, Utilities)
    if any(x in raw_disp for x in ["volume", "brightness", "playerctl", "swaylock", "wlogout", "powermenu", "screenshot", "reload", "bluetooth", "wifi", "clipboard", "color picker", "dnd"]):
        return "🛠️ System Controls & Utilities"
    
    # Applications
    if "exec" in raw_disp:
        return "🚀 Application Shortcuts"
        
    return "⚙️ Other"

def main():
    if not os.path.exists(CONFIG_FILE):
        print(f"Error: Config file not found at {CONFIG_FILE}")
        return

    # Dictionary to ensure uniqueness: Key = Hotkey String, Value = Item Dict
    unique_bindings = {}

    # 1. Load Static Bindings first (can be overwritten by hyprland.conf if collision, or kept)
    for b in STATIC_BINDINGS:
        unique_bindings[b['key']] = b

    # 2. Parse Hyprland Config
    with open(CONFIG_FILE, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("bind =") or line.startswith("bindm ="):
                if "#" in line: line = line.split("#")[0] # Strip comments
                
                parts = line.split(",")
                if len(parts) >= 3:
                    mod_key = parts[0].split("=")[1].strip()
                    key = parts[1].strip()
                    dispatcher = parts[2].strip()
                    params = parts[3].strip() if len(parts) > 3 else ""

                    # Skip mouse move/resize specific binds if desired, or format them nicely
                    if "mouse" in key and "272" in key: key = "MOUSE LEFT DRAG"
                    elif "mouse" in key and "273" in key: key = "MOUSE RIGHT DRAG"
                    elif "mouse" in key: continue 

                    hotkey = parse_key(f"{mod_key} {key}")
                    action = parse_dispatcher(dispatcher, params)
                    raw_disp = f"{dispatcher} {params}"
                    category = get_category(raw_disp, action)

                    # Store/Overwrite in dictionary to deduplicate
                    unique_bindings[hotkey] = {
                        "category": category,
                        "key": hotkey,
                        "action": action
                    }

    # 3. Group by Category
    grouped = {}
    for hotkey, item in unique_bindings.items():
        cat = item['category']
        if cat not in grouped: grouped[cat] = []
        grouped[cat].append(item)

    # 4. Generate Markdown
    # Define category order
    cat_order = [
        "🚀 Application Shortcuts",
        "🪟 Window Management",
        "🔢 Workspaces",
        "🛠️ System Controls & Utilities",
        "🐚 Shell (Zsh)",
        "⚙️ Other"
    ]

    with open(OUTPUT_FILE, "w") as f:
        f.write(HEADER)
        
        for cat in cat_order:
            if cat in grouped and grouped[cat]:
                f.write(f"\n### {cat}\n\n")
                f.write("| Key Combination | Action |\n")
                f.write("| :--- | :--- |\n")
                # Sort bindings alphabetically within category
                sorted_items = sorted(grouped[cat], key=lambda x: x['key'])
                for item in sorted_items:
                    f.write(f"| `{item['key']}` | {item['action']} |\n")

    print(f"Successfully generated {OUTPUT_FILE}")

if __name__ == "__main__":
    main()