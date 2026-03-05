# Virtual Keyboard and Mouse Controller

A system that allows your mobile phone to act as a virtual keyboard and mouse for a Windows computer.

## Architecture

- **Mobile App (Flutter)**: Acts as the client, sending input events
- **Windows Server (Python)**: Receives events and executes them on the system

## Quick Start

### 1. Start the Windows Server

```powershell
cd server
pip install -r requirements.txt
python server.py
```

The server will display your PC's IP address and port.

### 2. Run the Mobile App

```powershell
cd mobile_app
flutter pub get
flutter run
```

### 3. Connect

1. Open the mobile app on your phone
2. Enter the PC's IP address shown in the server console
3. Tap "Connect"

## Features

### Mouse Control
- **Single finger drag**: Move mouse cursor
- **Single tap**: Left click
- **Double tap**: Double click
- **Two finger scroll**: Scroll up/down
- **Long press**: Start drag operation
- Dedicated buttons for left, middle, and right click

### Keyboard Control
- Full QWERTY keyboard
- Function keys (F1-F12)
- Arrow keys and navigation (Home, End, PgUp, PgDn)
- Modifier keys (Shift, Ctrl, Alt, Caps Lock)
- Quick text input field

## Communication Protocol

The app communicates via WebSocket using JSON messages:

### Mouse Events
```json
{"type": "mouse_move", "dx": 10, "dy": -5}
{"type": "mouse_click", "button": "left", "clicks": 1}
{"type": "mouse_scroll", "dx": 0, "dy": 3}
{"type": "mouse_drag_start"}
{"type": "mouse_drag_end"}
```

### Keyboard Events
```json
{"type": "key_tap", "key": "a"}
{"type": "key_press", "key": "shift"}
{"type": "key_release", "key": "shift"}
```

## Requirements

### Server (Windows)
- Python 3.8+
- websockets
- pyautogui
- pynput

### Mobile App
- Flutter 3.0+
- Android 5.0+ or iOS 11+

## Troubleshooting

### Connection Issues
1. Ensure both devices are on the same Wi-Fi network
2. Check if Windows Firewall is blocking port 8765
3. Verify the IP address is correct

### Input Not Working
1. Make sure the server console is not minimized
2. Some applications may require the server to run as Administrator

## Security Note

This application allows remote control of your computer. Only use it on trusted networks and with trusted devices.
