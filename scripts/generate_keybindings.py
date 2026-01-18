#!/usr/bin/env python3
import os
import re

# Paths
REPO_ROOT = os.path.expanduser("~/Hyprland-Arch-Config")
CONFIG_FILE = os.path.join(REPO_ROOT, "dotfiles/hypr/hyprland.conf")
OUTPUT_FILE = os.path.join(REPO_ROOT, "Keybindings.md")

# Header for the Markdown file
HEADER = """# ⌨️ Hyprland Keybindings

This file is **automatically generated** from the active `hyprland.conf`. 
Any changes made to the configuration will be reflected here after a repository sync.

**Modifier Key:** `SUPER` (Windows Key)

## 🖥️ System & Session
"""

# Categorization logic (simple keyword matching)
CATEGORIES = {
    "Apps": ["exec, wezterm", "exec, code", "exec, firefox", "exec, brave", "exec, thunar", "exec, obsidian", "exec, telegram", "exec, libreoffice"],
    "System": ["exec, swaylock", "exec, wlogout", "reload", "exec, ~/.config/hypr/powermenu.sh"],
    "Window Management": ["killactive", "togglesplit", "togglefloating", "fullscreen", "movefocus", "movewindow", "resize"],
    "Workspaces": ["workspace", "movetoworkspace"],
    "Hardware & Media": ["volume", "brightness", "playerctl"],
    "Utilities": ["grim", "slurp", "cliphist", "ocr", "color picker", "clipboard"],
    "Scratchpad": ["special"]
}

def parse_key(key_part):
    key_part = key_part.replace("$mainMod", "SUPER").replace("$mod", "SUPER")
    parts = [p.strip() for p in key_part.split(" ") if p.strip()]
    return " + ".join(parts).upper()

def parse_dispatcher(dispatcher, params):
    action = f"{dispatcher} {params}".strip()
    
    # Beautify common actions
    if "exec" in dispatcher:
        cmd = params.split("/")[-1].replace(".sh", "").replace("-", " ").title()
        if "Wezterm" in cmd: return "Terminal (WezTerm)"
        if "Code" in cmd: return "VS Code"
        if "Thunar" in cmd: return "File Manager (Thunar)"
        if "Brave" in cmd: return "Web Browser (Brave)"
        if "Grim" in cmd: return "Screenshot"
        if "Wofi" in cmd or "Smart_Launcher" in cmd: return "App Launcher"
        return f"Launch {cmd}"
    
    if dispatcher == "killactive": return "Close Active Window"
    if dispatcher == "togglesplit": return "Toggle Split Direction"
    if dispatcher == "togglefloating": return "Toggle Floating Mode"
    if dispatcher == "fullscreen": return "Toggle Fullscreen"
    if dispatcher == "movefocus": return f"Move Focus {params.upper()}"
    if dispatcher == "movewindow": return f"Move Window {params.upper()}"
    if dispatcher == "workspace": return f"Switch to Workspace {params}"
    if dispatcher == "movetoworkspace": return f"Move Window to Workspace {params}"
    
    return action

def main():
    if not os.path.exists(CONFIG_FILE):
        print(f"Error: Config file not found at {CONFIG_FILE}")
        return

    bindings = []
    
    with open(CONFIG_FILE, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("bind =") or line.startswith("bindm ="):
                # Remove comments
                if "#" in line:
                    line = line.split("#")[0]
                
                parts = line.split(",")
                if len(parts) >= 3:
                    # Format: bind = MOD, KEY, DISPATCHER, PARAMS
                    mod_key = parts[0].split("=")[1].strip()
                    key = parts[1].strip()
                    dispatcher = parts[2].strip()
                    params = parts[3].strip() if len(parts) > 3 else ""
                    
                    # Clean up mouse binds
                    if "mouse" in key:
                        continue # Skip mouse binds for the simplified table for now
                    
                    hotkey = parse_key(f"{mod_key} {key}")
                    action = parse_dispatcher(dispatcher, params)
                    
                    bindings.append({"key": hotkey, "action": action, "raw_disp": f"{dispatcher} {params}"})

    # Generate Markdown
    with open(OUTPUT_FILE, "w") as f:
        f.write(HEADER)
        
        # Helper to write table
        def write_category(name, filter_func):
            f.write(f"\n### {name}\n\n")
            f.write("| Key Combination | Action |\n")
            f.write("| :--- | :--- |\n")
            count = 0
            for b in bindings:
                if filter_func(b):
                    f.write(f"| `{b['key']}` | {b['action']} |\n")
                    count += 1
            if count == 0:
                f.write("| - | No bindings found |\n")

        # Define categories
        write_category("🪟 Window Management", lambda b: any(k in b['raw_disp'] for k in ["killactive", "togglesplit", "togglefloating", "fullscreen", "movefocus", "movewindow"]))
        write_category("🚀 Applications", lambda b: "exec" in b['raw_disp'] and not any(k in b['raw_disp'] for k in ["volume", "brightness", "swaylock", "wlogout", "powermenu", "screenshot", "grim"]))
        write_category("🖥️ System & Session", lambda b: any(k in b['raw_disp'] for k in ["swaylock", "powermenu", "reload", "wlogout", "exit"]))
        write_category("🔢 Workspaces", lambda b: "workspace" in b['raw_disp'] and "movetoworkspace" not in b['raw_disp'])
        write_category("📦 Move to Workspace", lambda b: "movetoworkspace" in b['raw_disp'])
        write_category("🔊 Hardware & Media", lambda b: any(k in b['raw_disp'] for k in ["volume", "brightness", "playerctl"]))
        write_category("🛠️ Utilities", lambda b: "grim" in b['raw_disp'] or "slurp" in b['raw_disp'] or "clipboard" in b['raw_disp'])

    print(f"Successfully generated {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
