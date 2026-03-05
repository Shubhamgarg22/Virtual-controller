"""
Virtual Keyboard and Mouse Controller - Windows Server
A WebSocket server that receives input events from a mobile app and executes
mouse and keyboard actions on the Windows system.
"""

import asyncio
import json
import socket
import pyautogui
from pynput.keyboard import Controller as KeyboardController, Key
import websockets

# Disable pyautogui fail-safe (move mouse to corner to abort)
pyautogui.FAILSAFE = True
pyautogui.PAUSE = 0  # Remove delay between pyautogui commands

# Initialize keyboard controller
keyboard = KeyboardController()

# Special key mapping
SPECIAL_KEYS = {
    'enter': Key.enter,
    'space': Key.space,
    'backspace': Key.backspace,
    'tab': Key.tab,
    'escape': Key.esc,
    'shift': Key.shift,
    'ctrl': Key.ctrl,
    'alt': Key.alt,
    'up': Key.up,
    'down': Key.down,
    'left': Key.left,
    'right': Key.right,
    'caps_lock': Key.caps_lock,
    'delete': Key.delete,
    'home': Key.home,
    'end': Key.end,
    'page_up': Key.page_up,
    'page_down': Key.page_down,
    'f1': Key.f1,
    'f2': Key.f2,
    'f3': Key.f3,
    'f4': Key.f4,
    'f5': Key.f5,
    'f6': Key.f6,
    'f7': Key.f7,
    'f8': Key.f8,
    'f9': Key.f9,
    'f10': Key.f10,
    'f11': Key.f11,
    'f12': Key.f12,
}


def get_local_ip():
    """Get the local IP address of this machine."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def handle_mouse_move(data):
    """Handle mouse movement."""
    dx = data.get('dx', 0)
    dy = data.get('dy', 0)
    # Move relative to current position
    pyautogui.moveRel(dx, dy, duration=0)


def handle_mouse_click(data):
    """Handle mouse click."""
    button = data.get('button', 'left')
    clicks = data.get('clicks', 1)
    
    if button == 'left':
        pyautogui.click(clicks=clicks)
    elif button == 'right':
        pyautogui.rightClick()
    elif button == 'middle':
        pyautogui.middleClick()


def handle_mouse_scroll(data):
    """Handle mouse scroll."""
    dx = data.get('dx', 0)
    dy = data.get('dy', 0)
    
    # pyautogui scroll: positive = up, negative = down
    if dy != 0:
        pyautogui.scroll(int(dy))
    if dx != 0:
        pyautogui.hscroll(int(dx))


def handle_mouse_drag_start(data):
    """Handle drag start (mouse down)."""
    pyautogui.mouseDown()


def handle_mouse_drag_end(data):
    """Handle drag end (mouse up)."""
    pyautogui.mouseUp()


def handle_key_press(data):
    """Handle keyboard key press."""
    key = data.get('key', '')
    key_lower = key.lower()
    
    if key_lower in SPECIAL_KEYS:
        keyboard.press(SPECIAL_KEYS[key_lower])
    elif len(key) == 1:
        keyboard.press(key)


def handle_key_release(data):
    """Handle keyboard key release."""
    key = data.get('key', '')
    key_lower = key.lower()
    
    if key_lower in SPECIAL_KEYS:
        keyboard.release(SPECIAL_KEYS[key_lower])
    elif len(key) == 1:
        keyboard.release(key)


def handle_key_tap(data):
    """Handle keyboard key tap (press and release)."""
    key = data.get('key', '')
    key_lower = key.lower()
    
    if key_lower in SPECIAL_KEYS:
        keyboard.press(SPECIAL_KEYS[key_lower])
        keyboard.release(SPECIAL_KEYS[key_lower])
    elif len(key) == 1:
        keyboard.press(key)
        keyboard.release(key)


def handle_text_input(data):
    """Handle text input (type a string)."""
    text = data.get('text', '')
    pyautogui.typewrite(text, interval=0.01)


# Message handlers mapping
MESSAGE_HANDLERS = {
    'mouse_move': handle_mouse_move,
    'mouse_click': handle_mouse_click,
    'mouse_scroll': handle_mouse_scroll,
    'mouse_drag_start': handle_mouse_drag_start,
    'mouse_drag_end': handle_mouse_drag_end,
    'key_press': handle_key_press,
    'key_release': handle_key_release,
    'key_tap': handle_key_tap,
    'text_input': handle_text_input,
}


async def handle_client(websocket):
    """Handle a connected client."""
    client_address = websocket.remote_address
    print(f"[+] Client connected: {client_address}")
    
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                msg_type = data.get('type', '')
                
                if msg_type in MESSAGE_HANDLERS:
                    MESSAGE_HANDLERS[msg_type](data)
                elif msg_type == 'ping':
                    await websocket.send(json.dumps({'type': 'pong'}))
                else:
                    print(f"[!] Unknown message type: {msg_type}")
                    
            except json.JSONDecodeError:
                print(f"[!] Invalid JSON received: {message}")
            except Exception as e:
                print(f"[!] Error handling message: {e}")
                
    except websockets.exceptions.ConnectionClosed:
        print(f"[-] Client disconnected: {client_address}")
    except Exception as e:
        print(f"[!] Connection error: {e}")


async def main():
    """Main server entry point."""
    host = "0.0.0.0"
    port = 8765
    
    local_ip = get_local_ip()
    
    print("=" * 50)
    print("  Virtual Keyboard & Mouse Controller - Server")
    print("=" * 50)
    print(f"\n  Local IP Address: {local_ip}")
    print(f"  Port: {port}")
    print(f"\n  Connect your mobile app to: {local_ip}:{port}")
    print("\n  Waiting for connections...")
    print("=" * 50)
    
    async with websockets.serve(handle_client, host, port):
        await asyncio.Future()  # Run forever


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n[*] Server stopped.")
