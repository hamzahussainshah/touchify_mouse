# TouchifyMouse — Full Functionality Fix Guide
# For: Anti-Gravity / Gemini coding agent
# Status: App connects but NOTHING works (clicks, scroll, keyboard, media, audio)

---

## ARCHITECTURE SUMMARY (read this first)

The app has TWO parts:
1. Flutter mobile app (phone) — sends commands
2. Python desktop agent (laptop) — receives and executes commands

Communication:
- UDP port 35900 → mouse movement only (binary 9-byte packets)
- TCP port 35901 → everything else (newline-delimited JSON)

The phone connects, but commands are either not being sent, 
not being received, or not being executed. Fix ALL layers.

---

## CRITICAL ISSUE: THE ROOT CAUSE

The most likely reason everything stopped working at once is one of:

A) The TCP socket in Flutter is not actually connected when commands are sent
B) The Python agent TCP handler is crashing silently on first command
C) The JSON is malformed or missing the newline terminator
D) The socket service is being disposed/recreated incorrectly

Fix ALL of the following. Do not skip any section.

---

## FIX 1 — PYTHON AGENT: ADD FULL DEBUG LOGGING

This is the FIRST thing to do. Without logs you cannot debug.

File: `touchifymouse_desktop/__agent_rebuild/touchifymouse_agent.py`

Replace the entire TCP handler with this version that logs everything:

```python
import socket
import struct
import threading
import json
import subprocess
import platform
import traceback
import sys
import logging

# Setup logging to both console and file
logging.basicConfig(
    level=logging.DEBUG,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('/tmp/touchifymouse_debug.log')
    ]
)
log = logging.getLogger('TouchifyMouse')

OS = platform.system()  # 'Darwin' or 'Windows'

# ─── TCP HANDLER ───────────────────────────────────────────────────────────────

def handle_client(conn, addr):
    log.info(f"Phone connected from {addr}")
    buffer = ""
    try:
        while True:
            chunk = conn.recv(4096)
            if not chunk:
                log.info(f"Phone disconnected: {addr}")
                break
            
            raw = chunk.decode('utf-8', errors='replace')
            log.debug(f"RAW RECEIVED ({len(chunk)} bytes): {repr(raw[:200])}")
            buffer += raw
            
            # Process all complete lines
            while '\n' in buffer:
                line, buffer = buffer.split('\n', 1)
                line = line.strip()
                if not line:
                    continue
                log.debug(f"PROCESSING LINE: {line[:200]}")
                try:
                    cmd = json.loads(line)
                    log.info(f"COMMAND: type={cmd.get('type')} data={cmd}")
                    execute_command(cmd, conn)
                except json.JSONDecodeError as e:
                    log.error(f"JSON PARSE ERROR: {e} | Line was: {repr(line)}")
                except Exception as e:
                    log.error(f"COMMAND EXECUTE ERROR: {e}")
                    log.error(traceback.format_exc())
    except Exception as e:
        log.error(f"CLIENT HANDLER CRASH: {e}")
        log.error(traceback.format_exc())
    finally:
        conn.close()
        log.info(f"Connection closed: {addr}")


def execute_command(cmd, conn):
    t = cmd.get('type', '')
    log.info(f"EXECUTING: {t}")
    
    # ── MOUSE CLICKS ────────────────────────────────────────────────────────────
    if t == 'click':
        btn = cmd.get('button', 'left')
        log.info(f"CLICK: {btn}")
        import pyautogui
        pyautogui.FAILSAFE = False
        if btn == 'left':
            pyautogui.click()
        elif btn == 'right':
            pyautogui.rightClick()
        elif btn == 'middle':
            pyautogui.middleClick()
        log.info(f"CLICK DONE: {btn}")
    
    elif t == 'mousedown':
        import pyautogui
        pyautogui.FAILSAFE = False
        pyautogui.mouseDown(button=cmd.get('button', 'left'))
        log.info("MOUSEDOWN sent")
    
    elif t == 'mouseup':
        import pyautogui
        pyautogui.FAILSAFE = False
        pyautogui.mouseUp(button=cmd.get('button', 'left'))
        log.info("MOUSEUP sent")
    
    # ── SCROLL ──────────────────────────────────────────────────────────────────
    elif t == 'scroll':
        import pyautogui
        pyautogui.FAILSAFE = False
        raw_dy = cmd.get('deltaY', 0)
        raw_dx = cmd.get('deltaX', 0)
        # IMPORTANT: multiply by sensitivity — raw flutter delta is tiny floats
        # int() of small float = 0, which is why scroll appeared broken
        scroll_sensitivity = 3
        dy = int(-raw_dy * scroll_sensitivity)
        dx = int(raw_dx * scroll_sensitivity)
        log.info(f"SCROLL: rawDy={raw_dy} rawDx={raw_dx} → dy={dy} dx={dx}")
        if dy != 0:
            pyautogui.scroll(dy)
        if dx != 0:
            pyautogui.hscroll(dx)
        log.info("SCROLL DONE")
    
    # ── KEYBOARD ────────────────────────────────────────────────────────────────
    elif t == 'key':
        import pyautogui
        pyautogui.FAILSAFE = False
        code = cmd.get('code', '')
        modifiers = cmd.get('modifiers', [])
        key_map = {
            'return': 'enter', 'backspace': 'backspace', 'space': 'space',
            'up': 'up', 'down': 'down', 'left': 'left', 'right': 'right',
            'cmd': 'command', 'ctrl': 'ctrl', 'alt': 'alt', 'shift': 'shift',
            'tab': 'tab', 'esc': 'escape', 'delete': 'delete',
            'home': 'home', 'end': 'end', 'pageup': 'pageup', 'pagedown': 'pagedown',
            'f1':'f1','f2':'f2','f3':'f3','f4':'f4','f5':'f5','f6':'f6',
            'f7':'f7','f8':'f8','f9':'f9','f10':'f10','f11':'f11','f12':'f12',
        }
        mapped_code = key_map.get(code.lower(), code.lower())
        mapped_mods = [key_map.get(m.lower(), m.lower()) for m in modifiers]
        log.info(f"KEY: code={code}→{mapped_code} mods={modifiers}→{mapped_mods}")
        if mapped_mods:
            pyautogui.hotkey(*mapped_mods, mapped_code)
        else:
            pyautogui.press(mapped_code)
        log.info("KEY DONE")
    
    # ── SHORTCUTS ───────────────────────────────────────────────────────────────
    elif t == 'shortcut':
        import pyautogui
        pyautogui.FAILSAFE = False
        action = cmd.get('action', '')
        SHORTCUTS = {
            'app_switcher':    {'Darwin': ('command','tab'),          'Windows': ('alt','tab')},
            'screenshot':      {'Darwin': ('command','shift','3'),    'Windows': ('win','printscreen')},
            'lock_screen':     {'Darwin': ('command','control','q'),  'Windows': ('win','l')},
            'paste':           {'Darwin': ('command','v'),             'Windows': ('ctrl','v')},
            'copy':            {'Darwin': ('command','c'),             'Windows': ('ctrl','c')},
            'undo':            {'Darwin': ('command','z'),             'Windows': ('ctrl','z')},
            'mission_control': {'Darwin': ('control','up'),            'Windows': ('win','tab')},
            'show_desktop':    {'Darwin': ('command','f3'),            'Windows': ('win','d')},
        }
        keys = SHORTCUTS.get(action, {}).get(OS)
        log.info(f"SHORTCUT: action={action} keys={keys} OS={OS}")
        if keys:
            pyautogui.hotkey(*keys)
            log.info("SHORTCUT DONE")
        else:
            log.warning(f"Unknown shortcut: {action}")
    
    # ── MEDIA ───────────────────────────────────────────────────────────────────
    elif t == 'media':
        action = cmd.get('action', '')
        value = cmd.get('value', 0.5)
        log.info(f"MEDIA: action={action} value={value}")
        handle_media(action, value)
    
    # ── AUDIO MIC ───────────────────────────────────────────────────────────────
    elif t == 'audio_mic_chunk':
        import base64, sounddevice as sd, numpy as np
        try:
            raw = base64.b64decode(cmd['data'])
            sample_rate = cmd.get('sampleRate', 44100)
            audio = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
            sd.play(audio, samplerate=sample_rate, blocking=False)
            log.debug(f"MIC CHUNK played: {len(raw)} bytes @ {sample_rate}Hz")
        except Exception as e:
            log.error(f"MIC PLAY ERROR: {e}")
    
    # ── SPEAKER ─────────────────────────────────────────────────────────────────
    elif t == 'speaker_start':
        log.info("SPEAKER START requested")
        threading.Thread(target=stream_speaker_to_phone, args=(conn,), daemon=True).start()
    
    elif t == 'speaker_stop':
        log.info("SPEAKER STOP requested")
        global speaker_streaming
        speaker_streaming = False
    
    else:
        log.warning(f"UNKNOWN COMMAND TYPE: {t}")


# ── MEDIA IMPLEMENTATION ─────────────────────────────────────────────────────

def handle_media(action, value=0.5):
    if OS == 'Darwin':
        media_keycodes = {
            'play_pause': 16,
            'next': 17,
            'previous': 18,
            'mute': 7,
        }
        if action in media_keycodes:
            keycode = media_keycodes[action]
            script = f'''
tell application "System Events"
    key code {keycode}
end tell
'''
            result = subprocess.run(['osascript', '-e', script], 
                                   capture_output=True, text=True)
            log.info(f"MEDIA osascript result: returncode={result.returncode} stderr={result.stderr}")
        elif action == 'volume':
            vol = int(value * 100)
            script = f'set volume output volume {vol}'
            subprocess.run(['osascript', '-e', script])
            log.info(f"VOLUME set to {vol}")
        elif action in ('shuffle', 'repeat'):
            import pyautogui
            if action == 'shuffle':
                pyautogui.hotkey('command', 'shift', 's')
            else:
                pyautogui.hotkey('command', 'shift', 'r')
    
    elif OS == 'Windows':
        import ctypes
        VK_MAP = {
            'play_pause': 0xB3, 'next': 0xB0,
            'previous': 0xB1,   'mute': 0xAD,
        }
        vk = VK_MAP.get(action)
        if vk:
            ctypes.windll.user32.keybd_event(vk, 0, 0, 0)
            ctypes.windll.user32.keybd_event(vk, 0, 2, 0)


# ── UDP SERVER (mouse moves) ──────────────────────────────────────────────────

def start_udp_server():
    import pyautogui
    pyautogui.FAILSAFE = False
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0', 35900))
    log.info("UDP server listening on port 35900")
    while True:
        try:
            data, addr = s.recvfrom(1024)
            if len(data) == 9 and data[0] == 0x01:
                dx, dy = struct.unpack('<ff', data[1:9])
                log.debug(f"UDP MOUSE MOVE: dx={dx:.2f} dy={dy:.2f}")
                pyautogui.moveRel(dx, dy, _pause=False)
        except Exception as e:
            log.error(f"UDP ERROR: {e}")


# ── TCP SERVER ────────────────────────────────────────────────────────────────

def start_tcp_server():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        s.bind(('0.0.0.0', 35901))
    except OSError as e:
        log.error(f"CANNOT BIND TCP PORT 35901: {e}")
        log.error("Is another instance of the agent already running?")
        log.error("Run: lsof -i :35901 | kill -9 <PID>")
        return
    s.listen(5)
    log.info("TCP server listening on port 35901")
    while True:
        try:
            conn, addr = s.accept()
            conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            t = threading.Thread(target=handle_client, args=(conn, addr), daemon=True)
            t.start()
        except Exception as e:
            log.error(f"TCP ACCEPT ERROR: {e}")


# ── MAIN ─────────────────────────────────────────────────────────────────────

speaker_streaming = False

def stream_speaker_to_phone(conn):
    global speaker_streaming
    import sounddevice as sd, numpy as np, base64
    speaker_streaming = True
    SAMPLE_RATE = 44100
    CHUNK = int(SAMPLE_RATE * 0.02)  # 20ms
    log.info("SPEAKER STREAM: starting")
    try:
        with sd.InputStream(samplerate=SAMPLE_RATE, channels=2,
                            dtype='int16', blocksize=CHUNK) as stream:
            while speaker_streaming:
                chunk, _ = stream.read(CHUNK)
                encoded = base64.b64encode(chunk.tobytes()).decode()
                packet = json.dumps({
                    'type': 'audio_speaker_chunk',
                    'data': encoded,
                    'sampleRate': SAMPLE_RATE,
                    'channels': 2,
                }) + '\n'
                conn.sendall(packet.encode())
    except Exception as e:
        log.error(f"SPEAKER STREAM ERROR: {e}")
        log.error("On macOS: install BlackHole → brew install blackhole-2ch")
        log.error("Then set System Output to BlackHole in Sound Settings")


if __name__ == '__main__':
    log.info(f"TouchifyMouse Agent starting on {OS}")
    log.info(f"Debug log: /tmp/touchifymouse_debug.log")
    
    # Check pyautogui is installed
    try:
        import pyautogui
        pyautogui.FAILSAFE = False
        log.info("pyautogui OK")
    except ImportError:
        log.error("pyautogui NOT INSTALLED: pip install pyautogui")
        sys.exit(1)
    
    # Start servers in threads
    udp_thread = threading.Thread(target=start_udp_server, daemon=True)
    udp_thread.start()
    
    tcp_thread = threading.Thread(target=start_tcp_server, daemon=True)
    tcp_thread.start()
    
    # mDNS advertisement (keep existing zeroconf code here)
    # ... your existing zeroconf/bonsoir advertisement code ...
    
    log.info("All servers running. Waiting for connections...")
    log.info("To monitor: tail -f /tmp/touchifymouse_debug.log")
    
    # Keep main thread alive
    try:
        while True:
            import time
            time.sleep(1)
    except KeyboardInterrupt:
        log.info("Agent stopped.")
```

---

## FIX 2 — FLUTTER: trackpad_socket_service.dart

This file is the most critical. Replace it entirely:

```dart
// lib/features/trackpad/services/trackpad_socket_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class TrackpadSocketService {
  // ── SINGLETON ──────────────────────────────────────────────────────────────
  static final TrackpadSocketService instance = TrackpadSocketService._internal();
  TrackpadSocketService._internal();

  // ── STATE ─────────────────────────────────────────────────────────────────
  Socket? _tcpSocket;
  RawDatagramSocket? _udpSocket;
  String? _deviceIP;
  int _tcpPort = 35901;
  int _udpPort = 35900;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  StreamSubscription? _tcpSubscription;

  // Status stream so UI can react
  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _statusController.stream;
  bool get isConnected => _isConnected;

  // ── CONNECT ────────────────────────────────────────────────────────────────
  Future<bool> connect(String ip, {int tcpPort = 35901, int udpPort = 35900}) async {
    if (_isConnecting) return false;
    _isConnecting = true;
    _deviceIP = ip;
    _tcpPort = tcpPort;
    _udpPort = udpPort;

    print('[Socket] Connecting to $ip:$tcpPort');

    try {
      // Close existing connection
      await _disconnect();

      // Open TCP connection with 5s timeout
      _tcpSocket = await Socket.connect(
        ip, tcpPort,
        timeout: const Duration(seconds: 5),
      );
      
      // CRITICAL: disable Nagle algorithm for low latency
      _tcpSocket!.setOption(SocketOption.tcpNoDelay, true);
      
      print('[Socket] TCP connected to $ip:$tcpPort');

      // Open UDP socket
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, 0,
      );
      print('[Socket] UDP socket bound');

      // Listen for incoming data (for speaker audio)
      _tcpSubscription = _tcpSocket!
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              print('[Socket] RECEIVED: ${line.substring(0, line.length.clamp(0, 100))}');
              _handleIncoming(line);
            },
            onError: (e) {
              print('[Socket] TCP ERROR: $e');
              _handleDisconnect();
            },
            onDone: () {
              print('[Socket] TCP CLOSED by remote');
              _handleDisconnect();
            },
          );

      _isConnected = true;
      _isConnecting = false;
      _statusController.add(true);
      print('[Socket] FULLY CONNECTED ✓');
      return true;

    } catch (e) {
      print('[Socket] CONNECT FAILED: $e');
      _isConnecting = false;
      _isConnected = false;
      _statusController.add(false);
      return false;
    }
  }

  // ── SEND HELPERS ──────────────────────────────────────────────────────────

  // ALWAYS use this to send TCP — never call socket.write directly
  void _sendTCP(String json) {
    if (_tcpSocket == null || !_isConnected) {
      print('[Socket] SEND BLOCKED — not connected. Command: $json');
      return;
    }
    try {
      final data = '$json\n';  // CRITICAL: must end with \n
      print('[Socket] SENDING: $data');
      _tcpSocket!.write(data);
    } catch (e) {
      print('[Socket] SEND ERROR: $e');
      _handleDisconnect();
    }
  }

  // ── PUBLIC API ────────────────────────────────────────────────────────────

  void sendMouseMove(double dx, double dy) {
    if (_udpSocket == null || _deviceIP == null || !_isConnected) return;
    try {
      final bytes = ByteData(9);
      bytes.setUint8(0, 0x01);
      bytes.setFloat32(1, dx, Endian.little);
      bytes.setFloat32(5, dy, Endian.little);
      _udpSocket!.send(
        bytes.buffer.asUint8List(),
        InternetAddress(_deviceIP!),
        _udpPort,
      );
    } catch (e) {
      print('[Socket] UDP SEND ERROR: $e');
    }
  }

  void sendClick(String button) {
    print('[Socket] sendClick($button)');
    _sendTCP(jsonEncode({'type': 'click', 'button': button}));
  }

  void sendMouseDown(String button) {
    _sendTCP(jsonEncode({'type': 'mousedown', 'button': button}));
  }

  void sendMouseUp(String button) {
    _sendTCP(jsonEncode({'type': 'mouseup', 'button': button}));
  }

  void sendScroll(double dx, double dy) {
    print('[Socket] sendScroll(dx=$dx, dy=$dy)');
    _sendTCP(jsonEncode({'type': 'scroll', 'deltaX': dx, 'deltaY': dy}));
  }

  void sendKey(String code, List<String> modifiers) {
    print('[Socket] sendKey($code, $modifiers)');
    _sendTCP(jsonEncode({'type': 'key', 'code': code, 'modifiers': modifiers}));
  }

  void sendShortcut(String action) {
    print('[Socket] sendShortcut($action)');
    _sendTCP(jsonEncode({'type': 'shortcut', 'action': action}));
  }

  void sendMedia(String action, {double? value}) {
    print('[Socket] sendMedia($action, $value)');
    final cmd = <String, dynamic>{'type': 'media', 'action': action};
    if (value != null) cmd['value'] = value;
    _sendTCP(jsonEncode(cmd));
  }

  void sendRaw(String json) {
    _sendTCP(json);
  }

  // ── DISCONNECT / RECONNECT ────────────────────────────────────────────────

  void _handleDisconnect() {
    if (!_isConnected) return;
    _isConnected = false;
    _statusController.add(false);
    print('[Socket] Disconnected. Scheduling reconnect in 2s...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (_deviceIP != null && !_isConnected) {
        print('[Socket] Attempting reconnect to $_deviceIP');
        connect(_deviceIP!, tcpPort: _tcpPort, udpPort: _udpPort);
      }
    });
  }

  Future<void> _disconnect() async {
    _reconnectTimer?.cancel();
    await _tcpSubscription?.cancel();
    _tcpSocket?.destroy();
    _udpSocket?.close();
    _tcpSocket = null;
    _udpSocket = null;
    _isConnected = false;
  }

  Future<void> disconnect() async {
    _deviceIP = null;
    await _disconnect();
    _statusController.add(false);
  }

  void _handleIncoming(String line) {
    // Handle audio speaker chunks coming back from desktop
    try {
      final data = jsonDecode(line) as Map<String, dynamic>;
      if (data['type'] == 'audio_speaker_chunk') {
        // Route to speaker service
        // SpeakerStreamService.instance.handleChunk(data);
      }
    } catch (_) {}
  }
}
```

---

## FIX 3 — FLUTTER: trackpad_surface.dart

The gesture logic must be rewritten completely. Copy this exactly:

```dart
// lib/features/trackpad/widgets/trackpad_surface.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/trackpad_socket_service.dart';
import '../../../core/providers/settings_provider.dart';

class TrackpadSurface extends ConsumerStatefulWidget {
  const TrackpadSurface({super.key});

  @override
  ConsumerState<TrackpadSurface> createState() => _TrackpadSurfaceState();
}

class _TrackpadSurfaceState extends ConsumerState<TrackpadSurface> {
  // ── POINTER TRACKING ──────────────────────────────────────────────────────
  final Map<int, Offset> _activePointers = {};
  
  // For tap detection (left click)
  Offset? _singleFingerStartPos;
  bool _singleFingerMoved = false;
  static const double _tapThreshold = 8.0; // pixels before drag
  
  // For two-finger tap detection (right click)
  bool _twoFingerScrolled = false;
  double _twoFingerScrollTotal = 0;
  static const double _twoFingerTapThreshold = 12.0;
  
  // For scroll
  final Map<int, Offset> _lastPointerPos = {};

  // ── GETTERS ───────────────────────────────────────────────────────────────
  TrackpadSocketService get _socket => TrackpadSocketService.instance;
  
  double get _speed {
    try {
      return ref.read(settingsProvider).pointerSpeed;
    } catch (_) {
      return 1.0;
    }
  }
  
  bool get _invertScroll {
    try {
      return ref.read(settingsProvider).invertScroll;
    } catch (_) {
      return false;
    }
  }
  
  bool get _haptic {
    try {
      return ref.read(settingsProvider).hapticFeedback;
    } catch (_) {
      return true;
    }
  }

  // ── POINTER DOWN ─────────────────────────────────────────────────────────
  void _onPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    _lastPointerPos[event.pointer] = event.localPosition;
    
    if (_activePointers.length == 1) {
      _singleFingerStartPos = event.localPosition;
      _singleFingerMoved = false;
    }
    
    if (_activePointers.length == 2) {
      _twoFingerScrolled = false;
      _twoFingerScrollTotal = 0;
    }
  }

  // ── POINTER MOVE ─────────────────────────────────────────────────────────
  void _onPointerMove(PointerMoveEvent event) {
    final prev = _lastPointerPos[event.pointer];
    _lastPointerPos[event.pointer] = event.localPosition;
    _activePointers[event.pointer] = event.localPosition;
    
    if (prev == null) return;
    final delta = event.localPosition - prev;

    if (_activePointers.length == 1) {
      // ── MOUSE MOVE ──────────────────────────────────────────────────────
      if (delta.distance > 0.5) {
        _singleFingerMoved = true;
        final dx = _applyAcceleration(delta.dx) * _speed;
        final dy = _applyAcceleration(delta.dy) * _speed;
        _socket.sendMouseMove(dx, dy);
      }
    }
    
    if (_activePointers.length == 2) {
      // ── SCROLL ──────────────────────────────────────────────────────────
      // Average the movement of both fingers
      final avgDy = delta.dy;
      final avgDx = delta.dx;
      
      _twoFingerScrollTotal += avgDy.abs();
      
      if (_twoFingerScrollTotal > 3) {
        _twoFingerScrolled = true;
      }
      
      if (_twoFingerScrolled) {
        final invertMult = _invertScroll ? -1.0 : 1.0;
        // Send scroll — use real delta values, not multiplied
        // Python agent multiplies by 3 on its side
        _socket.sendScroll(
          avgDx * invertMult,
          avgDy * invertMult,
        );
      }
    }
  }

  // ── POINTER UP ────────────────────────────────────────────────────────────
  void _onPointerUp(PointerUpEvent event) {
    final wasOneFingerActive = _activePointers.length == 1;
    final wasTwoFingerActive = _activePointers.length == 2;
    
    _activePointers.remove(event.pointer);
    _lastPointerPos.remove(event.pointer);

    if (wasOneFingerActive && _activePointers.isEmpty) {
      // ── LEFT CLICK (single finger tap) ──────────────────────────────────
      if (!_singleFingerMoved) {
        print('[Gesture] LEFT CLICK');
        if (_haptic) HapticFeedback.lightImpact();
        _socket.sendClick('left');
      }
    }
    
    if (wasTwoFingerActive && _activePointers.length == 1) {
      // ── RIGHT CLICK (two-finger tap, no scroll) ──────────────────────────
      if (!_twoFingerScrolled && _twoFingerScrollTotal < _twoFingerTapThreshold) {
        print('[Gesture] RIGHT CLICK');
        if (_haptic) HapticFeedback.mediumImpact();
        _socket.sendClick('right');
      }
    }
  }

  // ── ACCELERATION CURVE ────────────────────────────────────────────────────
  double _applyAcceleration(double v) {
    final abs = v.abs();
    if (abs < 2) return v * 0.8;
    if (abs < 8) return v * 1.2;
    return v * 1.8;
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown:   _onPointerDown,
      onPointerMove:   _onPointerMove,
      onPointerUp:     _onPointerUp,
      onPointerCancel: (e) {
        _activePointers.remove(e.pointer);
        _lastPointerPos.remove(e.pointer);
      },
      child: Container(
        // The visual trackpad area
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        // IMPORTANT: must absorb all pointer events
        child: const SizedBox.expand(),
      ),
    );
  }
}
```

---

## FIX 4 — FLUTTER: click_buttons_bar.dart

The left/right buttons were not wired. Fix them:

```dart
// lib/features/trackpad/widgets/click_buttons_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/trackpad_socket_service.dart';
import '../../../core/theme/app_colors.dart';

class ClickButtonsBar extends StatelessWidget {
  const ClickButtonsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          // LEFT CLICK
          Expanded(
            flex: 5,
            child: _ClickButton(
              label: 'Left',
              icon: Icons.mouse_outlined,
              onTap: () {
                print('[Button] LEFT CLICK tapped');
                HapticFeedback.lightImpact();
                TrackpadSocketService.instance.sendClick('left');
              },
              onLongPressStart: (_) {
                print('[Button] LEFT MOUSEDOWN');
                HapticFeedback.heavyImpact();
                TrackpadSocketService.instance.sendMouseDown('left');
              },
              onLongPressEnd: (_) {
                print('[Button] LEFT MOUSEUP');
                TrackpadSocketService.instance.sendMouseUp('left');
              },
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          
          // SCROLL (middle)
          SizedBox(
            width: 48,
            child: _ClickButton(
              label: '',
              icon: Icons.unfold_more,
              onTap: () {
                HapticFeedback.selectionClick();
                TrackpadSocketService.instance.sendClick('middle');
              },
              borderRadius: BorderRadius.zero,
            ),
          ),
          
          // RIGHT CLICK
          Expanded(
            flex: 5,
            child: _ClickButton(
              label: 'Right',
              icon: Icons.mouse_outlined,
              onTap: () {
                print('[Button] RIGHT CLICK tapped');
                HapticFeedback.lightImpact();
                TrackpadSocketService.instance.sendClick('right');
              },
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressEndCallback? onLongPressEnd;
  final BorderRadius borderRadius;

  const _ClickButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.borderRadius,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label.isNotEmpty) ...[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text3,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## FIX 5 — FLUTTER: trackpad_screen.dart

Ensure socket connects properly when screen loads:

```dart
// In TrackpadScreen — initState or didChangeDependencies

@override
void initState() {
  super.initState();
  
  // Connect socket AFTER first frame so providers are ready
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _connectSocket();
  });
  
  // Keep screen awake
  try { WakelockPlus.enable(); } catch (_) {}
}

Future<void> _connectSocket() async {
  final device = ref.read(connectionProvider).connectedDevice;
  if (device == null) {
    print('[TrackpadScreen] No device in provider — going back to connect');
    context.go('/connect');
    return;
  }
  
  print('[TrackpadScreen] Connecting socket to ${device.ip}:${device.port}');
  final success = await TrackpadSocketService.instance.connect(
    device.ip,
    tcpPort: device.port,
    udpPort: 35900,
  );
  
  if (!success) {
    print('[TrackpadScreen] Socket connection FAILED');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to desktop agent')),
      );
    }
  } else {
    print('[TrackpadScreen] Socket connected ✓');
  }
}

@override
void dispose() {
  try { WakelockPlus.disable(); } catch (_) {}
  // Do NOT disconnect socket on dispose — reconnect should handle it
  super.dispose();
}
```

---

## FIX 6 — FLUTTER: keyboard_panel.dart shortcut chips

```dart
// In the shortcut chips section of keyboard_panel.dart

// App Switcher chip
onTap: () => TrackpadSocketService.instance.sendShortcut('app_switcher'),

// Screenshot chip
onTap: () => TrackpadSocketService.instance.sendShortcut('screenshot'),

// Lock screen chip  
onTap: () => TrackpadSocketService.instance.sendShortcut('lock_screen'),

// Paste chip
onTap: () => TrackpadSocketService.instance.sendShortcut('paste'),

// Copy chip
onTap: () => TrackpadSocketService.instance.sendShortcut('copy'),

// Mission Control chip
onTap: () => TrackpadSocketService.instance.sendShortcut('mission_control'),

// Shutdown option — send special command
onTap: () => TrackpadSocketService.instance.sendRaw(
  jsonEncode({'type': 'shortcut', 'action': 'shutdown_dialog'})
),
```

---

## FIX 7 — FLUTTER: media_remote_panel.dart

```dart
// Ensure all media buttons are wired:

// Play/Pause
onTap: () {
  print('[Media] play_pause tapped');
  TrackpadSocketService.instance.sendMedia('play_pause');
},

// Next
onTap: () => TrackpadSocketService.instance.sendMedia('next'),

// Previous
onTap: () => TrackpadSocketService.instance.sendMedia('previous'),

// Mute
onTap: () => TrackpadSocketService.instance.sendMedia('mute'),

// Volume slider
onChanged: (double val) {
  TrackpadSocketService.instance.sendMedia('volume', value: val);
},
```

---

## FIX 8 — PYTHON: requirements.txt

Make sure ALL dependencies are installed:

```
pyautogui
zeroconf
pillow
qrcode[pil]
pystray
sounddevice
numpy
pyinstaller
```

Install: `pip install -r requirements.txt`

On macOS also run:
```bash
# Allow pyautogui to control the screen:
# System Settings → Privacy & Security → Accessibility → add Terminal

# Test pyautogui works:
python3 -c "import pyautogui; pyautogui.FAILSAFE=False; pyautogui.click()"
# If this crashes → Accessibility permission not granted
```

---

## TESTING PROCEDURE (do this in exact order)

### Step 1 — Test Python agent in isolation
```bash
cd touchifymouse_desktop/__agent_rebuild
python3 touchifymouse_agent.py

# In a second terminal, send a test command manually:
python3 -c "
import socket, json
s = socket.socket()
s.connect(('localhost', 35901))
s.send(json.dumps({'type':'click','button':'left'}).encode() + b'\n')
s.close()
print('Sent test click')
"
# Watch the agent terminal — you should see:
# [Socket] COMMAND: type=click
# [Socket] CLICK: left
# [Socket] CLICK DONE: left
# And your Mac cursor should click
```

### Step 2 — Monitor the debug log
```bash
# In a new terminal while agent is running:
tail -f /tmp/touchifymouse_debug.log
```

### Step 3 — Test from Flutter app
1. Start agent: `python3 touchifymouse_agent.py`
2. Run Flutter app: `flutter run`
3. Connect to the agent (QR or IP)
4. On trackpad screen — tap with one finger
5. Watch BOTH:
   - Flutter console: should print `[Socket] SENDING: {"type":"click"...}`
   - Agent log: should print `COMMAND: type=click`

If Flutter prints "SENDING" but agent doesn't receive → firewall issue
If Flutter doesn't print "SENDING" → socket not connected
If agent receives but click doesn't happen → pyautogui/Accessibility issue

---

## COMMON ERRORS & EXACT FIXES

### "Nothing happens when I tap"
→ Check Flutter console for `[Socket] SEND BLOCKED — not connected`
→ Means `_connectSocket()` was never called or failed
→ Add print statements in `_connectSocket()` to trace

### "Agent receives command but click doesn't work"
→ Accessibility permission not granted on Mac
→ Run: System Settings → Privacy → Accessibility → add Terminal (or the app)
→ Test: `python3 -c "import pyautogui; pyautogui.click()"`

### "Scroll worked before, now doesn't"
→ The `int(-dy)` truncation bug — tiny float becomes 0
→ Fixed in agent: `int(-raw_dy * scroll_sensitivity)` where sensitivity = 3
→ Make sure this multiplication exists in Python agent

### "Port 35901 already in use"
→ Old agent still running
→ Run: `lsof -i :35901` then `kill -9 <PID>`

### "Connected but immediate disconnect"
→ TCP socket closes on first error
→ Check agent log for the specific error
→ Usually a JSON parse error — check Flutter is sending `\n` at end of each command

### "APK works but desktop crashes"
→ Missing null check on socket before sending
→ Every send method must check `if (_tcpSocket == null || !_isConnected) return;`

---

## WHAT NOT TO CHANGE

- UDP port 35900 and TCP port 35901 — do not change these
- JSON structure of commands — do not change field names
- The 9-byte binary UDP packet format — do not change
- mDNS service name `_touchifymouse._tcp` — do not change

---

## FILE LOCATIONS REFERENCE

```
touchify_mouse/
├── lib/features/trackpad/services/trackpad_socket_service.dart  ← FIX 2
├── lib/features/trackpad/widgets/trackpad_surface.dart          ← FIX 3
├── lib/features/trackpad/widgets/click_buttons_bar.dart         ← FIX 4
├── lib/features/trackpad/screens/trackpad_screen.dart           ← FIX 5
├── lib/features/keyboard/widgets/keyboard_panel.dart            ← FIX 6
├── lib/features/media/widgets/media_remote_panel.dart           ← FIX 7
└── touchifymouse_desktop/
    └── __agent_rebuild/
        ├── touchifymouse_agent.py                               ← FIX 1
        └── requirements.txt                                     ← FIX 8
```

Apply fixes in order: Fix 1 → Fix 8. 
Run test procedure after each fix group.
Check /tmp/touchifymouse_debug.log for all agent-side issues.
Check Flutter console (flutter run) for all mobile-side issues.
