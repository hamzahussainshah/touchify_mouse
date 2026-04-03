import socket
import struct
import threading
import json
import subprocess
import platform
import traceback
import sys
import logging

# ── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.DEBUG,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('/tmp/touchifymouse_debug.log'),
    ]
)
log = logging.getLogger('TouchifyMouse')

OS = platform.system()  # 'Darwin' or 'Windows'


# ── Execute Command ──────────────────────────────────────────────────────────
# FIX: This was previously dead code after a finally block.
# Now it's a proper top-level function called by handle_client().

def execute_command(cmd, conn):
    """Process a single JSON command from the phone."""
    t = cmd.get('type', '')

    # ── MOUSE ────────────────────────────────────────────────────────────────
    if t == 'click':
        import pyautogui
        pyautogui.FAILSAFE = False
        btn = cmd.get('button', 'left')
        log.info(f'CLICK: {btn}')
        if btn == 'left':
            pyautogui.click()
        elif btn == 'right':
            pyautogui.rightClick()
        elif btn == 'middle':
            pyautogui.middleClick()
        log.info(f'CLICK DONE: {btn}')

    elif t == 'mousedown':
        import pyautogui
        pyautogui.FAILSAFE = False
        btn = cmd.get('button', 'left')
        log.info(f'MOUSEDOWN: {btn}')
        pyautogui.mouseDown(button=btn)

    elif t == 'mouseup':
        import pyautogui
        pyautogui.FAILSAFE = False
        btn = cmd.get('button', 'left')
        log.info(f'MOUSEUP: {btn}')
        pyautogui.mouseUp(button=btn)

    # ── SCROLL ───────────────────────────────────────────────────────────────
    elif t == 'scroll':             
        import pyautogui
        pyautogui.FAILSAFE = False
        raw_dy = float(cmd.get('deltaY', 0))
        raw_dx = float(cmd.get('deltaX', 0))

        # Flutter sends small pixel deltas like 0.3, 1.2, etc.
        # Must multiply BEFORE int() conversion or result is always 0
        SCROLL_SENSITIVITY = 3   # increase to 4 or 5 if scroll feels too slow

        dy = int(-raw_dy * SCROLL_SENSITIVITY)
        dx = int(raw_dx * SCROLL_SENSITIVITY)

        log.info(f'SCROLL: raw=({raw_dy:.2f},{raw_dx:.2f}) → int=({dy},{dx})')

        if dy != 0:
            pyautogui.scroll(dy)
        if dx != 0:
            pyautogui.hscroll(dx)

    # ── KEYBOARD ─────────────────────────────────────────────────────────────
    elif t == 'key':
        import pyautogui
        pyautogui.FAILSAFE = False
        code = cmd.get('code', '')
        modifiers = cmd.get('modifiers', [])

        KEY_MAP = {
            'return': 'enter', 'backspace': 'backspace', 'space': 'space',
            'up': 'up', 'down': 'down', 'left': 'left', 'right': 'right',
            'cmd': 'command', 'ctrl': 'ctrl', 'alt': 'alt', 'shift': 'shift',
            'tab': 'tab', 'esc': 'escape', 'delete': 'delete',
            'insert': 'insert', 'home': 'home', 'end': 'end',
            'pageup': 'pageup', 'pagedown': 'pagedown',
            'f1': 'f1', 'f2': 'f2', 'f3': 'f3', 'f4': 'f4',
            'f5': 'f5', 'f6': 'f6', 'f7': 'f7', 'f8': 'f8',
            'f9': 'f9', 'f10': 'f10', 'f11': 'f11', 'f12': 'f12',
            'fn': None,   # fn key alone does nothing
        }

        mapped = KEY_MAP.get(code.lower(), code.lower())
        if mapped is None:
            log.info(f'KEY: skipping unmappable key: {code}')
            return

        mapped_mods = [KEY_MAP.get(m.lower(), m.lower()) for m in modifiers
                       if KEY_MAP.get(m.lower(), m.lower()) is not None]

        log.info(f"KEY: '{code}'→'{mapped}' mods={modifiers}→{mapped_mods}")
        try:
            if mapped_mods:
                pyautogui.hotkey(*mapped_mods, mapped)
            else:
                pyautogui.press(mapped)
            log.info(f'KEY DONE: {mapped}')
        except Exception as e:
            log.error(f"KEY FAILED: {e} — key='{mapped}' mods={mapped_mods}")

    # ── SHORTCUTS ────────────────────────────────────────────────────────────
    elif t == 'shortcut':
        import pyautogui
        pyautogui.FAILSAFE = False
        action = cmd.get('action', '')
        SHORTCUTS = {
            'app_switcher':    {'Darwin': ('command', 'tab'),          'Windows': ('alt', 'tab')},
            'screenshot':      {'Darwin': ('command', 'shift', '3'),  'Windows': ('win', 'printscreen')},
            'lock_screen':     {'Darwin': ('command', 'control', 'q'), 'Windows': ('win', 'l')},
            'paste':           {'Darwin': ('command', 'v'),           'Windows': ('ctrl', 'v')},
            'copy':            {'Darwin': ('command', 'c'),           'Windows': ('ctrl', 'c')},
            'undo':            {'Darwin': ('command', 'z'),           'Windows': ('ctrl', 'z')},
            'mission_control': {'Darwin': ('control', 'up'),          'Windows': ('win', 'tab')},
            'show_desktop':    {'Darwin': ('command', 'f3'),          'Windows': ('win', 'd')},
        }
        keys = SHORTCUTS.get(action, {}).get(OS)
        log.info(f'SHORTCUT: {action} → {keys}')
        if keys:
            pyautogui.hotkey(*keys)
            log.info('SHORTCUT DONE')
        else:
            log.warning(f'Unknown shortcut: {action}')

    # ── MEDIA ────────────────────────────────────────────────────────────────
    elif t == 'media':
        action = cmd.get('action', '')
        value = cmd.get('value', 0.5)
        handle_media(action, value)

    # ── MIC AUDIO ────────────────────────────────────────────────────────────
    elif t == 'audio_mic_chunk':
        try:
            import base64, sounddevice as sd, numpy as np
            raw = base64.b64decode(cmd['data'])
            sr = int(cmd.get('sampleRate', 44100))
            audio = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
            sd.play(audio, samplerate=sr, blocking=False)
            log.debug(f'MIC: played {len(raw)} bytes @ {sr}Hz')
        except ImportError:
            log.error('sounddevice not installed: pip install sounddevice numpy')
        except Exception as e:
            log.error(f'MIC PLAY ERROR: {e}')

    # ── SPEAKER ──────────────────────────────────────────────────────────────
    elif t == 'speaker_start':
        log.info('SPEAKER START')
        threading.Thread(target=stream_speaker_to_phone, args=(conn,), daemon=True).start()

    elif t == 'speaker_stop':
        global speaker_streaming
        speaker_streaming = False
        log.info('SPEAKER STOP')

    else:
        log.warning(f'UNKNOWN COMMAND TYPE: {t}')


# ── TCP handler ───────────────────────────────────────────────────────────────

def handle_client(conn, addr):
    log.info(f'Phone connected from {addr}')

    # FIX: Enable TCP keepalive so idle connection isn't dropped by router
    conn.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
    if hasattr(socket, 'TCP_KEEPIDLE'):   # Linux / macOS
        conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPIDLE, 10)
        conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPINTVL, 5)
        conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPCNT, 3)

    buffer = ''
    try:
        while True:
            chunk = conn.recv(4096)
            if not chunk:
                log.info(f'Phone disconnected: {addr}')
                break
            raw = chunk.decode('utf-8', errors='replace')
            log.debug(f'RAW ({len(chunk)}B): {repr(raw[:120])}')
            buffer += raw
            while '\n' in buffer:
                line, buffer = buffer.split('\n', 1)
                line = line.strip()
                if not line:
                    continue
                log.info(f'CMD: {line[:100]}')
                try:
                    cmd = json.loads(line)
                    execute_command(cmd, conn)
                except json.JSONDecodeError as e:
                    log.error(f'JSON ERROR: {e} | line={repr(line[:60])}')
                except Exception:
                    log.error(traceback.format_exc())
    except Exception:
        log.error(traceback.format_exc())
    finally:
        conn.close()
        log.info(f'Connection closed: {addr}')


# ── Media ─────────────────────────────────────────────────────────────────────

def handle_media(action, value=0.5):
    log.info(f'MEDIA: {action} value={value}')

    if OS == 'Darwin':
        NX_KEYCODES = {
            'play_pause': 16,
            'next':       17,
            'previous':   18,
            'mute':        7,
        }
        if action in NX_KEYCODES:
            keycode = NX_KEYCODES[action]
            script = f'''
tell application "System Events"
    key code {keycode}
end tell
'''
            result = subprocess.run(['osascript', '-e', script],
                                    capture_output=True, text=True)
            if result.returncode != 0:
                log.error(f'MEDIA osascript error: {result.stderr}')
                try:
                    import pyautogui
                    fallback = {'play_pause': 'playpause', 'next': 'nexttrack',
                                'previous': 'prevtrack',  'mute': 'volumemute'}
                    pyautogui.press(fallback.get(action, ''))
                except Exception as e:
                    log.error(f'MEDIA fallback error: {e}')
            else:
                log.info(f'MEDIA {action} sent via osascript')

        elif action == 'volume':
            vol = max(0, min(100, int(value * 100)))
            subprocess.run(['osascript', '-e', f'set volume output volume {vol}'])
            log.info(f'VOLUME set to {vol}%')

        elif action == 'shuffle':
            import pyautogui
            pyautogui.hotkey('command', 'shift', 's')

        elif action == 'repeat':
            import pyautogui
            pyautogui.hotkey('command', 'shift', 'r')

    elif OS == 'Windows':
        import ctypes
        VK = {'play_pause': 0xB3, 'next': 0xB0, 'previous': 0xB1, 'mute': 0xAD}
        vk = VK.get(action)
        if vk:
            ctypes.windll.user32.keybd_event(vk, 0, 0, 0)
            ctypes.windll.user32.keybd_event(vk, 0, 2, 0)
        elif action == 'volume':
            times = int(abs(value - 0.5) * 20)
            vk_vol = 0xAF if value > 0.5 else 0xAE
            for _ in range(times):
                ctypes.windll.user32.keybd_event(vk_vol, 0, 0, 0)
                ctypes.windll.user32.keybd_event(vk_vol, 0, 2, 0)


# ── UDP (mouse moves) ─────────────────────────────────────────────────────────

def start_udp_server():
    import pyautogui
    pyautogui.FAILSAFE = False
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0', 35900))
    log.info('UDP server listening on port 35900')
    while True:
        try:
            data, _ = s.recvfrom(1024)
            if len(data) == 9 and data[0] == 0x01:
                dx, dy = struct.unpack('<ff', data[1:9])
                pyautogui.moveRel(dx, dy, _pause=False)
        except Exception as e:
            log.error(f'UDP ERROR: {e}')


# ── TCP (commands) ────────────────────────────────────────────────────────────

def start_tcp_server():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    # FIX: Also disable Nagle on server socket
    s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    try:
        s.bind(('0.0.0.0', 35901))
    except OSError as e:
        log.error(f'CANNOT BIND TCP 35901: {e}')
        log.error('Kill existing: lsof -i :35901 | kill -9 <PID>')
        return
    s.listen(5)
    log.info('TCP server listening on port 35901')
    while True:
        try:
            conn, addr = s.accept()
            conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()
        except Exception as e:
            log.error(f'TCP ACCEPT ERROR: {e}')

# ── Speaker streaming ─────────────────────────────────────────────────────────

speaker_streaming = False

def stream_speaker_to_phone(conn):
    global speaker_streaming
    speaker_streaming = True
    try:
        import sounddevice as sd, numpy as np, base64
        SAMPLE_RATE = 44100
        CHUNK = int(SAMPLE_RATE * 0.02)
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
    except ImportError:
        log.error('sounddevice not installed: pip install sounddevice numpy')
    except Exception as e:
        log.error(f'SPEAKER STREAM ERROR: {e}')


# ── mDNS advertisement ────────────────────────────────────────────────────────

def register_mdns():
    try:
        from zeroconf import ServiceInfo, Zeroconf
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(('8.8.8.8', 80))
            ip = s.getsockname()[0]
        finally:
            s.close()
        hostname = socket.gethostname()
        info = ServiceInfo(
            '_touchifymouse._tcp.local.',
            f'{hostname}._touchifymouse._tcp.local.',
            addresses=[socket.inet_aton(ip)],
            port=35901,
            properties={'os': OS.lower(), 'name': hostname},
            server=f'{hostname}.local.',
        )
        Zeroconf().register_service(info)
        log.info(f'[mDNS] Registered {hostname} at {ip}')
    except Exception as e:
        log.error(f'mDNS Error: {e}')


# ── Main ──────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    log.info(f'TouchifyMouse Agent starting on {OS}')
    log.info('Debug log: /tmp/touchifymouse_debug.log')

    try:
        import pyautogui
        pyautogui.FAILSAFE = False
        log.info('pyautogui OK')
    except ImportError:
        log.error('pyautogui NOT INSTALLED: pip install pyautogui')
        sys.exit(1)

    threading.Thread(target=start_udp_server, daemon=True).start()
    threading.Thread(target=start_tcp_server, daemon=True).start()
    register_mdns()

    log.info('All servers running. Waiting for connections...')
    log.info('Monitor: tail -f /tmp/touchifymouse_debug.log')

    try:
        import time
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        log.info('Agent stopped.')
