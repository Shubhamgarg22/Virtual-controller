"""
Virtual Keyboard & Mouse Controller - Desktop Server (GUI)
Double-click to start. Shows IP address, port, connection status, and logs.
"""

import asyncio
import json
import os
import socket
import subprocess
import sys
import threading
import tkinter as tk
from tkinter import scrolledtext
from datetime import datetime

import pyautogui
from pynput.keyboard import Controller as KeyboardController, Key
import websockets

# --- Input handling (same as server.py) ---

pyautogui.FAILSAFE = True
pyautogui.PAUSE = 0

keyboard = KeyboardController()

SPECIAL_KEYS = {
    'enter': Key.enter, 'space': Key.space, 'backspace': Key.backspace,
    'tab': Key.tab, 'escape': Key.esc, 'shift': Key.shift,
    'ctrl': Key.ctrl, 'alt': Key.alt,
    'up': Key.up, 'down': Key.down, 'left': Key.left, 'right': Key.right,
    'caps_lock': Key.caps_lock, 'delete': Key.delete,
    'home': Key.home, 'end': Key.end,
    'page_up': Key.page_up, 'page_down': Key.page_down,
    'f1': Key.f1, 'f2': Key.f2, 'f3': Key.f3, 'f4': Key.f4,
    'f5': Key.f5, 'f6': Key.f6, 'f7': Key.f7, 'f8': Key.f8,
    'f9': Key.f9, 'f10': Key.f10, 'f11': Key.f11, 'f12': Key.f12,
}


def handle_mouse_move(data):
    pyautogui.moveRel(data.get('dx', 0), data.get('dy', 0), duration=0)

def handle_mouse_click(data):
    button = data.get('button', 'left')
    if button == 'left':
        pyautogui.click(clicks=data.get('clicks', 1))
    elif button == 'right':
        pyautogui.rightClick()
    elif button == 'middle':
        pyautogui.middleClick()

def handle_mouse_scroll(data):
    dy = data.get('dy', 0)
    dx = data.get('dx', 0)
    if dy != 0:
        pyautogui.scroll(int(dy))
    if dx != 0:
        pyautogui.hscroll(int(dx))

def handle_mouse_drag_start(data):
    pyautogui.mouseDown()

def handle_mouse_drag_end(data):
    pyautogui.mouseUp()

def handle_key_press(data):
    key = data.get('key', '')
    k = key.lower()
    if k in SPECIAL_KEYS:
        keyboard.press(SPECIAL_KEYS[k])
    elif len(key) == 1:
        keyboard.press(key)

def handle_key_release(data):
    key = data.get('key', '')
    k = key.lower()
    if k in SPECIAL_KEYS:
        keyboard.release(SPECIAL_KEYS[k])
    elif len(key) == 1:
        keyboard.release(key)

def handle_key_tap(data):
    key = data.get('key', '')
    k = key.lower()
    if k in SPECIAL_KEYS:
        keyboard.press(SPECIAL_KEYS[k])
        keyboard.release(SPECIAL_KEYS[k])
    elif len(key) == 1:
        keyboard.press(key)
        keyboard.release(key)

def handle_text_input(data):
    pyautogui.typewrite(data.get('text', ''), interval=0.01)

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


def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


# --- GUI Application ---

class ServerApp:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Virtual Controller Server")
        self.root.geometry("520x480")
        self.root.resizable(False, False)
        self.root.configure(bg="#1e1e2e")

        self.server = None
        self.loop = None
        self.server_thread = None
        self.running = False
        self.connected_clients = 0
        self.port = 8765

        self._build_ui()
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)

    def _build_ui(self):
        bg = "#1e1e2e"
        fg = "#cdd6f4"
        accent = "#89b4fa"
        green = "#a6e3a1"
        red = "#f38ba8"
        surface = "#313244"

        # Title
        title_frame = tk.Frame(self.root, bg=bg)
        title_frame.pack(fill="x", padx=20, pady=(15, 5))
        tk.Label(title_frame, text="🖥️  Virtual Controller Server",
                 font=("Segoe UI", 16, "bold"), bg=bg, fg=fg).pack(anchor="w")

        # Info card
        info_frame = tk.Frame(self.root, bg=surface, highlightbackground="#45475a",
                              highlightthickness=1)
        info_frame.pack(fill="x", padx=20, pady=10)

        ip = get_local_ip()

        row1 = tk.Frame(info_frame, bg=surface)
        row1.pack(fill="x", padx=15, pady=(12, 4))
        tk.Label(row1, text="IP Address:", font=("Segoe UI", 11),
                 bg=surface, fg="#a6adc8").pack(side="left")
        self.ip_label = tk.Label(row1, text=ip, font=("Segoe UI", 14, "bold"),
                                 bg=surface, fg=accent)
        self.ip_label.pack(side="right")

        row2 = tk.Frame(info_frame, bg=surface)
        row2.pack(fill="x", padx=15, pady=4)
        tk.Label(row2, text="Port:", font=("Segoe UI", 11),
                 bg=surface, fg="#a6adc8").pack(side="left")
        tk.Label(row2, text=str(self.port), font=("Segoe UI", 14, "bold"),
                 bg=surface, fg=accent).pack(side="right")

        row3 = tk.Frame(info_frame, bg=surface)
        row3.pack(fill="x", padx=15, pady=(4, 6))
        tk.Label(row3, text="Status:", font=("Segoe UI", 11),
                 bg=surface, fg="#a6adc8").pack(side="left")
        self.status_label = tk.Label(row3, text="● Stopped",
                                     font=("Segoe UI", 11, "bold"),
                                     bg=surface, fg=red)
        self.status_label.pack(side="right")

        row4 = tk.Frame(info_frame, bg=surface)
        row4.pack(fill="x", padx=15, pady=(0, 12))
        tk.Label(row4, text="Clients:", font=("Segoe UI", 11),
                 bg=surface, fg="#a6adc8").pack(side="left")
        self.clients_label = tk.Label(row4, text="0",
                                      font=("Segoe UI", 11, "bold"),
                                      bg=surface, fg=fg)
        self.clients_label.pack(side="right")

        # Buttons
        btn_frame = tk.Frame(self.root, bg=bg)
        btn_frame.pack(fill="x", padx=20, pady=5)

        self.start_btn = tk.Button(btn_frame, text="▶  Start Server",
                                   font=("Segoe UI", 12, "bold"),
                                   bg="#a6e3a1", fg="#1e1e2e",
                                   activebackground="#94e2d5",
                                   relief="flat", cursor="hand2",
                                   command=self._start_server)
        self.start_btn.pack(side="left", expand=True, fill="x", padx=(0, 5), ipady=6)

        self.stop_btn = tk.Button(btn_frame, text="⏹  Stop Server",
                                  font=("Segoe UI", 12, "bold"),
                                  bg="#f38ba8", fg="#1e1e2e",
                                  activebackground="#eba0ac",
                                  relief="flat", cursor="hand2",
                                  state="disabled",
                                  command=self._stop_server)
        self.stop_btn.pack(side="right", expand=True, fill="x", padx=(5, 0), ipady=6)

        # Log
        log_label = tk.Frame(self.root, bg=bg)
        log_label.pack(fill="x", padx=20, pady=(10, 2))
        tk.Label(log_label, text="Activity Log", font=("Segoe UI", 10, "bold"),
                 bg=bg, fg="#a6adc8").pack(anchor="w")

        self.log_text = scrolledtext.ScrolledText(
            self.root, height=10, font=("Consolas", 9),
            bg="#11111b", fg="#cdd6f4", insertbackground=fg,
            selectbackground=accent, relief="flat", state="disabled",
            wrap="word"
        )
        self.log_text.pack(fill="both", expand=True, padx=20, pady=(0, 15))

        # Instruction at bottom
        tk.Label(self.root,
                 text="Open the mobile app → enter the IP above → tap Connect",
                 font=("Segoe UI", 9), bg=bg, fg="#585b70").pack(pady=(0, 10))

    def _log(self, message):
        timestamp = datetime.now().strftime("%H:%M:%S")
        line = f"[{timestamp}] {message}\n"

        def _append():
            self.log_text.configure(state="normal")
            self.log_text.insert("end", line)
            self.log_text.see("end")
            self.log_text.configure(state="disabled")

        self.root.after(0, _append)

    def _update_status(self, running, clients=None):
        def _update():
            if running:
                self.status_label.config(text="● Running", fg="#a6e3a1")
                self.start_btn.config(state="disabled")
                self.stop_btn.config(state="normal")
            else:
                self.status_label.config(text="● Stopped", fg="#f38ba8")
                self.start_btn.config(state="normal")
                self.stop_btn.config(state="disabled")
            if clients is not None:
                self.clients_label.config(text=str(clients))
        self.root.after(0, _update)

    def _add_firewall_rule(self):
        """Add Windows Firewall rule to allow connections on the server port."""
        try:
            # Check if rule already exists
            check = subprocess.run(
                ["netsh", "advfirewall", "firewall", "show", "rule",
                 "name=Virtual Controller Server"],
                capture_output=True, text=True, creationflags=0x08000000
            )
            if "Virtual Controller Server" in check.stdout:
                self._log("Firewall rule already exists.")
                return

            # Add rule using netsh (doesn't always need admin for inbound allow)
            result = subprocess.run(
                ["netsh", "advfirewall", "firewall", "add", "rule",
                 "name=Virtual Controller Server",
                 "dir=in", "action=allow", "protocol=TCP",
                 f"localport={self.port}", "profile=any"],
                capture_output=True, text=True, creationflags=0x08000000
            )
            if result.returncode == 0:
                self._log("Firewall rule added successfully.")
            else:
                self._log("Could not add firewall rule (run as Admin if needed).")
        except Exception as e:
            self._log(f"Firewall config skipped: {e}")

    def _start_server(self):
        if self.running:
            return
        self.running = True
        self._update_status(True, 0)
        self._log("Starting server...")

        # Try to add firewall rule
        threading.Thread(target=self._add_firewall_rule, daemon=True).start()

        self.server_thread = threading.Thread(target=self._run_server, daemon=True)
        self.server_thread.start()

    def _stop_server(self):
        if not self.running:
            return
        self.running = False
        self._log("Stopping server...")

        if self.server:
            self.server.close()
        if self.loop:
            self.loop.call_soon_threadsafe(self.loop.stop)

        self.connected_clients = 0
        self._update_status(False, 0)
        self._log("Server stopped.")

    def _run_server(self):
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)

        async def handle_client(websocket):
            addr = websocket.remote_address
            self.connected_clients += 1
            self._update_status(True, self.connected_clients)
            self._log(f"Client connected: {addr[0]}:{addr[1]}")

            try:
                async for message in websocket:
                    try:
                        data = json.loads(message)
                        msg_type = data.get('type', '')
                        if msg_type in MESSAGE_HANDLERS:
                            MESSAGE_HANDLERS[msg_type](data)
                        elif msg_type == 'ping':
                            await websocket.send(json.dumps({'type': 'pong'}))
                    except json.JSONDecodeError:
                        pass
                    except Exception as e:
                        self._log(f"Error: {e}")
            except websockets.exceptions.ConnectionClosed:
                pass
            except Exception as e:
                self._log(f"Connection error: {e}")
            finally:
                self.connected_clients = max(0, self.connected_clients - 1)
                self._update_status(True, self.connected_clients)
                self._log(f"Client disconnected: {addr[0]}:{addr[1]}")

        async def serve():
            try:
                self.server = await websockets.serve(handle_client, "0.0.0.0", self.port)
                ip = get_local_ip()
                self._log(f"Server running on {ip}:{self.port}")
                self._log("Waiting for connections...")
                await asyncio.Future()
            except OSError as e:
                self._log(f"Error: {e}")
                self._update_status(False)
                self.running = False

        try:
            self.loop.run_until_complete(serve())
        except RuntimeError:
            pass

    def _on_close(self):
        self._stop_server()
        self.root.destroy()

    def run(self):
        # Auto-start the server
        self.root.after(500, self._start_server)
        self.root.mainloop()


if __name__ == "__main__":
    app = ServerApp()
    app.run()
