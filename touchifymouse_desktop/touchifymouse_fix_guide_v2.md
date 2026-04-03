# TouchifyMouse — Fix Guide v2
# For: Anti-Gravity / Gemini coding agent
# Priority: CRITICAL bugs + Flutter Desktop UI integration

---

## PROBLEM SUMMARY

1. AUTO-SCROLL BUG — phone scrolls by itself continuously up/down
2. TAPS NOT REGISTERING — single tap = no left click, double tap = nothing
3. SCROLL LATENCY + MOMENTUM — scrolls late, keeps going after finger lifts
4. KEYBOARD NOT WORKING — keys send nothing
5. MEDIA NOT WORKING — play/pause/volume do nothing
6. MIC/SPEAKER NOT WORKING — audio streaming broken
7. FLUTTER DESKTOP APP — needs to replace tray-only Python agent with full UI

---

# ═══════════════════════════════════════════════════════
# PART A — GESTURE BUGS (most critical — fix first)
# ═══════════════════════════════════════════════════════

## ROOT CAUSE OF AUTO-SCROLL

The auto-scroll happens because:
- `PointerMoveEvent` fires with tiny deltas even when finger is stationary
- Flutter reports events for ALL registered pointers, including ones already lifted
- The scroll never gets a "stop" signal

## ROOT CAUSE OF TAPS NOT WORKING

The tap logic fires onPointerUp but at that moment `_activePointers` has
already been modified, so the count check is wrong.

## ROOT CAUSE OF SCROLL MOMENTUM

Flutter's Listener widget does not have momentum/inertia handling.
Scroll events must STOP the instant finger lifts. No coasting.

---

## FIX A1 — COMPLETE REWRITE: trackpad_surface.dart

Replace the ENTIRE file with this. Do not merge — full replacement:

```dart
// lib/features/trackpad/widgets/trackpad_surface.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/trackpad_socket_service.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';

class TrackpadSurface extends ConsumerStatefulWidget {
  const TrackpadSurface({super.key});
  @override
  ConsumerState<TrackpadSurface> createState() => _TrackpadSurfaceState();
}

class _TrackpadSurfaceState extends ConsumerState<TrackpadSurface>
    with SingleTickerProviderStateMixin {

  // ─── Active pointer tracking ───────────────────────────────────────────────
  // Key = pointer ID, Value = current position
  final Map<int, Offset> _pointers = {};

  // Per-pointer: position at last move event (for delta calculation)
  final Map<int, Offset> _prevPos = {};

  // Per-pointer: position at finger-down (for tap threshold)
  final Map<int, Offset> _downPos = {};

  // ─── Scroll state ──────────────────────────────────────────────────────────
  bool _isScrolling = false;
  static const double _scrollStartThreshold = 4.0; // px before scroll begins
  static const double _tapMoveThreshold = 6.0;      // px before tap is cancelled

  // ─── Ripple animation ─────────────────────────────────────────────────────
  Offset? _ripplePos;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  // ─── Settings helpers ──────────────────────────────────────────────────────
  double get _speed {
    try { return ref.read(settingsProvider).pointerSpeed; } catch (_) { return 1.0; }
  }
  bool get _invertScroll {
    try { return ref.read(settingsProvider).invertScroll; } catch (_) { return false; }
  }
  bool get _haptic {
    try { return ref.read(settingsProvider).hapticFeedback; } catch (_) { return true; }
  }
  TrackpadSocketService get _s => TrackpadSocketService.instance;

  // ─── POINTER DOWN ──────────────────────────────────────────────────────────
  void _onDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    _prevPos[e.pointer]  = e.localPosition;
    _downPos[e.pointer]  = e.localPosition;

    // When second finger touches, mark scroll as not yet started
    // but don't reset if scroll already in progress (prevents jump)
    if (_pointers.length == 2) {
      _isScrolling = false;
    }
  }

  // ─── POINTER MOVE ──────────────────────────────────────────────────────────
  void _onMove(PointerMoveEvent e) {
    // Guard: ignore events for pointers we don't know about
    if (!_pointers.containsKey(e.pointer)) return;

    final prev = _prevPos[e.pointer]!;
    final curr = e.localPosition;
    final delta = curr - prev;

    // Update positions
    _pointers[e.pointer] = curr;
    _prevPos[e.pointer]  = curr;

    // Ignore micro-jitter (< 0.5px) — this is the auto-scroll fix
    if (delta.distance < 0.5) return;

    final count = _pointers.length;

    if (count == 1) {
      // ── SINGLE FINGER: MOUSE MOVE ────────────────────────────────────────
      final dx = _accel(delta.dx) * _speed;
      final dy = _accel(delta.dy) * _speed;
      _s.sendMouseMove(dx, dy);

    } else if (count == 2) {
      // ── TWO FINGERS: SCROLL ───────────────────────────────────────────────
      // Only use the event's own delta — do NOT average both pointers
      // (averaging causes doubled/erratic scroll)
      
      if (!_isScrolling) {
        // Require minimum movement before starting scroll
        // Prevents right-click from triggering accidental scroll
        final downDist = (curr - _downPos[e.pointer]!).distance;
        if (downDist < _scrollStartThreshold) return;
        _isScrolling = true;
      }

      final mult = _invertScroll ? -1.0 : 1.0;
      // Send raw delta — agent multiplies by sensitivity
      // Do NOT multiply here — double multiplication = too fast
      _s.sendScroll(delta.dx * mult, delta.dy * mult);
    }
  }

  // ─── POINTER UP ────────────────────────────────────────────────────────────
  void _onUp(PointerUpEvent e) {
    // Capture state BEFORE removing pointer
    final countBefore = _pointers.length;
    final wasScrolling = _isScrolling;
    final fingerDownPos = _downPos[e.pointer];
    final fingerCurrPos = _pointers[e.pointer];

    // Remove pointer
    _pointers.remove(e.pointer);
    _prevPos.remove(e.pointer);
    _downPos.remove(e.pointer);

    final countAfter = _pointers.length;

    // ── STOP SCROLL when all fingers lift ──────────────────────────────────
    if (countAfter == 0) {
      _isScrolling = false;
    }

    // ── TWO-FINGER TAP → RIGHT CLICK ───────────────────────────────────────
    // Fires when first of two fingers lifts AND we never scrolled
    if (countBefore == 2 && countAfter == 1 && !wasScrolling) {
      if (_haptic) HapticFeedback.mediumImpact();
      _showRipple(fingerCurrPos ?? e.localPosition);
      _s.sendClick('right');
      debugPrint('[Gesture] RIGHT CLICK ✓');

      // Clear remaining pointer to prevent phantom single-tap
      _pointers.clear();
      _prevPos.clear();
      _downPos.clear();
      _isScrolling = false;
      return;
    }

    // ── SINGLE-FINGER TAP → LEFT CLICK ────────────────────────────────────
    // Fires when the only finger lifts and barely moved
    if (countBefore == 1 && countAfter == 0) {
      if (fingerDownPos != null && fingerCurrPos != null) {
        final moved = (fingerCurrPos - fingerDownPos).distance;
        if (moved < _tapMoveThreshold) {
          if (_haptic) HapticFeedback.lightImpact();
          _showRipple(fingerCurrPos);
          _s.sendClick('left');
          debugPrint('[Gesture] LEFT CLICK ✓ (moved=${moved.toStringAsFixed(1)}px)');
        } else {
          debugPrint('[Gesture] Drag ended (moved=${moved.toStringAsFixed(1)}px, no click)');
        }
      }
    }
  }

  // ─── POINTER CANCEL ────────────────────────────────────────────────────────
  void _onCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    _prevPos.remove(e.pointer);
    _downPos.remove(e.pointer);
    if (_pointers.isEmpty) _isScrolling = false;
  }

  // ─── ACCELERATION CURVE ────────────────────────────────────────────────────
  double _accel(double v) {
    final a = v.abs();
    if (a < 1.5) return v * 0.7;  // very slow for precision
    if (a < 4.0) return v * 1.0;  // normal
    if (a < 8.0) return v * 1.4;  // fast
    return v * 1.8;                // very fast swipe
  }

  // ─── RIPPLE VISUAL ─────────────────────────────────────────────────────────
  void _showRipple(Offset pos) {
    setState(() => _ripplePos = pos);
    _rippleController.forward(from: 0);
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown:   _onDown,
      onPointerMove:   _onMove,
      onPointerUp:     _onUp,
      onPointerCancel: _onCancel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background
            Container(
              color: Colors.black,
              child: CustomPaint(
                painter: _GridPainter(),
                child: const SizedBox.expand(),
              ),
            ),
            // Gradient glow
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    radius: 0.8,
                    colors: [
                      AppColors.primary.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Tap ripple
            if (_ripplePos != null)
              AnimatedBuilder(
                animation: _rippleController,
                builder: (_, __) {
                  final t = _rippleController.value;
                  return Positioned(
                    left: _ripplePos!.dx - 30,
                    top:  _ripplePos!.dy - 30,
                    child: Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.3 + t * 1.7,
                        child: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryDim.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            // Hint text
            Positioned(
              bottom: 10,
              left: 0, right: 0,
              child: Text(
                'SLIDE · TAP TO CLICK · 2 FINGER SCROLL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.1,
                  color: Colors.white.withOpacity(0.07),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grid background painter ──────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 0.5;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
```

---

## FIX A2 — PYTHON AGENT: Fix scroll sensitivity

In `touchifymouse_agent.py`, find the scroll handler and replace:

```python
# FIND THIS (wrong):
elif t == 'scroll':
    dy = cmd.get('deltaY', 0)
    dx = cmd.get('deltaX', 0)
    pyautogui.scroll(int(-dy))

# REPLACE WITH THIS (correct):
elif t == 'scroll':
    raw_dy = float(cmd.get('deltaY', 0))
    raw_dx = float(cmd.get('deltaX', 0))
    
    # Flutter sends raw pixel deltas (small floats like 0.3, 1.2, etc.)
    # pyautogui.scroll() needs integers — multiply by sensitivity first
    SENSITIVITY = 3
    dy = int(-raw_dy * SENSITIVITY)
    dx = int(raw_dx  * SENSITIVITY)
    
    if dy != 0:
        pyautogui.scroll(dy)
    if dx != 0:
        pyautogui.hscroll(dx)
```

---

# ═══════════════════════════════════════════════════════
# PART B — KEYBOARD FIX
# ═══════════════════════════════════════════════════════

## FIX B1 — keyboard_panel.dart: Full QWERTY + wiring

Replace keyboard_panel.dart entirely:

```dart
// lib/features/keyboard/widgets/keyboard_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../trackpad/services/trackpad_socket_service.dart';
import '../../../core/theme/app_colors.dart';

enum _KeyboardTab { qwerty, numFn, arrows }

class KeyboardPanel extends ConsumerStatefulWidget {
  const KeyboardPanel({super.key});
  @override
  ConsumerState<KeyboardPanel> createState() => _KeyboardPanelState();
}

class _KeyboardPanelState extends ConsumerState<KeyboardPanel> {
  _KeyboardTab _tab = _KeyboardTab.qwerty;
  final Set<String> _heldModifiers = {};

  TrackpadSocketService get _s => TrackpadSocketService.instance;

  void _sendKey(String code) {
    HapticFeedback.selectionClick();
    final mods = _heldModifiers.toList();
    debugPrint('[Keyboard] sendKey($code, $mods)');
    _s.sendKey(code, mods);
    // Clear one-shot modifiers (shift clears after single key)
    if (_heldModifiers.contains('shift')) {
      setState(() => _heldModifiers.remove('shift'));
    }
  }

  void _toggleMod(String mod) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_heldModifiers.contains(mod)) {
        _heldModifiers.remove(mod);
      } else {
        _heldModifiers.add(mod);
      }
    });
    debugPrint('[Keyboard] modifiers: $_heldModifiers');
  }

  bool _isMod(String mod) => _heldModifiers.contains(mod);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Tab bar ────────────────────────────────────────────────────────
          _buildTabBar(),
          // ── Shortcut chips ─────────────────────────────────────────────────
          _buildShortcutChips(),
          // ── Modifier row ───────────────────────────────────────────────────
          _buildModifierRow(),
          // ── Content ────────────────────────────────────────────────────────
          if (_tab == _KeyboardTab.qwerty) _buildQwerty(),
          if (_tab == _KeyboardTab.numFn)   _buildNumFn(),
          if (_tab == _KeyboardTab.arrows)  _buildArrows(),
          // ── Arrow cluster (always visible) ─────────────────────────────────
          if (_tab == _KeyboardTab.qwerty)  _buildArrowCluster(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Row(
        children: [
          _tab_(label: 'ABC',  tab: _KeyboardTab.qwerty),
          const SizedBox(width: 6),
          _tab_(label: '123/Fn', tab: _KeyboardTab.numFn),
          const SizedBox(width: 6),
          _tab_(label: '↑↓←→', tab: _KeyboardTab.arrows),
        ],
      ),
    );
  }

  Widget _tab_({required String label, required _KeyboardTab tab}) {
    final active = _tab == tab;
    return GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.15) : AppColors.surface3,
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.primaryDim : AppColors.text3,
          )),
      ),
    );
  }

  Widget _buildShortcutChips() {
    final chips = [
      ('App Switch', 'app_switcher'),
      ('Screenshot', 'screenshot'),
      ('Lock', 'lock_screen'),
      ('Desktop', 'show_desktop'),
      ('Mission Ctrl', 'mission_control'),
    ];
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        children: chips.map((c) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () {
              debugPrint('[Keyboard] shortcut: ${c.$2}');
              _s.sendShortcut(c.$2);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface3,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(c.$1,
                style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text2,
                )),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildModifierRow() {
    final mods = [
      ('Shift', 'shift'),
      ('Ctrl',  'ctrl'),
      ('Cmd',   'cmd'),
      ('Option','alt'),
      ('Fn',    'fn'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Row(
        children: mods.map((m) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () => _toggleMod(m.$2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _isMod(m.$2)
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.surface3,
                  border: Border.all(
                    color: _isMod(m.$2) ? AppColors.primary : AppColors.borderMid,
                    width: _isMod(m.$2) ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(m.$1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _isMod(m.$2) ? AppColors.primaryDim : AppColors.text2,
                    fontFamily: 'DM Mono',
                  )),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildQwerty() {
    const rows = [
      ['q','w','e','r','t','y','u','i','o','p'],
      ['a','s','d','f','g','h','j','k','l'],
      ['z','x','c','v','b','n','m'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              children: [
                if (row == rows[2])
                  _specialKey('⇧', flex: 15, onTap: () => _toggleMod('shift')),
                ...row.map((k) => _key(k.toUpperCase(), onTap: () => _sendKey(k))),
                if (row == rows[2])
                  _specialKey('⌫', flex: 15, onTap: () => _sendKey('backspace')),
              ],
            ),
          ),
        // Bottom row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: [
              _specialKey('123', flex: 15, onTap: () => setState(() => _tab = _KeyboardTab.numFn)),
              _specialKey('Tab', flex: 12, onTap: () => _sendKey('tab')),
              Expanded(
                flex: 40,
                child: GestureDetector(
                  onTap: () => _sendKey('space'),
                  child: _keyContainer(
                    child: const Text('SPACE',
                      style: TextStyle(fontSize: 10, color: AppColors.text3,
                          fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              _specialKey('Esc', flex: 12, onTap: () => _sendKey('esc')),
              _specialKey('↵', flex: 15, onTap: () => _sendKey('return')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumFn() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(children: [
        // F keys row
        Row(children: List.generate(6, (i) =>
          _key('F${i+1}', onTap: () => _sendKey('f${i+1}')))),
        Row(children: List.generate(6, (i) =>
          _key('F${i+7}', onTap: () => _sendKey('f${i+7}')))),
        const SizedBox(height: 4),
        // Number pad
        Row(children: ['7','8','9','/'].map((k) => _key(k, onTap: () => _sendKey(k))).toList()),
        Row(children: ['4','5','6','*'].map((k) => _key(k, onTap: () => _sendKey(k))).toList()),
        Row(children: ['1','2','3','-'].map((k) => _key(k, onTap: () => _sendKey(k))).toList()),
        Row(children: [
          Expanded(flex: 2, child: GestureDetector(
            onTap: () => _sendKey('0'),
            child: _keyContainer(child: const Text('0',
              style: TextStyle(fontSize: 14, color: AppColors.text1,
                  fontWeight: FontWeight.w600))),
          )),
          _key('.', onTap: () => _sendKey('.')),
          _key('+', onTap: () => _sendKey('=')),
        ]),
        Row(children: [
          _specialKey('Home', flex: 1, onTap: () => _sendKey('home')),
          _specialKey('End',  flex: 1, onTap: () => _sendKey('end')),
          _specialKey('PgUp', flex: 1, onTap: () => _sendKey('pageup')),
          _specialKey('PgDn', flex: 1, onTap: () => _sendKey('pagedown')),
          _specialKey('Del',  flex: 1, onTap: () => _sendKey('delete')),
          _specialKey('Ins',  flex: 1, onTap: () => _sendKey('insert')),
        ]),
      ]),
    );
  }

  Widget _buildArrows() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _arrowKey(Icons.arrow_upward, () => _sendKey('up')),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _arrowKey(Icons.arrow_back,    () => _sendKey('left')),
          const SizedBox(width: 6),
          _arrowKey(Icons.arrow_downward,() => _sendKey('down')),
          const SizedBox(width: 6),
          _arrowKey(Icons.arrow_forward, () => _sendKey('right')),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _specialKey('Home', flex: 1, onTap: () => _sendKey('home')),
          _specialKey('End',  flex: 1, onTap: () => _sendKey('end')),
          _specialKey('PgUp', flex: 1, onTap: () => _sendKey('pageup')),
          _specialKey('PgDn', flex: 1, onTap: () => _sendKey('pagedown')),
        ]),
      ]),
    );
  }

  Widget _buildArrowCluster() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _arrowKey(Icons.arrow_back,    () => _sendKey('left')),
          const SizedBox(width: 4),
          Column(mainAxisSize: MainAxisSize.min, children: [
            _arrowKey(Icons.arrow_upward,   () => _sendKey('up')),
            const SizedBox(height: 4),
            _arrowKey(Icons.arrow_downward, () => _sendKey('down')),
          ]),
          const SizedBox(width: 4),
          _arrowKey(Icons.arrow_forward, () => _sendKey('right')),
        ],
      ),
    );
  }

  // ─── Key builder helpers ──────────────────────────────────────────────────
  Widget _key(String label, {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: _keyContainer(
          child: Text(label,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1,
            )),
        ),
      ),
    );
  }

  Widget _specialKey(String label, {required VoidCallback onTap, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: _keyContainer(
          color: AppColors.surface4,
          child: Text(label,
            style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text2,
            )),
        ),
      ),
    );
  }

  Widget _arrowKey(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 36,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.surface3,
          border: Border.all(color: AppColors.borderMid),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppColors.text2),
      ),
    );
  }

  Widget _keyContainer({required Widget child, Color? color}) {
    return Container(
      height: 34,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface3,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(7),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), offset: const Offset(0, 2), blurRadius: 0, spreadRadius: 0)],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
```

---

## FIX B2 — PYTHON AGENT: keyboard handler fix

```python
# In touchifymouse_agent.py — replace key handler:

elif t == 'key':
    import pyautogui
    pyautogui.FAILSAFE = False
    
    code = cmd.get('code', '')
    modifiers = cmd.get('modifiers', [])
    
    KEY_MAP = {
        'return': 'enter', 'backspace': 'backspace', 'space': 'space',
        'up': 'up', 'down': 'down', 'left': 'left', 'right': 'right',
        'cmd': 'command', 'ctrl': 'ctrl', 'alt': 'alt', 'shift': 'shift',
        'tab': 'tab', 'esc': 'escape', 'delete': 'delete', 'insert': 'insert',
        'home': 'home', 'end': 'end', 'pageup': 'pageup', 'pagedown': 'pagedown',
        'f1':'f1','f2':'f2','f3':'f3','f4':'f4','f5':'f5','f6':'f6',
        'f7':'f7','f8':'f8','f9':'f9','f10':'f10','f11':'f11','f12':'f12',
        'fn': None,  # fn key alone does nothing on desktop
    }
    
    mapped = KEY_MAP.get(code.lower(), code.lower())
    if mapped is None:
        log.info(f"KEY: skipping unmappable key: {code}")
        continue
    
    mapped_mods = [KEY_MAP.get(m.lower(), m.lower()) for m in modifiers
                   if KEY_MAP.get(m.lower(), m.lower()) is not None]
    
    log.info(f"KEY: '{code}'→'{mapped}' mods={modifiers}→{mapped_mods}")
    
    try:
        if mapped_mods:
            pyautogui.hotkey(*mapped_mods, mapped)
        else:
            pyautogui.press(mapped)
        log.info(f"KEY DONE: {mapped}")
    except Exception as e:
        log.error(f"KEY FAILED: {e} — key='{mapped}' mods={mapped_mods}")
```

---

# ═══════════════════════════════════════════════════════
# PART C — MEDIA FIX
# ═══════════════════════════════════════════════════════

## FIX C1 — media_remote_panel.dart: Wire all buttons

```dart
// lib/features/media/widgets/media_remote_panel.dart
// Find each button and ensure these exact onTap calls exist:

// Play/Pause button:
onTap: () {
  debugPrint('[Media] PLAY_PAUSE');
  TrackpadSocketService.instance.sendMedia('play_pause');
  HapticFeedback.lightImpact();
},

// Previous track:
onTap: () {
  debugPrint('[Media] PREVIOUS');
  TrackpadSocketService.instance.sendMedia('previous');
},

// Next track:
onTap: () {
  debugPrint('[Media] NEXT');
  TrackpadSocketService.instance.sendMedia('next');
},

// Mute:
onTap: () {
  debugPrint('[Media] MUTE');
  TrackpadSocketService.instance.sendMedia('mute');
},

// Volume slider — use onChanged NOT onChangeEnd:
onChanged: (double val) {
  debugPrint('[Media] VOLUME: $val');
  TrackpadSocketService.instance.sendMedia('volume', value: val);
},

// Shuffle:
onTap: () => TrackpadSocketService.instance.sendMedia('shuffle'),

// Repeat:
onTap: () => TrackpadSocketService.instance.sendMedia('repeat'),
```

## FIX C2 — Python: media handler (macOS key codes)

```python
# In touchifymouse_agent.py — replace handle_media function:

def handle_media(action, value=0.5):
    log.info(f"MEDIA: {action} value={value}")
    
    if OS == 'Darwin':
        # Use NX_KEYTYPE key codes via AppleScript
        # These work regardless of which app is playing
        NX_KEYCODES = {
            'play_pause': 16,
            'next':       17,
            'previous':   18,
            'mute':        7,
        }
        
        if action in NX_KEYCODES:
            keycode = NX_KEYCODES[action]
            # Must send both keydown and keyup
            script = f'''
tell application "System Events"
    key code {keycode}
end tell
'''
            result = subprocess.run(
                ['osascript', '-e', script],
                capture_output=True, text=True
            )
            if result.returncode != 0:
                log.error(f"MEDIA osascript error: {result.stderr}")
                # Fallback: try using keyboard key directly
                import pyautogui
                fallback = {'play_pause': 'playpause', 'next': 'nexttrack',
                           'previous': 'prevtrack', 'mute': 'volumemute'}
                pyautogui.press(fallback.get(action, ''))
            else:
                log.info(f"MEDIA {action} sent via osascript")
        
        elif action == 'volume':
            vol = max(0, min(100, int(value * 100)))
            script = f'set volume output volume {vol}'
            subprocess.run(['osascript', '-e', script])
            log.info(f"VOLUME set to {vol}%")
        
        elif action == 'shuffle':
            import pyautogui
            pyautogui.hotkey('command', 'shift', 's')
        
        elif action == 'repeat':
            import pyautogui
            pyautogui.hotkey('command', 'shift', 'r')
    
    elif OS == 'Windows':
        import ctypes
        VK = {
            'play_pause': 0xB3, 'next': 0xB0,
            'previous':   0xB1, 'mute': 0xAD,
        }
        vk = VK.get(action)
        if vk:
            ctypes.windll.user32.keybd_event(vk, 0, 0, 0)
            ctypes.windll.user32.keybd_event(vk, 0, 2, 0)
        elif action == 'volume':
            # VK_VOLUME_UP / VK_VOLUME_DOWN repeatedly
            times = int(abs(value - 0.5) * 20)
            vk_vol = 0xAF if value > 0.5 else 0xAE
            for _ in range(times):
                ctypes.windll.user32.keybd_event(vk_vol, 0, 0, 0)
                ctypes.windll.user32.keybd_event(vk_vol, 0, 2, 0)
```

---

# ═══════════════════════════════════════════════════════
# PART D — MIC & SPEAKER FIX
# ═══════════════════════════════════════════════════════

## FIX D1 — mic_stream_service.dart

```dart
// lib/features/audio/services/mic_stream_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../trackpad/services/trackpad_socket_service.dart';

class MicStreamService {
  static final instance = MicStreamService._();
  MicStreamService._();

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<List<int>>? _sub;
  bool _active = false;

  bool get isActive => _active;

  Future<bool> start({int sampleRate = 44100}) async {
    if (_active) return true;

    // Request mic permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('[Mic] Permission denied');
      return false;
    }

    if (!TrackpadSocketService.instance.isConnected) {
      debugPrint('[Mic] Not connected to desktop');
      return false;
    }

    try {
      final stream = await _recorder.startStream(RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      ));

      _sub = stream.listen((chunk) {
        if (!TrackpadSocketService.instance.isConnected) return;
        final b64 = base64Encode(chunk);
        TrackpadSocketService.instance.sendRaw(jsonEncode({
          'type': 'audio_mic_chunk',
          'data': b64,
          'sampleRate': sampleRate,
        }));
      });

      _active = true;
      debugPrint('[Mic] Started @ ${sampleRate}Hz');
      return true;
    } catch (e) {
      debugPrint('[Mic] Start error: $e');
      return false;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    await _recorder.stop();
    _active = false;
    debugPrint('[Mic] Stopped');
  }
}
```

## FIX D2 — microphone_screen.dart: Wire the toggle

```dart
// In microphone_screen.dart — find the mic toggle onChanged:

onChanged: (bool val) async {
  if (val) {
    final ok = await MicStreamService.instance.start(
      sampleRate: _selectedQuality == 0 ? 16000
                : _selectedQuality == 1 ? 44100 : 48000,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'Mic failed — check permissions or connection'
        )),
      );
      return;
    }
  } else {
    await MicStreamService.instance.stop();
  }
  setState(() => _micEnabled = val);
},
```

## FIX D3 — Python: mic playback with sounddevice

```python
# In touchifymouse_agent.py:
# Add this at the top:
import sounddevice as sd
import numpy as np
import base64

# In execute_command, handle mic chunks:
elif t == 'audio_mic_chunk':
    try:
        raw = base64.b64decode(cmd['data'])
        sr  = int(cmd.get('sampleRate', 44100))
        audio = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
        sd.play(audio, samplerate=sr, blocking=False)
        log.debug(f"MIC: played {len(raw)} bytes @ {sr}Hz")
    except Exception as e:
        log.error(f"MIC PLAY ERROR: {e}")
        # sounddevice not installed? → pip install sounddevice
```

## FIX D4 — speaker_stream_service.dart

```dart
// lib/features/audio/services/speaker_stream_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import '../../trackpad/services/trackpad_socket_service.dart';

class SpeakerStreamService {
  static final instance = SpeakerStreamService._();
  SpeakerStreamService._();

  bool _active = false;
  bool get isActive => _active;

  // Buffer of incoming PCM chunks
  final _audioQueue = <Uint8List>[];
  StreamController<Uint8List>? _streamController;

  Future<bool> start() async {
    if (_active) return true;
    if (!TrackpadSocketService.instance.isConnected) return false;

    // Tell agent to start sending audio
    TrackpadSocketService.instance.sendRaw(
      jsonEncode({'type': 'speaker_start'})
    );
    _active = true;
    debugPrint('[Speaker] Started — waiting for audio from desktop');
    return true;
  }

  // Called by TrackpadSocketService when it receives audio_speaker_chunk
  void handleChunk(Map<String, dynamic> data) {
    try {
      final bytes = base64Decode(data['data'] as String);
      // TODO: feed to audio player
      // For now just log receipt
      debugPrint('[Speaker] Received ${bytes.length} bytes');
    } catch (e) {
      debugPrint('[Speaker] Chunk error: $e');
    }
  }

  Future<void> stop() async {
    TrackpadSocketService.instance.sendRaw(
      jsonEncode({'type': 'speaker_stop'})
    );
    _active = false;
    debugPrint('[Speaker] Stopped');
  }
}
```

---

# ═══════════════════════════════════════════════════════
# PART E — FLUTTER DESKTOP APP: Replace Python-only agent
# with full Flutter UI that ALSO runs the agent
# ═══════════════════════════════════════════════════════

## ARCHITECTURE DECISION

The Flutter desktop app should:
1. Launch the Python agent binary as a SUBPROCESS (not replace it)
2. Show a proper window with permissions, QR code, device status
3. When the window is closed → minimize to tray (agent keeps running)

This way the Python agent handles all the OS-level input injection
(it already works) and Flutter provides the UI shell around it.

## FIX E1 — Flutter Desktop: main.dart

```dart
// touchifymouse_desktop/lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:path/path.dart' as p;

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/agent_process_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Window setup
  await windowManager.ensureInitialized();
  await windowManager.setSize(const Size(860, 580));
  await windowManager.setMinimumSize(const Size(700, 480));
  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  await windowManager.center();
  await windowManager.setBackgroundColor(const Color(0xFF0D0D11));

  // Start the Python agent subprocess
  await AgentProcessService.instance.start();

  runApp(const ProviderScope(child: TouchifyMouseDesktopApp()));
}

class TouchifyMouseDesktopApp extends ConsumerWidget {
  const TouchifyMouseDesktopApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TouchifyMouse',
      theme: AppTheme.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

## FIX E2 — AgentProcessService: Launch Python agent

```dart
// touchifymouse_desktop/lib/services/agent_process_service.dart

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AgentProcessService {
  static final instance = AgentProcessService._();
  AgentProcessService._();

  Process? _process;
  bool get isRunning => _process != null;

  Future<void> start() async {
    if (_process != null) return;

    // Find the bundled agent binary
    // In Flutter desktop, assets are in the app bundle
    final appDir = p.dirname(Platform.resolvedExecutable);
    
    String agentPath;
    if (Platform.isMacOS) {
      // macOS: MyApp.app/Contents/MacOS/../Resources/assets/bin/touchifymouse_agent
      agentPath = p.join(appDir, '..', 'Resources', 'flutter_assets',
          'assets', 'bin', 'touchifymouse_agent');
    } else {
      // Windows: next to the .exe
      agentPath = p.join(appDir, 'assets', 'bin', 'touchifymouse_agent.exe');
    }

    debugPrint('[Agent] Starting: $agentPath');

    if (!File(agentPath).existsSync()) {
      debugPrint('[Agent] Binary not found at $agentPath');
      // Try running from source with python (development mode)
      await _startFromSource();
      return;
    }

    try {
      _process = await Process.start(
        agentPath, [],
        mode: ProcessStartMode.normal,
      );

      // Log stdout/stderr
      _process!.stdout.listen((bytes) {
        final line = String.fromCharCodes(bytes);
        debugPrint('[Agent stdout] $line');
      });
      _process!.stderr.listen((bytes) {
        final line = String.fromCharCodes(bytes);
        debugPrint('[Agent stderr] $line');
      });

      debugPrint('[Agent] Started with PID ${_process!.pid}');
    } catch (e) {
      debugPrint('[Agent] Failed to start: $e');
      await _startFromSource();
    }
  }

  Future<void> _startFromSource() async {
    // Development fallback: run python script directly
    final scriptPath = p.join(
      Directory.current.path,
      '__agent_rebuild', 'touchifymouse_agent.py',
    );
    if (!File(scriptPath).existsSync()) {
      debugPrint('[Agent] Source script not found either: $scriptPath');
      return;
    }
    try {
      _process = await Process.start('python3', [scriptPath]);
      debugPrint('[Agent] Started from source: $scriptPath');
    } catch (e) {
      debugPrint('[Agent] python3 not available: $e');
    }
  }

  Future<void> stop() async {
    _process?.kill();
    await _process?.exitCode;
    _process = null;
    debugPrint('[Agent] Stopped');
  }
}
```

## FIX E3 — Permissions Screen in Flutter Desktop

```dart
// touchifymouse_desktop/lib/features/permissions/permissions_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});
  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  Timer? _checkTimer;
  bool _accessibilityGranted = false;
  bool _firewallOk = false;
  bool _networkOk = true; // always true on desktop
  bool _micGranted = false;

  @override
  void initState() {
    super.initState();
    _checkAll();
    // Re-check every 2 seconds so UI updates instantly when user grants
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkAll());
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAll() async {
    if (Platform.isMacOS) {
      final accessibility = await _checkAccessibilityMac();
      final firewall      = await _checkFirewallMac();
      final mic           = await _checkMicMac();
      if (mounted) {
        setState(() {
          _accessibilityGranted = accessibility;
          _firewallOk           = firewall;
          _micGranted           = mic;
        });
      }
    } else {
      // Windows — check by attempting operations
      setState(() {
        _accessibilityGranted = true; // Windows UAC is handled differently
        _firewallOk = true;
        _micGranted = true;
      });
    }
  }

  Future<bool> _checkAccessibilityMac() async {
    try {
      final result = await Process.run('osascript', [
        '-e', 'tell application "System Events" to return name of processes'
      ]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkFirewallMac() async {
    // Try binding port 35901 briefly
    try {
      final server = await ServerSocket.bind(
        InternetAddress.anyIPv4, 35901,
        shared: true,
      );
      await server.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkMicMac() async {
    try {
      final result = await Process.run('osascript', [
        '-e',
        'tell application "System Events" to return (exists process "coreaudiod")'
      ]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  void _openAccessibilityPrefs() {
    Process.run('open', [
      'x-apple.systempreferences:'
      'com.apple.preference.security?Privacy_Accessibility'
    ]);
  }

  void _openFirewallPrefs() {
    Process.run('open', [
      'x-apple.systempreferences:'
      'com.apple.preference.security?Firewall'
    ]);
  }

  void _openMicPrefs() {
    Process.run('open', [
      'x-apple.systempreferences:'
      'com.apple.preference.security?Privacy_Microphone'
    ]);
  }

  bool get _allGranted =>
    _accessibilityGranted && _firewallOk && _networkOk && _micGranted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface0,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Permissions Required',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text1,
                letterSpacing: -0.5,
              )),
            const SizedBox(height: 4),
            const Text(
              'TouchifyMouse needs these permissions to control your Mac.',
              style: TextStyle(fontSize: 13, color: AppColors.text3),
            ),
            const SizedBox(height: 24),
            _PermRow(
              icon: Icons.accessibility_new_rounded,
              iconColor: AppColors.primaryLight,
              title: 'Accessibility',
              description:
                'Required to move cursor and send keyboard/mouse events',
              granted: _accessibilityGranted,
              onGrant: _openAccessibilityPrefs,
            ),
            _PermRow(
              icon: Icons.security_rounded,
              iconColor: AppColors.warning,
              title: 'Network / Firewall',
              description: 'Allow TouchifyMouse to receive connections',
              granted: _firewallOk,
              onGrant: _openFirewallPrefs,
            ),
            _PermRow(
              icon: Icons.wifi_rounded,
              iconColor: AppColors.success,
              title: 'Local Network',
              description: 'Discover phones on your Wi-Fi automatically',
              granted: _networkOk,
              onGrant: null, // always granted
            ),
            _PermRow(
              icon: Icons.mic_rounded,
              iconColor: const Color(0xFF34D399),
              title: 'Microphone',
              description: 'Play audio from phone mic through this Mac',
              granted: _micGranted,
              onGrant: _openMicPrefs,
            ),
            const Spacer(),
            if (!_allGranted)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withOpacity(0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                      color: AppColors.danger, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Accessibility permission is required before you can '
                        'use mouse/keyboard control.',
                        style: TextStyle(
                          fontSize: 12, color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _accessibilityGranted
                  ? () => Navigator.of(context).pushReplacementNamed('/dashboard')
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.surface4,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _allGranted ? 'All set — Open Dashboard' : 'Grant Remaining Permissions',
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool granted;
  final VoidCallback? onGrant;

  const _PermRow({
    required this.icon, required this.iconColor,
    required this.title, required this.description,
    required this.granted, required this.onGrant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.text1,
                  )),
                Text(description,
                  style: const TextStyle(
                    fontSize: 11, color: AppColors.text3,
                  )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (granted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success.withOpacity(0.25)),
              ),
              child: Row(children: [
                Icon(Icons.check_circle_rounded,
                  size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                const Text('Granted',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  )),
              ]),
            )
          else if (onGrant != null)
            GestureDetector(
              onTap: onGrant,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.danger.withOpacity(0.25)),
                ),
                child: Row(children: [
                  Icon(Icons.open_in_new_rounded,
                    size: 12, color: AppColors.danger),
                  const SizedBox(width: 4),
                  const Text('Grant Access →',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    )),
                ]),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('System',
                style: TextStyle(fontSize: 11, color: AppColors.text3)),
            ),
        ],
      ),
    );
  }
}
```

---

# ═══════════════════════════════════════════════════════
# APPLY IN THIS EXACT ORDER
# ═══════════════════════════════════════════════════════

## Step 1 — Fix Python agent FIRST (scroll sensitivity + logging)
- Update scroll handler: `int(-raw_dy * 3)`
- Add full logging (see Part A Fix A2 + earlier guide)
- Restart agent: `python3 touchifymouse_agent.py`

## Step 2 — Fix trackpad_surface.dart (auto-scroll + tap)
- Full replacement with Part A Fix A1 code
- Key change: 0.5px jitter guard + pointer count captured BEFORE removal

## Step 3 — Fix keyboard_panel.dart (full QWERTY)
- Full replacement with Part B Fix B1 code

## Step 4 — Fix media buttons
- Wire all buttons per Part C Fix C1

## Step 5 — Fix mic/speaker
- Replace service files per Part D

## Step 6 — Flutter Desktop: add agent launcher + permissions screen
- Add AgentProcessService (Part E Fix E2)
- Add PermissionsScreen (Part E Fix E3)
- Call AgentProcessService.instance.start() in main()

---

# QUICK TEST AFTER EACH FIX

After Part A (gesture fix):
→ Open app → tap trackpad once → left click should register
→ Touch with two fingers without moving → right click should register  
→ No auto-scrolling when not touching

After Part B (keyboard):
→ Open keyboard tab → type 'a' → letter 'a' appears on Mac
→ Press Cmd chip + C key → copy works

After Part C (media):
→ Play Spotify on Mac → press play/pause in app → music pauses

After Part D (audio):
→ Enable mic in app → speak → your voice plays through Mac speakers
→ Watch agent log: `MIC: played X bytes`

After Part E (Flutter desktop):
→ Run `flutter run -d macos` in touchifymouse_desktop/
→ App opens, shows permissions screen
→ Accessibility shows red → click "Grant Access →" → opens System Settings
→ After granting, red turns green automatically within 2 seconds

---

# FILE MAP FOR THIS GUIDE

```
touchify_mouse/lib/
  features/trackpad/widgets/trackpad_surface.dart     ← Part A Fix A1
  features/keyboard/widgets/keyboard_panel.dart       ← Part B Fix B1
  features/media/widgets/media_remote_panel.dart      ← Part C Fix C1
  features/audio/services/mic_stream_service.dart     ← Part D Fix D1
  features/audio/screens/microphone_screen.dart       ← Part D Fix D2
  features/audio/services/speaker_stream_service.dart ← Part D Fix D4

touchifymouse_desktop/lib/
  main.dart                                           ← Part E Fix E1
  services/agent_process_service.dart                 ← Part E Fix E2
  features/permissions/permissions_screen.dart        ← Part E Fix E3

touchifymouse_desktop/__agent_rebuild/
  touchifymouse_agent.py                              ← Part A Fix A2
                                                         Part B Fix B2
                                                         Part C Fix C2
                                                         Part D Fix D3
```
