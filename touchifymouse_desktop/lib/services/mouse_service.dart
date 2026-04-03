import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;

// --- macOS CoreGraphics FFI Definitions ---
final DynamicLibrary _cg = Platform.isMacOS 
    ? DynamicLibrary.open('/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics')
    : DynamicLibrary.process();

// CGEventCreateMouseEvent
typedef CGEventCreateMouseEventC = Pointer Function(Pointer, Int32, CGPoint, Int32);
typedef CGEventCreateMouseEventDart = Pointer Function(Pointer, int, CGPoint, int);

// CGEventPost
typedef CGEventPostC = Void Function(Int32, Pointer);
typedef CGEventPostDart = void Function(int, Pointer);

// CGEventGetLocation
typedef CGEventGetLocationC = CGPoint Function(Pointer);
typedef CGEventGetLocationDart = CGPoint Function(Pointer);

// CGEventCreate
typedef CGEventCreateC = Pointer Function(Pointer);
typedef CGEventCreateDart = Pointer Function(Pointer);

// CFRelease
typedef CFReleaseC = Void Function(Pointer);
typedef CFReleaseDart = void Function(Pointer);

final class CGPoint extends Struct {
  @Double() external double x;
  @Double() external double y;
}

const int kCGHIDEventTap = 0;
const int kCGEventMouseMoved = 5;
const int kCGEventLeftMouseDown = 1;
const int kCGEventLeftMouseUp = 2;
const int kCGEventRightMouseDown = 3;
const int kCGEventRightMouseUp = 4;
const int kCGScrollEventUnitLine = 1;

class MouseService {
  static final instance = MouseService._();
  MouseService._() {
    if (Platform.isMacOS) {
      _cgEventCreateMouseEvent = _cg.lookupFunction<CGEventCreateMouseEventC, CGEventCreateMouseEventDart>('CGEventCreateMouseEvent');
      _cgEventPost = _cg.lookupFunction<CGEventPostC, CGEventPostDart>('CGEventPost');
      _cgEventGetLocation = _cg.lookupFunction<CGEventGetLocationC, CGEventGetLocationDart>('CGEventGetLocation');
      _cgEventCreate = _cg.lookupFunction<CGEventCreateC, CGEventCreateDart>('CGEventCreate');
      _cfRelease = _cg.lookupFunction<CFReleaseC, CFReleaseDart>('CFRelease');
      // For scroll: CGEventCreateScrollWheelEvent
      _cgEventCreateScrollWheelEvent = _cg.lookupFunction<
          Pointer Function(Pointer, Int32, Int32, Int32, Int32),
          Pointer Function(Pointer, int, int, int, int)>('CGEventCreateScrollWheelEvent');
    }
  }

  late final CGEventCreateMouseEventDart _cgEventCreateMouseEvent;
  late final CGEventPostDart _cgEventPost;
  late final CGEventGetLocationDart _cgEventGetLocation;
  late final CGEventCreateDart _cgEventCreate;
  late final CFReleaseDart _cfRelease;
  late final Pointer Function(Pointer, int, int, int, int) _cgEventCreateScrollWheelEvent;

  void moveRelative(double dx, double dy) {
    if (Platform.isWindows) {
      final input = calloc<win32.INPUT>();
      input.ref.type = win32.INPUT_MOUSE;
      input.ref.mi.dx = dx.toInt();
      input.ref.mi.dy = dy.toInt();
      input.ref.mi.dwFlags = win32.MOUSEEVENTF_MOVE;
      win32.SendInput(1, input, sizeOf<win32.INPUT>());
      calloc.free(input);
    } else if (Platform.isMacOS) {
      final evt = _cgEventCreate(nullptr);
      final loc = _cgEventGetLocation(evt);
      _cfRelease(evt);

      final newLoc = calloc<CGPoint>();
      newLoc.ref.x = loc.x + dx;
      newLoc.ref.y = loc.y + dy;

      final moveEvent = _cgEventCreateMouseEvent(nullptr, kCGEventMouseMoved, newLoc.ref, 0);
      _cgEventPost(kCGHIDEventTap, moveEvent);
      _cfRelease(moveEvent);
      calloc.free(newLoc);
    }
  }

  void click(String button) {
    if (Platform.isWindows) {
      final input = calloc<win32.INPUT>();
      input.ref.type = win32.INPUT_MOUSE;
      if (button == 'left') {
        input.ref.mi.dwFlags = win32.MOUSEEVENTF_LEFTDOWN | win32.MOUSEEVENTF_LEFTUP;
      } else if (button == 'right') {
        input.ref.mi.dwFlags = win32.MOUSEEVENTF_RIGHTDOWN | win32.MOUSEEVENTF_RIGHTUP;
      }
      win32.SendInput(1, input, sizeOf<win32.INPUT>());
      calloc.free(input);
    } else if (Platform.isMacOS) {
      final evt = _cgEventCreate(nullptr);
      final loc = _cgEventGetLocation(evt);
      _cfRelease(evt);

      final pt = calloc<CGPoint>();
      pt.ref.x = loc.x;
      pt.ref.y = loc.y;

      final downType = button == 'left' ? kCGEventLeftMouseDown : kCGEventRightMouseDown;
      final upType = button == 'left' ? kCGEventLeftMouseUp : kCGEventRightMouseUp;
      final btnCode = button == 'left' ? 0 : 1;

      final downEvent = _cgEventCreateMouseEvent(nullptr, downType, pt.ref, btnCode);
      _cgEventPost(kCGHIDEventTap, downEvent);
      _cfRelease(downEvent);

      final upEvent = _cgEventCreateMouseEvent(nullptr, upType, pt.ref, btnCode);
      _cgEventPost(kCGHIDEventTap, upEvent);
      _cfRelease(upEvent);

      calloc.free(pt);
    }
  }

  void mouseDown(String button) {
    if (Platform.isWindows) {
      final input = calloc<win32.INPUT>();
      input.ref.type = win32.INPUT_MOUSE;
      input.ref.mi.dwFlags = button == 'left' ? win32.MOUSEEVENTF_LEFTDOWN : win32.MOUSEEVENTF_RIGHTDOWN;
      win32.SendInput(1, input, sizeOf<win32.INPUT>());
      calloc.free(input);
    } else if (Platform.isMacOS) {
      final evt = _cgEventCreate(nullptr);
      final loc = _cgEventGetLocation(evt);
      _cfRelease(evt);

      final pt = calloc<CGPoint>();
      pt.ref.x = loc.x;
      pt.ref.y = loc.y;

      final type = button == 'left' ? kCGEventLeftMouseDown : kCGEventRightMouseDown;
      final btnCode = button == 'left' ? 0 : 1;
      
      final downEvent = _cgEventCreateMouseEvent(nullptr, type, pt.ref, btnCode);
      _cgEventPost(kCGHIDEventTap, downEvent);
      _cfRelease(downEvent);
      calloc.free(pt);
    }
  }

  void mouseUp(String button) {
    if (Platform.isWindows) {
      final input = calloc<win32.INPUT>();
      input.ref.type = win32.INPUT_MOUSE;
      input.ref.mi.dwFlags = button == 'left' ? win32.MOUSEEVENTF_LEFTUP : win32.MOUSEEVENTF_RIGHTUP;
      win32.SendInput(1, input, sizeOf<win32.INPUT>());
      calloc.free(input);
    } else if (Platform.isMacOS) {
      final evt = _cgEventCreate(nullptr);
      final loc = _cgEventGetLocation(evt);
      _cfRelease(evt);

      final pt = calloc<CGPoint>();
      pt.ref.x = loc.x;
      pt.ref.y = loc.y;

      final type = button == 'left' ? kCGEventLeftMouseUp : kCGEventRightMouseUp;
      final btnCode = button == 'left' ? 0 : 1;
      
      final upEvent = _cgEventCreateMouseEvent(nullptr, type, pt.ref, btnCode);
      _cgEventPost(kCGHIDEventTap, upEvent);
      _cfRelease(upEvent);
      calloc.free(pt);
    }
  }

  void scroll(double dx, double dy) {
    if (Platform.isWindows) {
      if (dy != 0) {
        final input = calloc<win32.INPUT>();
        input.ref.type = win32.INPUT_MOUSE;
        input.ref.mi.mouseData = (dy * 120).toInt(); // 120 is WHEEL_DELTA
        input.ref.mi.dwFlags = win32.MOUSEEVENTF_WHEEL;
        win32.SendInput(1, input, sizeOf<win32.INPUT>());
        calloc.free(input);
      }
      if (dx != 0) {
        final input = calloc<win32.INPUT>();
        input.ref.type = win32.INPUT_MOUSE;
        input.ref.mi.mouseData = (dx * 120).toInt();
        input.ref.mi.dwFlags = win32.MOUSEEVENTF_HWHEEL;
        win32.SendInput(1, input, sizeOf<win32.INPUT>());
        calloc.free(input);
      }
    } else if (Platform.isMacOS) {
      // CGEventCreateScrollWheelEvent(source, units, wheelCount, wheel1, ...);
      // macOS scroll requires inverse polarity usually, testing native dx, dy directly:
      final scrollEvent = _cgEventCreateScrollWheelEvent(nullptr, kCGScrollEventUnitLine, 2, dy.toInt(), dx.toInt());
      _cgEventPost(kCGHIDEventTap, scrollEvent);
      _cfRelease(scrollEvent);
    }
  }
}
