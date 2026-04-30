// // lib/features/trackpad/widgets/trackpad_surface.dart

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../services/trackpad_socket_service.dart';
// import '../../../core/providers/settings_provider.dart';
// import '../../../core/theme/app_colors.dart';

// class TrackpadSurface extends ConsumerStatefulWidget {
//   const TrackpadSurface({super.key});
//   @override
//   ConsumerState<TrackpadSurface> createState() => _TrackpadSurfaceState();
// }

// class _TrackpadSurfaceState extends ConsumerState<TrackpadSurface>
//     with SingleTickerProviderStateMixin {

//   // ─── Active pointer tracking ───────────────────────────────────────────────
//   final Map<int, Offset> _pointers = {};
//   final Map<int, Offset> _prevPos = {};
//   final Map<int, Offset> _downPos = {};

//   // ─── Scroll state ──────────────────────────────────────────────────────────
//   bool _isScrolling = false;
//   static const double _scrollStartThreshold = 4.0;
//   static const double _tapMoveThreshold = 6.0;

//   // ─── Ripple animation ─────────────────────────────────────────────────────
//   Offset? _ripplePos;
//   late AnimationController _rippleController;

//   @override
//   void initState() {
//     super.initState();
//     _rippleController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//     );
//   }

//   @override
//   void dispose() {
//     _rippleController.dispose();
//     super.dispose();
//   }

//   // ─── Settings helpers ──────────────────────────────────────────────────────
//   double get _speed {
//     try { return ref.read(settingsProvider).pointerSpeed; } catch (_) { return 1.0; }
//   }
//   bool get _invertScroll {
//     try { return ref.read(settingsProvider).invertScroll; } catch (_) { return false; }
//   }
//   bool get _haptic {
//     try { return ref.read(settingsProvider).hapticFeedback; } catch (_) { return true; }
//   }
//   TrackpadSocketService get _s => TrackpadSocketService.instance;

//   // ─── POINTER DOWN ──────────────────────────────────────────────────────────
//   void _onDown(PointerDownEvent e) {
//     _pointers[e.pointer] = e.localPosition;
//     _prevPos[e.pointer]  = e.localPosition;
//     _downPos[e.pointer]  = e.localPosition;

//     if (_pointers.length == 2) {
//       _isScrolling = false;
//     }
//   }

//   // ─── POINTER MOVE ──────────────────────────────────────────────────────────
//   void _onMove(PointerMoveEvent e) {
//     if (!_pointers.containsKey(e.pointer)) return;

//     final prev = _prevPos[e.pointer]!;
//     final curr = e.localPosition;
//     final delta = curr - prev;

//     _pointers[e.pointer] = curr;
//     _prevPos[e.pointer]  = curr;

//     // Ignore micro-jitter — this is the auto-scroll fix
//     if (delta.distance < 0.5) return;

//     final count = _pointers.length;

//     if (count == 1) {
//       // ── SINGLE FINGER: MOUSE MOVE ────────────────────────────────────────
//       final dx = _accel(delta.dx) * _speed;
//       final dy = _accel(delta.dy) * _speed;
//       _s.sendMouseMove(dx, dy);

//     } else if (count == 2) {
//       // ── TWO FINGERS: SCROLL ───────────────────────────────────────────────
//       if (!_isScrolling) {
//         final downDist = (curr - _downPos[e.pointer]!).distance;
//         if (downDist < _scrollStartThreshold) return;
//         _isScrolling = true;
//       }

//       final mult = _invertScroll ? -1.0 : 1.0;
//       _s.sendScroll(delta.dx * mult, delta.dy * mult);
//     }
//   }

//   // ─── POINTER UP ────────────────────────────────────────────────────────────
//   void _onUp(PointerUpEvent e) {
//     // Capture state BEFORE removing pointer
//     final countBefore = _pointers.length;
//     final wasScrolling = _isScrolling;
//     final fingerDownPos = _downPos[e.pointer];
//     final fingerCurrPos = _pointers[e.pointer];

//     _pointers.remove(e.pointer);
//     _prevPos.remove(e.pointer);
//     _downPos.remove(e.pointer);

//     final countAfter = _pointers.length;

//     if (countAfter == 0) {
//       _isScrolling = false;
//     }

//     // ── TWO-FINGER TAP → RIGHT CLICK ───────────────────────────────────────
//     if (countBefore == 2 && countAfter == 1 && !wasScrolling) {
//       if (_haptic) HapticFeedback.mediumImpact();
//       _showRipple(fingerCurrPos ?? e.localPosition);
//       _s.sendClick('right');
//       debugPrint('[Gesture] RIGHT CLICK ✓');

//       // Clear remaining pointer to prevent phantom single-tap
//       _pointers.clear();
//       _prevPos.clear();
//       _downPos.clear();
//       _isScrolling = false;
//       return;
//     }

//     // ── SINGLE-FINGER TAP → LEFT CLICK ────────────────────────────────────
//     if (countBefore == 1 && countAfter == 0) {
//       if (fingerDownPos != null && fingerCurrPos != null) {
//         final moved = (fingerCurrPos - fingerDownPos).distance;
//         if (moved < _tapMoveThreshold) {
//           if (_haptic) HapticFeedback.lightImpact();
//           _showRipple(fingerCurrPos);
//           _s.sendClick('left');
//           debugPrint('[Gesture] LEFT CLICK ✓ (moved=${moved.toStringAsFixed(1)}px)');
//         } else {
//           debugPrint('[Gesture] Drag ended (moved=${moved.toStringAsFixed(1)}px, no click)');
//         }
//       }
//     }
//   }

//   // ─── POINTER CANCEL ────────────────────────────────────────────────────────
//   void _onCancel(PointerCancelEvent e) {
//     _pointers.remove(e.pointer);
//     _prevPos.remove(e.pointer);
//     _downPos.remove(e.pointer);
//     if (_pointers.isEmpty) _isScrolling = false;
//   }

//   // ─── ACCELERATION CURVE ────────────────────────────────────────────────────
//   double _accel(double v) {
//     final a = v.abs();
//     if (a < 1.5) return v * 0.7;
//     if (a < 4.0) return v * 1.0;
//     if (a < 8.0) return v * 1.4;
//     return v * 1.8;
//   }

//   // ─── RIPPLE VISUAL ─────────────────────────────────────────────────────────
//   void _showRipple(Offset pos) {
//     setState(() => _ripplePos = pos);
//     _rippleController.forward(from: 0);
//   }

//   // ─── BUILD ─────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     return Listener(
//       behavior: HitTestBehavior.opaque,
//       onPointerDown:   _onDown,
//       onPointerMove:   _onMove,
//       onPointerUp:     _onUp,
//       onPointerCancel: _onCancel,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: Stack(
//           children: [
//             // Background
//             Container(
//               color: Colors.black,
//               child: CustomPaint(
//                 painter: _GridPainter(),
//                 child: const SizedBox.expand(),
//               ),
//             ),
//             // Gradient glow
//             Positioned.fill(
//               child: DecoratedBox(
//                 decoration: BoxDecoration(
//                   gradient: RadialGradient(
//                     center: const Alignment(-0.3, -0.3),
//                     radius: 0.8,
//                     colors: [
//                       AppColors.primary.withValues(alpha: 0.06),
//                       Colors.transparent,
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             // Tap ripple
//             if (_ripplePos != null)
//               AnimatedBuilder(
//                 animation: _rippleController,
//                 builder: (_, __) {
//                   final t = _rippleController.value;
//                   return Positioned(
//                     left: _ripplePos!.dx - 30,
//                     top:  _ripplePos!.dy - 30,
//                     child: Opacity(
//                       opacity: (1 - t).clamp(0.0, 1.0),
//                       child: Transform.scale(
//                         scale: 0.3 + t * 1.7,
//                         child: Container(
//                           width: 60, height: 60,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               color: AppColors.primaryDim.withValues(alpha: 0.5),
//                               width: 1.5,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             // Hint text
//             Positioned(
//               bottom: 10,
//               left: 0, right: 0,
//               child: Text(
//                 'SLIDE · TAP TO CLICK · 2 FINGER SCROLL',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 9,
//                   letterSpacing: 0.1,
//                   color: Colors.white.withValues(alpha: 0.07),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Grid background painter ──────────────────────────────────────────────────
// class _GridPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (size.isEmpty) return;
//     final paint = Paint()
//       ..color = Colors.white.withValues(alpha: 0.018)
//       ..strokeWidth = 0.5;
//     const step = 32.0;
//     for (double x = 0; x < size.width; x += step) {
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
//     }
//     for (double y = 0; y < size.height; y += step) {
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
//     }
//   }
//   @override
//   bool shouldRepaint(_) => false;
// }
// lib/features/trackpad/widgets/trackpad_surface.dart
// FIXED VERSION — corrects: auto-scroll, tap detection, two-finger right click, scroll

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
  // ── Pointer tracking ────────────────────────────────────────────────────────
  final Map<int, Offset> _pointers = {}; // current position
  final Map<int, Offset> _prevPos = {}; // position at last move event
  final Map<int, Offset> _downPos = {}; // position at finger-down
  final Map<int, double> _totalMove = {}; // cumulative pixels moved per finger

  // ── Scroll state ────────────────────────────────────────────────────────────
  bool _scrollStarted = false;
  double _twoFingerMoved = 0.0; // total scroll distance this gesture

  // FIX 1: Higher thresholds — previous values (6px tap, 4px scroll) were too tight
  static const double _tapThreshold =
      12.0; // px — finger must stay within this to count as tap
  static const double _scrollThreshold =
      8.0; // px — minimum move before scroll begins
  static const double _rightClickMax =
      18.0; // px — max total scroll for two-finger tap

  // ── Ripple ──────────────────────────────────────────────────────────────────
  Offset? _ripplePos;
  late AnimationController _ripple;

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  TrackpadSocketService get _s => TrackpadSocketService.instance;

  double get _speed {
    try {
      return ref.read(settingsProvider).pointerSpeed;
    } catch (_) {
      return 1.0;
    }
  }

  bool get _invert {
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

  // ── POINTER DOWN ─────────────────────────────────────────────────────────────
  void _onDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    _prevPos[e.pointer] = e.localPosition;
    _downPos[e.pointer] = e.localPosition;
    _totalMove[e.pointer] = 0.0;

    // FIX 2: Reset scroll state when second finger touches down
    // but keep _twoFingerMoved reset here too
    if (_pointers.length == 2) {
      _scrollStarted = false;
      _twoFingerMoved = 0.0;
    }
  }

  // ── POINTER MOVE ─────────────────────────────────────────────────────────────
  void _onMove(PointerMoveEvent e) {
    // Guard: only handle known pointers
    if (!_pointers.containsKey(e.pointer)) return;

    final prev = _prevPos[e.pointer]!;
    final curr = e.localPosition;
    final delta = curr - prev;

    // Update tracking
    _pointers[e.pointer] = curr;
    _prevPos[e.pointer] = curr;
    _totalMove[e.pointer] = (_totalMove[e.pointer] ?? 0) + delta.distance;

    // FIX 3: Ignore jitter — micro-movements under 0.3px cause phantom scroll
    if (delta.distance < 0.3) return;

    final count = _pointers.length;

    // ── 1 FINGER: MOUSE MOVE ────────────────────────────────────────────────
    if (count == 1) {
      final dx = _accel(delta.dx) * _speed;
      final dy = _accel(delta.dy) * _speed;
      _s.sendMouseMove(dx, dy);
    }
    // ── 2 FINGERS: SCROLL ────────────────────────────────────────────────────
    else if (count == 2) {
      // Accumulate total movement to distinguish tap from scroll
      _twoFingerMoved += delta.distance;

      if (!_scrollStarted) {
        // Don't start scrolling until we've moved past threshold
        if (_twoFingerMoved < _scrollThreshold) return;
        _scrollStarted = true;
      }

      final mult = _invert ? -1.0 : 1.0;
      _s.sendScroll(delta.dx * mult, delta.dy * mult);
    }
  }

  // ── POINTER UP ───────────────────────────────────────────────────────────────
  void _onUp(PointerUpEvent e) {
    // FIX 4: Capture ALL state BEFORE modifying maps
    final countBefore = _pointers.length;
    final wasScrolling = _scrollStarted;
    final twoFingerTotal = _twoFingerMoved;
    final currPos = _pointers[e.pointer];
    final fingerTotal = _totalMove[e.pointer] ?? 0.0;

    // Remove this pointer
    _pointers.remove(e.pointer);
    _prevPos.remove(e.pointer);
    _downPos.remove(e.pointer);
    _totalMove.remove(e.pointer);

    final countAfter = _pointers.length;

    // Reset scroll when all fingers lift
    if (countAfter == 0) {
      _scrollStarted = false;
      _twoFingerMoved = 0.0;
    }

    // ── TWO-FINGER TAP → RIGHT CLICK ────────────────────────────────────────
    // Conditions: started with 2 fingers, one lifted, never scrolled meaningfully
    if (countBefore == 2 && countAfter == 1) {
      // FIX 5: Check TOTAL two-finger movement, not just _scrollStarted flag
      // _scrollStarted can be false even if there was some small movement
      final isActuallyTap = !wasScrolling && twoFingerTotal < _rightClickMax;

      if (isActuallyTap) {
        debugPrint(
          '[Gesture] RIGHT CLICK ✓ (twoFingerMoved=${twoFingerTotal.toStringAsFixed(1)}px)',
        );
        if (_haptic) HapticFeedback.mediumImpact();
        _showRipple(currPos ?? e.localPosition);
        _s.sendClick('right');

        // FIX 6: Clear remaining pointer so it doesn't fire a phantom left click
        final remainingPointer = _pointers.keys.firstOrNull;
        if (remainingPointer != null) {
          _pointers.remove(remainingPointer);
          _prevPos.remove(remainingPointer);
          _downPos.remove(remainingPointer);
          _totalMove.remove(remainingPointer);
        }
        _scrollStarted = false;
        _twoFingerMoved = 0.0;
        return;
      }
    }

    // ── SINGLE-FINGER TAP → LEFT CLICK ──────────────────────────────────────
    if (countBefore == 1 && countAfter == 0) {
      // FIX 7: Use total accumulated movement, more reliable than start-to-end distance
      // because start-to-end distance ignores back-and-forth wiggles
      final didNotDrag = fingerTotal < _tapThreshold;

      debugPrint(
        '[Gesture] finger up — totalMove=${fingerTotal.toStringAsFixed(1)}px'
        ' didNotDrag=$didNotDrag',
      );

      if (didNotDrag) {
        if (_haptic) HapticFeedback.lightImpact();
        _showRipple(currPos ?? e.localPosition);
        _s.sendClick('left');
        debugPrint('[Gesture] LEFT CLICK ✓');
      }
    }
  }

  // ── POINTER CANCEL ────────────────────────────────────────────────────────
  void _onCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    _prevPos.remove(e.pointer);
    _downPos.remove(e.pointer);
    _totalMove.remove(e.pointer);
    if (_pointers.isEmpty) {
      _scrollStarted = false;
      _twoFingerMoved = 0.0;
    }
  }

  // ── ACCELERATION CURVE ────────────────────────────────────────────────────
  double _accel(double v) {
    final a = v.abs();
    if (a < 1.5) return v * 0.7;
    if (a < 4.0) return v * 1.0;
    if (a < 8.0) return v * 1.4;
    return v * 1.8;
  }

  // ── RIPPLE ────────────────────────────────────────────────────────────────
  void _showRipple(Offset pos) {
    setState(() => _ripplePos = pos);
    _ripple.forward(from: 0);
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: _onCancel,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.borderMid, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 32,
                spreadRadius: -4,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: Stack(
              children: [
                // Base — deep plum gradient (not pure black; gives warmth)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          c.surface1,
                          c.surface0,
                        ],
                      ),
                    ),
                  ),
                ),
                // Subtle dotted grid (less visual noise than line grid)
                Positioned.fill(
                  child: CustomPaint(painter: _DotGridPainter()),
                ),
                // Top-left violet glow
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.7, -0.8),
                        radius: 1.0,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom-right cyan/pink glow
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.8, 0.9),
                        radius: 1.0,
                        colors: [
                          AppColors.accent.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Inner highlight stroke (top-edge specular)
                Positioned(
                  top: 0,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0x33FFFFFF),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Tap ripple
                if (_ripplePos != null)
                  AnimatedBuilder(
                    animation: _ripple,
                    builder: (_, __) {
                      final t = _ripple.value;
                      return Positioned(
                        left: _ripplePos!.dx - 40,
                        top: _ripplePos!.dy - 40,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: (1 - t).clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.3 + t * 2.0,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.35),
                                      AppColors.primary.withValues(alpha: 0.0),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: AppColors.primaryLight
                                        .withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                // Hint
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          'SLIDE · TAP · TWO-FINGER SCROLL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            color: c.text3.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle dotted grid — way less visually noisy than full lines.
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final p = Paint()..color = Colors.white.withValues(alpha: 0.05);
    const step = 26.0;
    for (double y = step; y < size.height; y += step) {
      for (double x = step; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 0.8, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
