"""
Creates a desktop shortcut for the Virtual Controller Server.
Run this once to add a shortcut to your desktop.
"""

import os
import sys

def create_shortcut():
    desktop = os.path.join(os.environ["USERPROFILE"], "Desktop")
    shortcut_path = os.path.join(desktop, "Virtual Controller Server.bat")

    server_dir = os.path.dirname(os.path.abspath(__file__))
    venv_python = os.path.join(server_dir, "..", ".venv", "Scripts", "pythonw.exe")
    venv_python = os.path.abspath(venv_python)

    # Fallback to python.exe if pythonw.exe doesn't exist
    if not os.path.exists(venv_python):
        venv_python = os.path.join(server_dir, "..", ".venv", "Scripts", "python.exe")
        venv_python = os.path.abspath(venv_python)

    if not os.path.exists(venv_python):
        venv_python = sys.executable

    gui_script = os.path.join(server_dir, "server_gui.py")

    bat_content = f'''@echo off
cd /d "{server_dir}"
start "" "{venv_python}" "{gui_script}"
'''

    with open(shortcut_path, "w") as f:
        f.write(bat_content)

    print(f"Desktop shortcut created: {shortcut_path}")
    print("You can now double-click 'Virtual Controller Server' on your desktop!")

    # Also try to create a proper .lnk shortcut via PowerShell
    try:
        lnk_path = os.path.join(desktop, "Virtual Controller Server.lnk")
        icon_target = venv_python
        ps_cmd = f'''
$ws = New-Object -ComObject WScript.Shell
$s = $ws.CreateShortcut("{lnk_path}")
$s.TargetPath = "{venv_python}"
$s.Arguments = '"{gui_script}"'
$s.WorkingDirectory = "{server_dir}"
$s.Description = "Virtual Keyboard & Mouse Controller Server"
$s.Save()
'''
        os.system(f'powershell -Command "{ps_cmd.strip()}"')
        # Remove .bat if .lnk created successfully
        if os.path.exists(lnk_path):
            os.remove(shortcut_path)
            print(f"Created proper shortcut: {lnk_path}")
    except Exception:
        print("Using .bat shortcut (couldn't create .lnk)")


if __name__ == "__main__":
    create_shortcut()
