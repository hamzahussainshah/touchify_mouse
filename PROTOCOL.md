# TouchifyMouse — Communication Protocol & Architecture Reference

## Overview

Two apps communicate over a **local Wi-Fi network** (both devices on same network):

```
[ Flutter Mobile App ]  ──UDP 35900──▶  [ Python Desktop Agent ]
                        ──TCP 35901──▶
                        ◀──TCP 35901──
```

- **UDP port 35900** — Mouse movement only (low-latency, fire-and-forget)
- **TCP port 35901** — All other commands (reliable delivery): clicks, scroll, keyboard, media, audio

---

## 1. Connection Flow

### How Mobile Finds Desktop

**Method A — QR Code**
1. Desktop agent generates a QR code containing a JSON payload:
   ```json
   {
     "app": "touchifymouse",
     "ip": "192.168.1.10",
     "tcp_port": 35901,
     "udp_port": 35900,
     "name": "MyMacBook",
     "os": "darwin"
   }
   ```
2. Mobile scans QR → parses JSON → calls `socket.connect(ip, 35901)`

**Method B — mDNS (auto-discovery)**
- Desktop advertises `_touchifymouse._tcp.local.` via Zeroconf
- Mobile uses `bonsoir` (Flutter) to discover and list nearby desktops

**Method C — Manual IP**
- User types IP address directly in the connect screen

### Flutter Files Involved
| File | Role |
|------|------|
| `lib/features/connect/widgets/qr_connect_sheet.dart` | Scans QR, parses payload, calls `connect()` |
| `lib/features/connect/screens/connect_screen.dart` | Manual IP entry, mDNS device list |
| `lib/features/connect/services/mdns_discovery_service.dart` | mDNS scanning via bonsoir |
| `lib/core/providers/connection_provider.dart` | Stores connected device IP/port in Riverpod state |
| `lib/features/trackpad/services/trackpad_socket_service.dart` | Opens UDP + TCP sockets |
| `lib/features/trackpad/screens/trackpad_screen.dart` | Calls `socket.connect(ip)` on mount |

### Desktop Files Involved
| File | Role |
|------|------|
| `touchifymouse_desktop/__agent_rebuild/touchifymouse_agent.py` | Main Python agent |
| `touchifymouse_desktop/assets/bin/touchifymouse_agent` | Compiled binary (run by Flutter desktop app) |

---

## 2. Mouse Movement

### Protocol — UDP Binary Packet (9 bytes)

```
Byte 0:     0x01  (command type = mouse move)
Bytes 1–4:  float32 little-endian  → dx (horizontal delta)
Bytes 5–8:  float32 little-endian  → dy (vertical delta)
```

### Flutter → sends via:
```dart
// trackpad_socket_service.dart
void sendMouseMove(double dx, double dy) {
  final bdata = ByteData(9);
  bdata.setUint8(0, 0x01);
  bdata.setFloat32(1, dx, Endian.little);
  bdata.setFloat32(5, dy, Endian.little);
  _udpSocket!.send(bdata.buffer.asUint8List(), InternetAddress(ip), 35900);
}
```

### Python → receives via:
```python
# touchifymouse_agent.py — start_udp_server()
data, addr = s.recvfrom(1024)
if len(data) == 9 and data[0] == 0x01:
    dx, dy = struct.unpack('<ff', data[1:9])
    pyautogui.moveRel(dx, dy, _pause=False)
```

### Gesture Detection (trackpad_surface.dart)
| Gesture | Action |
|---------|--------|
| 1 finger drag | Mouse move (sendMouseMove) |
| 1 finger tap (moved < 8px) | Left click |
| 2 finger drag | Scroll |
| 2 finger tap (scroll < 12px) | Right click |

---

## 3. All TCP Commands — Full Protocol Reference

All TCP commands are **newline-delimited JSON** strings:
```
{"type": "click", "button": "left"}\n
```

### 3A. Mouse Clicks

| Action | JSON sent from mobile |
|--------|-----------------------|
| Left click | `{"type": "click", "button": "left"}` |
| Right click | `{"type": "click", "button": "right"}` |
| Middle click | `{"type": "click", "button": "middle"}` |
| Hold left (drag start) | `{"type": "mousedown", "button": "left"}` |
| Release left (drag end) | `{"type": "mouseup", "button": "left"}` |

**Python handler:**
```python
elif t == 'click':
    btn = cmd.get('button', 'left')
    if btn == 'left':    pyautogui.click()
    elif btn == 'right': pyautogui.rightClick()
    elif btn == 'middle':pyautogui.middleClick()

elif t == 'mousedown':
    pyautogui.mouseDown(button=cmd.get('button', 'left'))

elif t == 'mouseup':
    pyautogui.mouseUp(button=cmd.get('button', 'left'))
```

**Flutter sender:**
```dart
// trackpad_socket_service.dart
void sendClick(String button) =>
    sendRaw(jsonEncode({'type': 'click', 'button': button}));
```

### 3B. Scroll

| Action | JSON sent |
|--------|-----------|
| Vertical scroll | `{"type": "scroll", "deltaX": 0.0, "deltaY": -5.0}` |
| Horizontal scroll | `{"type": "scroll", "deltaX": 5.0, "deltaY": 0.0}` |

**Python handler:**
```python
elif t == 'scroll':
    dy = cmd.get('deltaY', 0)
    dx = cmd.get('deltaX', 0)
    pyautogui.scroll(int(-dy))        # negative = scroll up
    if dx != 0:
        pyautogui.hscroll(int(dx))
```

**Flutter sender:**
```dart
void sendScroll(double dx, double dy) =>
    sendRaw(jsonEncode({'type': 'scroll', 'deltaX': dx, 'deltaY': dy}));
```

> ⚠️ **Known issue:** `pyautogui.scroll()` takes integer steps.  
> Very small float deltas (< 1.0) get truncated to 0 → scroll appears not to work.  
> **Fix needed:** multiply delta by a scroll sensitivity factor (e.g. × 3) before sending, or use `int(-dy * 3)` on the Python side.

---

### 3C. Keyboard Keys

| Action | JSON sent |
|--------|-----------|
| Type a letter | `{"type": "key", "code": "a", "modifiers": []}` |
| Shift + A | `{"type": "key", "code": "a", "modifiers": ["shift"]}` |
| Cmd+C (copy) | `{"type": "key", "code": "c", "modifiers": ["cmd"]}` |
| Backspace | `{"type": "key", "code": "backspace", "modifiers": []}` |
| Enter | `{"type": "key", "code": "return", "modifiers": []}` |
| Space | `{"type": "key", "code": "space", "modifiers": []}` |
| Arrow Up | `{"type": "key", "code": "up", "modifiers": []}` |
| Arrow Down | `{"type": "key", "code": "down", "modifiers": []}` |
| Arrow Left | `{"type": "key", "code": "left", "modifiers": []}` |
| Arrow Right | `{"type": "key", "code": "right", "modifiers": []}` |
| Tab | `{"type": "key", "code": "tab", "modifiers": []}` |
| Escape | `{"type": "key", "code": "esc", "modifiers": []}` |

**Python key map (code → pyautogui key):**
```python
key_map = {
    'return':   'enter',
    'backspace':'backspace',
    'space':    'space',
    'up':       'up',
    'down':     'down',
    'left':     'left',
    'right':    'right',
    'cmd':      'command',
    'ctrl':     'ctrl',
    'alt':      'alt',
    'shift':    'shift',
    'tab':      'tab',
    'esc':      'escape',
    'delete':   'delete',
    'home':     'home',
    'end':      'end',
    'pageup':   'pageup',
    'pagedown': 'pagedown',
}
```

**Python handler:**
```python
elif t == 'key':
    code = cmd.get('code', '')
    modifiers = cmd.get('modifiers', [])
    mapped = key_map.get(code.lower(), code.lower())
    mods = [key_map.get(m, m) for m in modifiers]
    if mods:
        pyautogui.hotkey(*mods, mapped)
    else:
        pyautogui.press(mapped)
```

**Flutter sender:**
```dart
void sendKey(String code, List<String> modifiers) =>
    sendRaw(jsonEncode({'type': 'key', 'code': code, 'modifiers': modifiers}));
```

---

### 3D. Keyboard Shortcuts (Quick-action chips)

| Action | JSON sent |
|--------|-----------|
| App Switcher | `{"type": "shortcut", "action": "app_switcher"}` |
| Screenshot | `{"type": "shortcut", "action": "screenshot"}` |
| Lock Screen | `{"type": "shortcut", "action": "lock_screen"}` |
| Paste | `{"type": "shortcut", "action": "paste"}` |
| Copy | `{"type": "shortcut", "action": "copy"}` |
| Undo | `{"type": "shortcut", "action": "undo"}` |
| Mission Control | `{"type": "shortcut", "action": "mission_control"}` |
| Show Desktop | `{"type": "shortcut", "action": "show_desktop"}` |

**Python SHORTCUTS map:**
```python
SHORTCUTS = {
    'app_switcher':    {'Darwin': ('command', 'tab'),          'Windows': ('alt', 'tab')},
    'screenshot':      {'Darwin': ('command', 'shift', '3'),   'Windows': ('win', 'printscreen')},
    'lock_screen':     {'Darwin': ('command', 'control', 'q'), 'Windows': ('win', 'l')},
    'paste':           {'Darwin': ('command', 'v'),             'Windows': ('ctrl', 'v')},
    'copy':            {'Darwin': ('command', 'c'),             'Windows': ('ctrl', 'c')},
    'undo':            {'Darwin': ('command', 'z'),             'Windows': ('ctrl', 'z')},
    'mission_control': {'Darwin': ('control', 'up'),            'Windows': ('win', 'tab')},
    'show_desktop':    {'Darwin': ('command', 'f3'),            'Windows': ('win', 'd')},
}
```

---

### 3E. Media Controls

| Action | JSON sent |
|--------|-----------|
| Play / Pause | `{"type": "media", "action": "play_pause"}` |
| Next track | `{"type": "media", "action": "next"}` |
| Previous track | `{"type": "media", "action": "previous"}` |
| Mute | `{"type": "media", "action": "mute"}` |
| Volume | `{"type": "media", "action": "volume", "value": 0.75}` |
| Shuffle toggle | `{"type": "media", "action": "shuffle"}` |
| Repeat toggle | `{"type": "media", "action": "repeat"}` |

**Python — macOS key codes for media keys:**
```python
media_keycodes = {
    'play_pause': 16,   # NX_KEYTYPE_PLAY
    'next':       17,   # NX_KEYTYPE_FAST
    'previous':   18,   # NX_KEYTYPE_REWIND
    'mute':        7,   # NX_KEYTYPE_MUTE
}
# Sent via: osascript -e 'tell application "System Events" to key code N'
```

**Python — Windows virtual key codes:**
```python
vk_map = {
    'play_pause': 0xB3,   # VK_MEDIA_PLAY_PAUSE
    'next':       0xB0,   # VK_MEDIA_NEXT_TRACK
    'previous':   0xB1,   # VK_MEDIA_PREV_TRACK
    'mute':       0xAD,   # VK_VOLUME_MUTE
}
```

**Volume (macOS):**
```python
def handle_volume(value):   # value = 0.0 to 1.0
    vol = int(value * 100)
    subprocess.run(['osascript', '-e', f'set volume output volume {vol}'])
```

**Shuffle/Repeat (Spotify on macOS):**
```python
# Shuffle:  Cmd+Shift+S
# Repeat:   Cmd+Shift+R
pyautogui.hotkey('command', 'shift', 's')
```

---

### 3F. Audio Streaming

| Action | JSON sent |
|--------|-----------|
| Mic audio chunk | `{"type": "audio_mic_chunk", "data": "<base64_pcm>", "sampleRate": 44100}` |
| Start speaker stream | `{"type": "speaker_start"}` |
| Stop speaker stream | `{"type": "speaker_stop"}` |

**Flow:**
- Mobile → records PCM16 mono → base64 encodes → sends chunks over TCP
- Desktop → decodes base64 → plays via sounddevice
- Desktop → captures system audio → base64 encodes → sends chunks back
- Mobile → decodes → plays via device speaker

---

## 4. Known Issues & Fixes Needed

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| Scroll not working | `pyautogui.scroll(int(-dy))` where dy is tiny float → int(0) | Multiply delta: `int(-dy * 3)` in Python or scale before sending |
| Clicks not registering | TCP socket not connected before sending | Fixed: `socket.connect()` in `TrackpadScreen.initState` via `addPostFrameCallback` |
| Right-click fires during scroll | No scroll distance threshold | Fixed: only right-click if `_twoFingerScrollDelta < 12px` |
| Tap fires during drag | No movement threshold | Fixed: only left-click if `_singleFingerDelta < 8px` |
| Keyboard crashes app | `ref.read()` called from async socket code after provider disposal | Fixed: `TrackpadSocketService` is now a pure singleton |

---

## 5. File Map

```
touchify_mouse/
├── lib/                                    ← Flutter Mobile App
│   ├── main.dart                           ← App entry, SharedPreferences init
│   ├── core/
│   │   ├── providers/
│   │   │   ├── connection_provider.dart    ← Stores connected device state
│   │   │   ├── settings_provider.dart      ← User settings (speed, haptics)
│   │   │   └── connection_state_provider.dart ← Reactive socket connected stream
│   │   └── router/app_router.dart
│   └── features/
│       ├── connect/                        ← Connect screen (QR, IP, mDNS)
│       ├── trackpad/
│       │   ├── services/trackpad_socket_service.dart ← UDP + TCP socket
│       │   ├── screens/trackpad_screen.dart          ← Main screen, calls socket.connect()
│       │   └── widgets/
│       │       ├── trackpad_surface.dart   ← Gesture detection → sendMouseMove/Click/Scroll
│       │       └── click_buttons_bar.dart  ← LEFT/RIGHT/SCRL buttons
│       ├── keyboard/widgets/keyboard_panel.dart  ← Sends key events
│       ├── media/widgets/media_remote_panel.dart ← Sends media commands
│       └── audio/                          ← Mic/Speaker streaming
│
└── touchifymouse_desktop/                  ← Flutter Desktop App (macOS/Windows)
    ├── assets/bin/touchifymouse_agent      ← Python agent binary (PyInstaller)
    └── __agent_rebuild/
        └── touchifymouse_agent.py          ← Python source (rebuild here)
```

---

## 6. How to Rebuild the Desktop Agent Binary

```bash
cd touchifymouse_desktop/__agent_rebuild

# Install deps + build
./venv_build/bin/pip install pyautogui zeroconf pillow "qrcode[pil]" pyinstaller
./venv_build/bin/pyinstaller --onefile --noconfirm touchifymouse_agent.py

# Copy to Flutter assets
cp dist/touchifymouse_agent ../assets/bin/touchifymouse_agent

# Rebuild Flutter desktop app
cd ..
bash scripts/build_dmg.sh    # macOS DMG
```
