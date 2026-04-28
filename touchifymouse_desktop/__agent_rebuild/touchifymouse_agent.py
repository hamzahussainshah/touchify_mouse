import os
import socket
import struct
import threading
import json
import subprocess
import platform
import traceback
import sys
import logging
import queue

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


# ── Virtual audio device discovery ────────────────────────────────────────────
#
# Both the Mic and Speaker features require a virtual audio cable installed on
# the desktop.  Without one, macOS/Windows provide no way to route audio between
# applications without a kernel driver.
#
#   macOS   → BlackHole 2ch (free): brew install blackhole-2ch
#             https://existential.audio/blackhole/
#   Windows → VB-Audio Virtual Cable (free): https://vb-audio.com/Cable/
#
# HOW IT WORKS
#   Microphone (Mobile → Apps):
#     1. Mobile mic audio arrives over TCP.
#     2. Agent writes it to BlackHole OUTPUT (CABLE Input on Windows).
#     3. BlackHole "loops" it: anything written to its output appears on its input.
#     4. User selects "BlackHole 2ch" (or "CABLE Output") as mic in Zoom/Teams/etc.
#
#   Speaker (Mac audio → Mobile):
#     1. User sets "BlackHole 2ch" (or "CABLE Input") as system audio output.
#     2. Agent reads from BlackHole INPUT (CABLE Output on Windows).
#     3. Agent encodes and streams each chunk to the mobile over TCP.
#     4. Mobile plays the audio in real time.

def _find_virtual_audio_device(direction='output'):
    """
    Find a virtual audio loopback device.

    direction='output' → device we WRITE mobile mic audio to
                         (BlackHole / CABLE Input)
    direction='input'  → device we READ system audio from
                         (BlackHole / CABLE Output)

    Returns (device_index, device_name) or (None, None).
    """
    try:
        import sounddevice as sd
        devices = sd.query_devices()

        if OS == 'Darwin':
            # BlackHole and Soundflower both loop output→input on the same device
            output_terms = ['blackhole', 'soundflower', 'loopback']
            input_terms  = ['blackhole', 'soundflower', 'loopback']
        else:
            output_terms = ['cable input', 'vb-audio virtual cable', 'voicemeeter input']
            input_terms  = ['cable output', 'vb-audio virtual cable', 'voicemeeter output']

        terms = output_terms if direction == 'output' else input_terms

        for i, dev in enumerate(devices):
            name_lower = dev['name'].lower()
            for term in terms:
                if term in name_lower:
                    ch_key = 'max_output_channels' if direction == 'output' else 'max_input_channels'
                    if dev[ch_key] > 0:
                        log.info(f'[Audio] Virtual {direction} device #{i}: {dev["name"]}')
                        return i, dev['name']
    except Exception as e:
        log.error(f'[Audio] Device search error: {e}')

    log.warning(f'[Audio] No virtual {direction} device found')
    return None, None


# ── Default audio device switching (macOS) ───────────────────────────────────
#
# When the user enables the mic feature the agent must automatically set the
# Mac's default AUDIO INPUT to BlackHole so every app (Zoom, Teams, FaceTime…)
# that uses "System Default Microphone" will receive the mobile audio.
#
# When the user enables the speaker feature the agent must automatically set
# the Mac's default AUDIO OUTPUT to BlackHole so all system audio is captured
# and streamed to the mobile.  Both are restored on stop / disconnect.

_prev_default_input_name  = None   # restored when mic_stop received
_prev_default_output_name = None   # restored when speaker_stop received
_mic_setup_required_sent  = False  # rate-limit: only send once per session


def _ca_property_address(selector, scope=0x676C6F62, element=0):
    """Return a packed AudioObjectPropertyAddress bytes buffer."""
    import struct
    return struct.pack('III', selector, scope, element)


def _coreaudio_get_default_device_name(is_input=False):
    """Return the current macOS default audio device name via CoreAudio."""
    try:
        import ctypes, struct
        ca = ctypes.CDLL(
            '/System/Library/Frameworks/CoreAudio.framework/CoreAudio')

        kSystemObject      = ctypes.c_uint32(1)
        kPropDefaultInput  = 0x64496E20  # 'dIn '
        kPropDefaultOutput = 0x644F7574  # 'dOut'
        kPropName          = 0x6E616D65  # 'name'
        kScopeGlobal       = 0x676C6F62  # 'glob'

        # --- get default device id ---
        sel   = kPropDefaultInput if is_input else kPropDefaultOutput
        addr  = ctypes.create_string_buffer(struct.pack('III', sel, kScopeGlobal, 0))
        dev_id = ctypes.c_uint32(0)
        sz     = ctypes.c_uint32(4)
        if ca.AudioObjectGetPropertyData(kSystemObject, addr, 0, None,
                                         ctypes.byref(sz),
                                         ctypes.byref(dev_id)) != 0:
            return None

        # --- get device name ---
        addr2  = ctypes.create_string_buffer(
            struct.pack('III', kPropName, kScopeGlobal, 0))
        buf    = ctypes.create_string_buffer(512)
        buf_sz = ctypes.c_uint32(512)
        if ca.AudioObjectGetPropertyData(dev_id, addr2, 0, None,
                                         ctypes.byref(buf_sz), buf) == 0:
            return buf.value.decode('utf-8', errors='replace')
    except Exception as e:
        log.debug(f'[Audio] coreaudio_get_default error: {e}')
    return None


def _coreaudio_set_default_device(device_name, is_input=False):
    """Set the macOS default audio input or output device by name."""
    try:
        import ctypes, struct
        ca = ctypes.CDLL(
            '/System/Library/Frameworks/CoreAudio.framework/CoreAudio')

        kSystemObject   = ctypes.c_uint32(1)
        kPropDevices    = 0x64657623  # 'dev#'
        kPropName       = 0x6E616D65  # 'name'
        kPropDefInput   = 0x64496E20  # 'dIn '
        kPropDefOutput  = 0x644F7574  # 'dOut'
        kScopeGlobal    = 0x676C6F62  # 'glob'

        def make_addr(sel):
            return ctypes.create_string_buffer(
                struct.pack('III', sel, kScopeGlobal, 0))

        # --- enumerate device IDs ---
        a  = make_addr(kPropDevices)
        sz = ctypes.c_uint32(0)
        if ca.AudioObjectGetPropertyDataSize(kSystemObject, a, 0, None,
                                             ctypes.byref(sz)) != 0:
            return False
        n      = sz.value // 4
        ids    = (ctypes.c_uint32 * n)()
        if ca.AudioObjectGetPropertyData(kSystemObject, a, 0, None,
                                         ctypes.byref(sz), ids) != 0:
            return False

        # --- find device by name ---
        target = None
        for raw_id in ids:
            dev_id  = ctypes.c_uint32(raw_id)
            a_name  = make_addr(kPropName)
            buf_sz  = ctypes.c_uint32(512)
            buf     = ctypes.create_string_buffer(512)
            if ca.AudioObjectGetPropertyData(dev_id, a_name, 0, None,
                                             ctypes.byref(buf_sz), buf) == 0:
                name = buf.value.decode('utf-8', errors='replace')
                if device_name.lower() in name.lower():
                    target = raw_id
                    log.debug(f'[Audio] CoreAudio matched "{name}" id={raw_id}')
                    break

        if target is None:
            log.warning(f'[Audio] CoreAudio: "{device_name}" not found')
            return False

        # --- set as default ---
        sel    = kPropDefInput if is_input else kPropDefOutput
        a_set  = make_addr(sel)
        val    = ctypes.c_uint32(target)
        status = ca.AudioObjectSetPropertyData(kSystemObject, a_set, 0, None,
                                               ctypes.c_uint32(4),
                                               ctypes.byref(val))
        if status == 0:
            dtype = 'input' if is_input else 'output'
            log.info(f'[Audio] Default {dtype} → "{device_name}" (CoreAudio)')
            return True
        log.warning(f'[Audio] CoreAudio set property status={status}')
    except Exception as e:
        log.error(f'[Audio] CoreAudio set default device error: {e}')
    return False


def _get_default_audio_device_name(is_input=False):
    """Get the current OS-level default audio device name."""
    if OS != 'Darwin':
        return None
    # 1. SwitchAudioSource (brew install switchaudio-osx) — fastest
    try:
        import subprocess
        dtype = 'input' if is_input else 'output'
        r = subprocess.run(['SwitchAudioSource', '-c', '-t', dtype],
                           capture_output=True, timeout=3)
        if r.returncode == 0:
            name = r.stdout.decode().strip()
            if name:
                return name
    except FileNotFoundError:
        pass
    except Exception:
        pass
    # 2. CoreAudio ctypes (no dependencies)
    name = _coreaudio_get_default_device_name(is_input)
    if name:
        return name
    # 3. osascript fallback (always available on macOS)
    try:
        import subprocess
        prop = 'input' if is_input else 'output'
        script = (
            f'tell application "System Events" to get name of '
            f'(first audio {prop} device whose default is true)'
        )
        r = subprocess.run(['osascript', '-e', script],
                           capture_output=True, timeout=5)
        if r.returncode == 0:
            return r.stdout.decode().strip()
    except Exception:
        pass
    return None


def _set_default_audio_device(device_name, is_input=False):
    """
    Set the OS-level default audio input or output device.
    Tries three methods in order:
      1. SwitchAudioSource CLI (brew install switchaudio-osx)
      2. CoreAudio ctypes (no dependencies, uses private C API)
      3. osascript System Events (always available, slightly slower)
    Returns True on success.
    """
    if OS != 'Darwin':
        return False
    dtype = 'input' if is_input else 'output'

    # ── 1. SwitchAudioSource ─────────────────────────────────────────────────
    try:
        import subprocess
        r = subprocess.run(
            ['SwitchAudioSource', '-s', device_name, '-t', dtype],
            capture_output=True, timeout=3)
        if r.returncode == 0:
            log.info(f'[Audio] Default {dtype} → "{device_name}" (SwitchAudioSource)')
            return True
    except FileNotFoundError:
        pass
    except Exception as e:
        log.debug(f'[Audio] SwitchAudioSource error: {e}')

    # ── 2. CoreAudio ctypes ──────────────────────────────────────────────────
    if _coreaudio_set_default_device(device_name, is_input):
        return True

    # ── 3. osascript System Events (most compatible, zero deps) ─────────────
    try:
        import subprocess
        script = (
            f'tell application "System Events" to set default '
            f'{dtype} device to audio {dtype} device "{device_name}"'
        )
        r = subprocess.run(['osascript', '-e', script],
                           capture_output=True, timeout=5)
        if r.returncode == 0:
            log.info(f'[Audio] Default {dtype} → "{device_name}" (osascript)')
            return True
        log.warning(f'[Audio] osascript set default failed: {r.stderr.decode().strip()}')
    except Exception as e:
        log.error(f'[Audio] osascript set default error: {e}')
    return False


def _build_audio_devices_info():
    """Return a JSON-serialisable dict describing virtual device availability."""
    try:
        import sounddevice as sd
        all_names = [d['name'] for d in sd.query_devices()]
    except Exception:
        all_names = []

    out_idx, out_name = _find_virtual_audio_device('output')
    in_idx,  in_name  = _find_virtual_audio_device('input')

    if OS == 'Darwin':
        virtual_product = 'BlackHole 2ch'
        install_cmd     = 'brew install blackhole-2ch'
        install_url     = 'https://existential.audio/blackhole/'
        mic_app_step    = 'In Zoom/Teams/etc. → Settings → Audio → Microphone → select "BlackHole 2ch"'
        spk_sys_step    = 'System Settings → Sound → Output → select "BlackHole 2ch"\n(To also hear locally: create a Multi-Output Device in Audio MIDI Setup)'
    else:
        virtual_product = 'VB-Audio Virtual Cable'
        install_cmd     = 'Download from vb-audio.com/Cable/'
        install_url     = 'https://vb-audio.com/Cable/'
        mic_app_step    = 'In Zoom/Teams/etc. → Settings → Audio → Microphone → select "CABLE Output"'
        spk_sys_step    = 'Windows Sound Settings → Playback → set "CABLE Input" as default'

    return {
        'virtualProduct':    virtual_product,
        'installCmd':        install_cmd,
        'installUrl':        install_url,
        'micDeviceReady':    out_idx is not None,
        'micDeviceName':     out_name or '',
        'speakerDeviceReady': in_idx is not None,
        'speakerDeviceName': in_name or '',
        'micAppStep':        mic_app_step,
        'spkSysStep':        spk_sys_step,
        'allDevices':        all_names[:30],
    }


# ── Mic audio: mobile mic → virtual device → apps ────────────────────────────
#
# We use a single persistent OutputStream so chunks play in one continuous
# timeline (no overlap, no gaps).  The stream targets the virtual OUTPUT device
# so that any app selecting that device as its microphone input receives the
# mobile audio.

_mic_queue       = queue.Queue(maxsize=40)
_mic_out_stream  = None
_mic_out_sr      = 0
_mic_out_dev_idx = None
_mic_stream_lock = threading.Lock()
_mic_partial        = None
_mic_partial_offset = 0
_mic_active         = False   # set by mic_start / mic_stop commands


def _mic_output_callback(outdata, frames, _time_info, _status):
    """
    OutputStream callback — drain the queue into outdata with carry-over.

    outdata shape is (frames, n_channels).  Mobile sends mono PCM; we duplicate
    it to every channel so stereo devices (BlackHole 2ch) receive valid audio.
    """
    import numpy as np
    global _mic_partial, _mic_partial_offset

    # Build a 1-D mono buffer first, then broadcast to all channels below
    mono = np.zeros(frames, dtype='float32')
    pos  = 0

    if _mic_partial is not None:
        available = len(_mic_partial) - _mic_partial_offset
        n = min(available, frames)
        mono[:n] = _mic_partial[_mic_partial_offset:_mic_partial_offset + n]
        pos += n
        _mic_partial_offset += n
        if _mic_partial_offset >= len(_mic_partial):
            _mic_partial        = None
            _mic_partial_offset = 0

    while pos < frames:
        try:
            chunk = _mic_queue.get_nowait()
            n = min(len(chunk), frames - pos)
            mono[pos:pos + n] = chunk[:n]
            pos += n
            if n < len(chunk):
                _mic_partial        = chunk[n:]
                _mic_partial_offset = 0
                break
        except queue.Empty:
            break

    # Duplicate mono to every channel (handles 1ch, 2ch, 16ch devices)
    for ch in range(outdata.shape[1]):
        outdata[:, ch] = mono


# ── Virtual driver auto-installer ─────────────────────────────────────────────
#
# PRODUCT APPROACH (same as Krisp, Loopback, AudioRelay):
#   On first use, silently download the BlackHole 2ch PKG from GitHub and
#   install it via a single native macOS "allow changes" password dialog.
#   The user sees ONE prompt — no manual download, no Terminal commands.
#
# BlackHole release: https://github.com/ExistentialAudio/BlackHole/releases
# Using a pinned known-good release so the URL stays stable.

_BLACKHOLE_PKG_URL  = 'https://existential.audio/downloads/BlackHole2ch-0.6.1.pkg'
_BLACKHOLE_PKG_NAME = 'BlackHole2ch-0.6.1.pkg'

# Prevent concurrent install attempts
_install_lock      = threading.Lock()
_install_attempted = False   # only try once per agent run


def _download_file(url, dest_path):
    """Download url → dest_path with a 60 s timeout.  Returns True on success."""
    try:
        import urllib.request
        log.info(f'[Audio] Downloading {url} ...')
        urllib.request.urlretrieve(url, dest_path)
        log.info(f'[Audio] Downloaded → {dest_path}')
        return True
    except Exception as e:
        log.error(f'[Audio] Download failed: {e}')
        return False


def _install_pkg_with_admin(pkg_path):
    """
    Install a macOS .pkg with a native admin-password dialog.

    Uses osascript 'do shell script … with administrator privileges' which
    pops the standard macOS "TouchifyMouse wants to make changes" sheet —
    identical to what Loopback, Krisp, and every other audio app does.
    Returns True if installer exited 0.
    """
    import subprocess
    # The space-escaped path is passed directly into the shell snippet
    safe = pkg_path.replace('"', '\\"')
    script = (
        f'do shell script '
        f'"installer -pkg \\"{safe}\\" -target /" '
        f'with administrator privileges'
    )
    log.info(f'[Audio] Requesting admin to install {pkg_path}')
    r = subprocess.run(
        ['osascript', '-e', script],
        capture_output=True, timeout=120,
    )
    if r.returncode == 0:
        log.info('[Audio] PKG installed successfully')
        return True
    log.error(f'[Audio] installer returned {r.returncode}: {r.stderr.decode().strip()}')
    return False


def _restart_coreaudiod():
    """Kill coreaudiod so launchd restarts it and picks up the new HAL plugin."""
    import subprocess, time
    log.info('[Audio] Restarting coreaudiod to load new driver …')
    subprocess.run(
        ['launchctl', 'kickstart', '-k', 'system/com.apple.audio.coreaudiod'],
        capture_output=True, timeout=10,
    )
    time.sleep(2)


def _try_install_virtual_device(conn=None):
    """
    Install Virtual Audio Driver (BlackHole for macOS, VBCABLE for Windows)
    using the locally bundled installers from PyInstaller's drivers/ payload.
    Returns True when the virtual device is ready.
    """
    global _install_attempted

    with _install_lock:
        if _install_attempted:
            return False           # already tried this session
        _install_attempted = True

        def _notify(msg):
            if conn:
                try:
                    conn.sendall((
                        json.dumps({'type': 'audio_install_progress', 'message': msg})
                        + '\n'
                    ).encode())
                except Exception:
                    pass
            log.info(f'[Audio] {msg}')

        # --- 1. Check if device is already visible ---
        dev_idx, _ = _find_virtual_audio_device('output')
        if dev_idx is not None:
            return True

        _notify('Installing audio driver for TouchifyMouse (one-time setup)…')

        # --- 2. Determine path to bundled drivers ---
        import os, sys, tempfile
        base_path = getattr(sys, '_MEIPASS', os.path.dirname(os.path.abspath(__file__)))
        drivers_dir = os.path.join(base_path, 'drivers')

        if OS == 'Darwin':
            pkg_path = os.path.join(drivers_dir, _BLACKHOLE_PKG_NAME)
            if not os.path.exists(pkg_path):
                _notify(f'Installer missing at {pkg_path}')
                return False

            _notify('Please approve the installation dialog to set up macOS audio routing.')
            ok = _install_pkg_with_admin(pkg_path)
            if not ok:
                _notify('Installation cancelled or failed. Audio routing unavailable.')
                return False

            _notify('Audio driver installed — activating…')
            _restart_coreaudiod()

        elif OS == 'Windows':
            zip_path = os.path.join(drivers_dir, 'VBCABLE_Driver_Pack43.zip')
            if not os.path.exists(zip_path):
                _notify(f'Installer missing at {zip_path}')
                return False

            import zipfile, ctypes
            extract_dir = os.path.join(tempfile.gettempdir(), "VBMacAgentBundle")
            try:
                with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                    zip_ref.extractall(extract_dir)
            except Exception as e:
                _notify(f'ZIP extraction failed: {e}')
                return False
                
            executable = os.path.join(extract_dir, "VBCABLE_Setup_x64.exe")
            _notify('Please approve the Windows UAC dialog to install audio drivers.')
            log.info(f'[Audio] Requesting UAC admin to install {executable}')
            
            # ShellExecuteW: 1 = SW_SHOWNORMAL. Runs installer as Admin.
            ret = ctypes.windll.shell32.ShellExecuteW(None, "runas", executable, "-i -h", None, 1)
            
            # Check for error (ret <= 32 means error in ShellExecute)
            if int(ret) <= 32:
                _notify('Installation cancelled or failed. Audio routing unavailable.')
                return False
                
            # Windows typically requires a short wait for new devices to register
            import time
            time.sleep(2)
            _notify('Windows driver installed.')

        else:
            return False

        # --- 3. Verify ---
        dev_idx, dev_name = _find_virtual_audio_device('output')
        if dev_idx is not None:
            _notify(f'Audio driver ready: "{dev_name}"')
            return True

        _notify('Driver installed but not yet visible. Please restart the agent.')
        return False


def _ensure_mic_stream(sr, conn=None):
    """
    Start or restart the mic output stream, routing to the virtual device.
    Uses the device's actual output channel count (handles both 2ch and 16ch).
    conn — if provided, install-progress messages are forwarded to the phone.
    """
    global _mic_out_stream, _mic_out_sr, _mic_out_dev_idx
    with _mic_stream_lock:
        dev_idx, dev_name = _find_virtual_audio_device('output')

        # If no virtual device, attempt auto-install once
        if dev_idx is None:
            log.info('[Mic] No virtual device — attempting auto-install...')
            if _try_install_virtual_device(conn=conn):
                dev_idx, dev_name = _find_virtual_audio_device('output')

        # Restart if sample rate or device changed
        same = (_mic_out_stream is not None and _mic_out_stream.active
                and _mic_out_sr == sr and _mic_out_dev_idx == dev_idx)
        if same:
            return dev_idx is not None

        if _mic_out_stream is not None:
            try:
                _mic_out_stream.stop()
                _mic_out_stream.close()
            except Exception:
                pass

        import sounddevice as sd

        if dev_idx is None:
            log.warning('[Mic] No virtual device found — mic audio will NOT be routed to apps.')
            log.warning('[Mic] Install BlackHole (macOS): brew install blackhole-2ch')
            log.warning('[Mic] Install VB-Audio Cable (Windows): vb-audio.com/Cable')
            _mic_out_stream  = None
            _mic_out_sr      = 0
            _mic_out_dev_idx = None
            return False

        # Query actual channel count — BlackHole 2ch = 2, BlackHole 16ch = 16
        dev_info   = sd.query_devices(dev_idx)
        n_channels = max(1, int(dev_info['max_output_channels']))
        log.info(f'[Mic] Device "{dev_name}" has {n_channels} output channel(s)')

        _mic_out_dev_idx = dev_idx
        _mic_out_sr      = sr
        try:
            _mic_out_stream  = sd.OutputStream(
                samplerate=sr,
                channels=n_channels,   # ← use device's real channel count
                dtype='float32',
                device=dev_idx,
                blocksize=512,
                callback=_mic_output_callback,
            )
            _mic_out_stream.start()
        except Exception as e:
            log.error(f'[Mic] OutputStream open failed: {e}')
            _mic_out_stream  = None
            _mic_out_sr      = 0
            _mic_out_dev_idx = None
            return False

        log.info(f'[Mic] Stream started @ {sr} Hz → "{dev_name}" ({n_channels}ch)')
        return True


def _mic_enqueue(audio, sr, conn=None):
    """Queue a float32 PCM chunk; drop oldest on overflow."""
    ready = _ensure_mic_stream(sr, conn=conn)
    if not ready:
        return False   # caller will notify mobile to show setup UI
    try:
        _mic_queue.put_nowait(audio)
    except queue.Full:
        try:
            _mic_queue.get_nowait()
        except queue.Empty:
            pass
        _mic_queue.put_nowait(audio)
    return True


# ── Execute Command ──────────────────────────────────────────────────────────
# FIX: This was previously dead code after a finally block.
# Now it's a proper top-level function called by handle_client().

def execute_command(cmd, conn):
    """Process a single JSON command from the phone."""
    global speaker_streaming
    global _mic_active, _mic_setup_required_sent
    global _prev_default_input_name, _prev_default_output_name
    global _mic_out_stream
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

    # ── MIC START ─────────────────────────────────────────────────────────────
    # Mobile sends this before it begins streaming audio_mic_chunk packets.
    # We find the virtual device, save the current default input, switch to it,
    # and open the OutputStream so chunks can be routed immediately.
    elif t == 'mic_start':
        if _mic_active:
            log.warning('[Mic] Already active — ignoring duplicate mic_start')
        else:
            # Run setup in a thread so it doesn't block the command loop
            # (install can take 30+ seconds on first run)
            def _do_mic_start():
                global _mic_active, _mic_setup_required_sent, _prev_default_input_name
                sr = int(cmd.get('sampleRate', 44100))

                # This handles: find device → auto-install if missing → open stream
                ok = _ensure_mic_stream(sr, conn=conn)

                if not ok:
                    log.error('[Mic] Could not open stream (no virtual device)')
                    try:
                        conn.sendall((json.dumps({
                            'type': 'audio_setup_required',
                            'for':  'mic',
                            'info': _build_audio_devices_info(),
                        }) + '\n').encode())
                    except Exception:
                        pass
                    return

                # Get device name after install
                dev_idx, dev_name = _find_virtual_audio_device('output')
                dev_name = dev_name or 'virtual device'

                # Save and switch Mac's default INPUT → virtual device
                _prev_default_input_name = _get_default_audio_device_name(is_input=True)
                log.info(f'[Mic] Saving current default input: "{_prev_default_input_name}"')
                switched = _set_default_audio_device(dev_name, is_input=True)
                log.info(f'[Mic] MAC INPUT → "{dev_name}" switched={switched}')

                _mic_active            = True
                _mic_setup_required_sent = False
                log.info('[Mic] Ready — phone mic now routes to all Mac apps via system default mic')
                try:
                    conn.sendall((json.dumps({
                        'type': 'mic_status',
                        'active': True,
                        'device': dev_name,
                    }) + '\n').encode())
                except Exception:
                    pass

            threading.Thread(target=_do_mic_start, daemon=True).start()

    # ── MIC STOP ──────────────────────────────────────────────────────────────
    elif t == 'mic_stop':
        _mic_active = False
        # Restore Mac's previous default input
        if _prev_default_input_name:
            restored = _set_default_audio_device(_prev_default_input_name, is_input=True)
            log.info(f'[Mic] Restored default input → "{_prev_default_input_name}" ok={restored}')
            _prev_default_input_name = None
        # Stop the output stream
        with _mic_stream_lock:
            if _mic_out_stream is not None:
                try:
                    _mic_out_stream.stop()
                    _mic_out_stream.close()
                except Exception:
                    pass
                _mic_out_stream = None
        log.info('[Mic] Stopped')

    # ── MIC AUDIO ────────────────────────────────────────────────────────────
    elif t == 'audio_mic_chunk':
        if not _mic_active:
            return  # ignore chunks until mic_start received
        try:
            import base64, numpy as np
            raw   = base64.b64decode(cmd['data'])
            sr    = int(cmd.get('sampleRate', 44100))
            audio = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
            routed = _mic_enqueue(audio, sr)
            if not routed and not _mic_setup_required_sent:
                _mic_setup_required_sent = True
                pkt = json.dumps({
                    'type': 'audio_setup_required',
                    'for':  'mic',
                    'info': _build_audio_devices_info(),
                }) + '\n'
                try:
                    conn.sendall(pkt.encode())
                except Exception:
                    pass
            log.debug(f'MIC: {"routed" if routed else "no-device"} {len(raw)}B @ {sr}Hz')
        except ImportError:
            log.error('sounddevice/numpy not installed')
        except Exception as e:
            log.error(f'MIC CHUNK ERROR: {e}')

    # ── SPEAKER ──────────────────────────────────────────────────────────────
    elif t == 'speaker_start':
        if speaker_streaming:
            log.warning('SPEAKER already streaming — ignoring duplicate start')
        else:
            log.info('SPEAKER START')
            threading.Thread(target=stream_speaker_to_phone, args=(conn,), daemon=True).start()

    elif t == 'speaker_stop':
        speaker_streaming = False
        # Restore Mac's previous default output
        if _prev_default_output_name:
            restored = _set_default_audio_device(_prev_default_output_name, is_input=False)
            log.info(f'[Speaker] Restored default output → "{_prev_default_output_name}" ok={restored}')
            _prev_default_output_name = None
        log.info('SPEAKER STOP')

    # ── DEVICE QUERY ─────────────────────────────────────────────────────────
    elif t == 'audio_query_devices':
        info = _build_audio_devices_info()
        pkt  = json.dumps({'type': 'audio_devices_info', 'info': info}) + '\n'
        try:
            conn.sendall(pkt.encode())
            log.info(f'[Audio] Sent devices info: mic_ready={info["micDeviceReady"]} spk_ready={info["speakerDeviceReady"]}')
        except Exception as e:
            log.error(f'[Audio] Could not send devices info: {e}')

    else:
        log.warning(f'UNKNOWN COMMAND TYPE: {t}')


# ── TCP handler ───────────────────────────────────────────────────────────────

def handle_client(conn, addr):
    global _mic_active, speaker_streaming
    global _prev_default_input_name, _prev_default_output_name
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
            chunk = conn.recv(65536)  # 64 KB — audio chunks can be > 4 KB
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
        # Restore audio devices if the phone disconnected mid-session
        if _mic_active:
            _mic_active = False
            if _prev_default_input_name:
                _set_default_audio_device(_prev_default_input_name, is_input=True)
                log.info(f'[Mic] Disconnect: restored input → "{_prev_default_input_name}"')
        if speaker_streaming:
            speaker_streaming = False
            if _prev_default_output_name:
                _set_default_audio_device(_prev_default_output_name, is_input=False)
                log.info(f'[Speaker] Disconnect: restored output → "{_prev_default_output_name}"')


# ── Media ─────────────────────────────────────────────────────────────────────

# Windows: track last-known volume so we can compute correct delta
_win_volume_state = 0.5


def _macos_send_media_key(action):
    """
    Post a global NX media key (play/pause, next, previous, mute) on macOS.

    Injects at kCGHIDEventTap — the lowest event-tap level — so the event
    reaches Music, Spotify, Safari/YouTube, etc. (kCGSessionEventTap is
    higher in the chain and often filtered out, which is why the old
    implementation silently dropped events.)

    Returns True only if the event was actually posted.
    """
    NX_KEY_TYPES = {'play_pause': 16, 'next': 17, 'previous': 18, 'mute': 7}
    key_type = NX_KEY_TYPES.get(action)
    if key_type is None:
        return False
    try:
        from AppKit import NSEvent
        from Quartz import CGEventPost, kCGHIDEventTap
        NSSystemDefined = 14
        NX_SUBTYPE_AUX_CONTROL_BUTTONS = 8

        for is_down in (True, False):
            # data1: high 16 bits = NX key type, next 8 bits = 0xa on key-down /
            # 0xb on key-up. Modifier-flags field must also flip between
            # down (0xa00) and up (0xb00) — using the same flag for both is a
            # common cause of "event fires but app ignores it".
            data1 = (key_type << 16) | ((0xa if is_down else 0xb) << 8)
            flags = 0xa00 if is_down else 0xb00
            ev = NSEvent.otherEventWithType_location_modifierFlags_timestamp_windowNumber_context_subtype_data1_data2_(
                NSSystemDefined,
                (0, 0),
                flags,
                0,
                0,
                None,
                NX_SUBTYPE_AUX_CONTROL_BUTTONS,
                data1,
                -1,
            )
            CGEventPost(kCGHIDEventTap, ev.CGEvent())
        log.info(f'MEDIA {action} posted via HID tap (nx={key_type})')
        return True
    except Exception as e:
        log.error(f'NSEvent media key failed for {action}: {e}')
        return False


def _macos_frontmost_media_app():
    """Best-effort: return the name of a running media app we can talk to via
    AppleScript. Checked in priority order."""
    try:
        r = subprocess.run(
            ['osascript', '-e',
             'tell application "System Events" to get name of '
             '(processes whose background only is false)'],
            capture_output=True, text=True, timeout=2,
        )
        running = {n.strip() for n in (r.stdout or '').split(',')}
        for app in ('Spotify', 'Music', 'iTunes', 'VOX', 'QuickTime Player'):
            if app in running:
                return app
    except Exception:
        pass
    return None


def _macos_applescript_media(action):
    """Last-resort fallback: drive a known media app directly via AppleScript.
    Only used when the HID injection was blocked (e.g. accessibility perm
    missing). Silent if no supported app is running."""
    app = _macos_frontmost_media_app()
    if not app:
        log.warning(f'MEDIA {action}: HID injection blocked and no media app running')
        return False
    script_map = {
        'play_pause': f'tell application "{app}" to playpause',
        'next':       f'tell application "{app}" to next track',
        'previous':   f'tell application "{app}" to previous track',
    }
    script = script_map.get(action)
    if not script:
        return False
    try:
        subprocess.run(['osascript', '-e', script], capture_output=True, timeout=2)
        log.info(f'MEDIA {action} → AppleScript fallback on {app}')
        return True
    except Exception as e:
        log.error(f'AppleScript fallback failed: {e}')
        return False


def handle_media(action, value=0.5):
    log.info(f'MEDIA: {action} value={value}')

    if OS == 'Darwin':
        if action in ('play_pause', 'next', 'previous', 'mute'):
            if _macos_send_media_key(action):
                return
            # HID injection blocked (usually = missing Accessibility perm).
            # Try driving a running media app by name.
            if action != 'mute':
                _macos_applescript_media(action)
            return

        if action == 'volume':
            vol = max(0, min(100, int(float(value) * 100)))
            subprocess.run(
                ['osascript', '-e', f'set volume output volume {vol}'],
                capture_output=True,
            )
            log.info(f'VOLUME set to {vol}%')
            return

        if action in ('shuffle', 'repeat'):
            # No universal macOS keybinding for shuffle/repeat. Target the
            # running media app explicitly instead of mashing Cmd+Shift+S
            # (which is Spotify's "save track", not shuffle).
            app = _macos_frontmost_media_app()
            if app == 'Spotify':
                script = (
                    'tell application "Spotify" to set shuffling to not shuffling'
                    if action == 'shuffle'
                    else 'tell application "Spotify" to set repeating to not repeating'
                )
                subprocess.run(['osascript', '-e', script], capture_output=True)
                log.info(f'MEDIA {action} → Spotify')
            else:
                log.info(f'MEDIA {action}: no-op (supported only in Spotify)')
            return

    elif OS == 'Windows':
        import ctypes
        VK = {'play_pause': 0xB3, 'next': 0xB0, 'previous': 0xB1, 'mute': 0xAD}
        vk = VK.get(action)
        if vk:
            ctypes.windll.user32.keybd_event(vk, 0, 0, 0)
            ctypes.windll.user32.keybd_event(vk, 0, 2, 0)
        elif action == 'volume':
            global _win_volume_state
            vol_scalar = max(0.0, min(1.0, float(value)))
            delta = vol_scalar - _win_volume_state
            _win_volume_state = vol_scalar
            if abs(delta) < 0.005:
                return
            # Each VK_VOLUME_UP/DOWN press moves ~2% on most systems.
            # 50 steps covers the full 0-100% range.
            steps = max(1, round(abs(delta) * 50))
            vk_vol = 0xAF if delta > 0 else 0xAE  # VK_VOLUME_UP / VK_VOLUME_DOWN
            for _ in range(steps):
                ctypes.windll.user32.keybd_event(vk_vol, 0, 0, 0)
                ctypes.windll.user32.keybd_event(vk_vol, 0, 2, 0)
            log.info(f'VOLUME delta={delta:+.2f} → {steps} key presses')


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
    """
    Capture audio from the virtual INPUT device and stream to mobile.

    Auto-switches the Mac's default audio OUTPUT to the virtual device so that
    all system audio is routed through it and captured here.  On stop/disconnect
    the previous output device is restored.
    """
    global speaker_streaming, _prev_default_output_name
    speaker_streaming = True

    try:
        import sounddevice as sd, numpy as np, base64

        dev_idx, dev_name = _find_virtual_audio_device('input')

        # Auto-install driver if not present (same flow as mic)
        if dev_idx is None:
            log.info('[Speaker] No virtual device — attempting auto-install...')
            _try_install_virtual_device(conn=conn)
            dev_idx, dev_name = _find_virtual_audio_device('input')

        if dev_idx is None:
            info = _build_audio_devices_info()
            err_pkt = json.dumps({
                'type': 'audio_setup_required',
                'for':  'speaker',
                'info': info,
            }) + '\n'
            conn.sendall(err_pkt.encode())
            log.warning('[Speaker] No virtual input device — sent setup_required to mobile')
            speaker_streaming = False
            return

        # ── Auto-switch Mac default output → BlackHole ────────────────────────
        _prev_default_output_name = _get_default_audio_device_name(is_input=False)
        log.info(f'[Speaker] Saved current default output: "{_prev_default_output_name}"')

        switched = _set_default_audio_device(dev_name, is_input=False)
        if switched:
            log.info(f'[Speaker] Mac default OUTPUT → "{dev_name}" — all audio now goes to phone')
        else:
            log.warning('[Speaker] Could not auto-switch output; user may need to set manually')

        # Query device's actual channel count (BlackHole 2ch = 2, 16ch = 16)
        dev_info   = sd.query_devices(dev_idx)
        n_channels = max(1, min(2, int(dev_info['max_input_channels'])))
        log.info(f'[Speaker] Device "{dev_name}" → {n_channels} input channel(s)')
        log.info(f'[Speaker] Capturing system audio from: "{dev_name}"')

        SAMPLE_RATE = 44100
        CHANNELS    = n_channels
        CHUNK       = int(SAMPLE_RATE * 0.02)  # 20 ms per packet

        with sd.InputStream(
            samplerate=SAMPLE_RATE,
            channels=CHANNELS,
            dtype='int16',
            device=dev_idx,
            blocksize=CHUNK,
        ) as stream:
            while speaker_streaming:
                audio_chunk, _ = stream.read(CHUNK)
                encoded  = base64.b64encode(audio_chunk.tobytes()).decode()
                packet   = json.dumps({
                    'type':       'audio_speaker_chunk',
                    'data':       encoded,
                    'sampleRate': SAMPLE_RATE,
                    'channels':   CHANNELS,
                }) + '\n'
                conn.sendall(packet.encode())

    except ImportError:
        log.error('[Speaker] sounddevice not installed: pip install sounddevice numpy')
    except Exception as e:
        log.error(f'[Speaker] Stream error: {e}')
        try:
            err_pkt = json.dumps({'type': 'speaker_error', 'message': str(e)}) + '\n'
            conn.sendall(err_pkt.encode())
        except Exception:
            pass
    finally:
        speaker_streaming = False
        # Restore Mac's previous default output (if we changed it)
        if _prev_default_output_name:
            restored = _set_default_audio_device(_prev_default_output_name, is_input=False)
            log.info(f'[Speaker] Restored default output → "{_prev_default_output_name}" ok={restored}')
            _prev_default_output_name = None
        log.info('[Speaker] Stream ended')


# ── mDNS advertisement ────────────────────────────────────────────────────────

def _local_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        return s.getsockname()[0]
    finally:
        s.close()


def _qr_output_path() -> str:
    if OS == 'Windows':
        base = os.environ.get('TEMP') or os.environ.get('TMP') or 'C:\\Windows\\Temp'
    else:
        base = '/tmp'
    return os.path.join(base, 'touchifymouse_qr.png')


def generate_pairing_qr(ip: str) -> None:
    """Write a PNG QR at a well-known path so the desktop UI can display it.

    Payload matches lib/features/connect/widgets/qr_connect_sheet.dart parser.
    """
    try:
        import json as _json
        import qrcode
        payload = _json.dumps({
            'app': 'touchifymouse',
            'ip': ip,
            'tcp_port': 35901,
            'udp_port': 35900,
            'name': socket.gethostname(),
            'os': OS.lower(),
        }, separators=(',', ':'))
        img = qrcode.make(payload)
        path = _qr_output_path()
        img.save(path)
        log.info(f'[QR] Wrote pairing QR → {path}  (payload={payload})')
    except ImportError:
        log.error('[QR] qrcode not installed — pip install "qrcode[pil]"')
    except Exception as e:
        log.error(f'[QR] Failed to write QR: {e}')


def register_mdns():
    try:
        from zeroconf import ServiceInfo, Zeroconf
        ip = _local_ip()
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
        generate_pairing_qr(ip)
    except Exception as e:
        log.error(f'mDNS Error: {e}')
        # Still try to write a QR so the desktop UI isn't stuck waiting.
        try:
            generate_pairing_qr(_local_ip())
        except Exception:
            pass


# ── Main ──────────────────────────────────────────────────────────────────────

def _startup_audio_check():
    """Print a clear audio setup status at startup so the user knows what to do."""
    log.info('=' * 60)
    log.info('AUDIO DEVICE STATUS')
    log.info('=' * 60)
    try:
        import sounddevice as sd
        all_devs = sd.query_devices()
        log.info(f'Total audio devices found: {len(all_devs)}')
        for i, d in enumerate(all_devs):
            log.info(f'  [{i:2d}] {d["name"]}  in={d["max_input_channels"]} out={d["max_output_channels"]}')
    except ImportError:
        log.error('sounddevice NOT installed: pip install sounddevice numpy')
        return

    mic_idx,  mic_name  = _find_virtual_audio_device('output')
    spk_idx,  spk_name  = _find_virtual_audio_device('input')

    if mic_idx is not None:
        log.info(f'✓  Virtual MIC device ready: "{mic_name}" (idx={mic_idx})')
        log.info('   → Mobile mic will be routed to this device when mic toggle is ON')
        log.info('   → In Zoom/Meet: Settings → Audio → Microphone → select this device')
        log.info('     (OR the app auto-sets Mac default input, so "System Default" works)')
    else:
        log.warning('✗  No virtual mic device found!')
        log.warning('   macOS: brew install blackhole-2ch')
        log.warning('   Windows: download from vb-audio.com/Cable')

    if spk_idx is not None:
        log.info(f'✓  Virtual SPEAKER device ready: "{spk_name}" (idx={spk_idx})')
        log.info('   → Mac audio will be captured and sent to phone when speaker toggle is ON')
        log.info('   → The app auto-sets Mac default output when speaker toggle is ON')
    else:
        log.warning('✗  No virtual speaker device found!')

    log.info('=' * 60)


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

    _startup_audio_check()

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
