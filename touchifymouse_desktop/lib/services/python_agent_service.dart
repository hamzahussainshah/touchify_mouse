import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Manages the bundled Python agent subprocess.
///
/// - Extracts the bundled binary from `assets/bin/touchifymouse_agent` to the
///   app support dir on first run (or when the asset is newer).
/// - Spawns the agent, captures stdout/stderr to the debug console.
/// - Watches for unexpected exits and restarts with exponential backoff.
/// - `stop()` is idempotent and kills the child before app quit.
class PythonAgentService {
  PythonAgentService._();
  static final PythonAgentService instance = PythonAgentService._();

  Process? _process;
  bool _starting = false;
  bool _wantRunning = false;
  int _restartAttempt = 0;
  Timer? _restartTimer;
  final _statusCtrl = StreamController<AgentStatus>.broadcast();

  Stream<AgentStatus> get status => _statusCtrl.stream;
  bool get isRunning => _process != null;

  Future<void> start() async {
    if (_starting || _wantRunning) return;
    _wantRunning = true;
    await _spawn();
  }

  Future<void> _spawn() async {
    if (_starting) return;
    _starting = true;
    _statusCtrl.add(AgentStatus.starting);
    try {
      final exe = await _ensureExecutable();
      if (exe == null) {
        _statusCtrl.add(AgentStatus.failed);
        _starting = false;
        _scheduleRestart();
        return;
      }
      debugPrint('[Agent] Spawning ${exe.path}');
      final proc = await Process.start(
        exe.path,
        const <String>[],
        mode: ProcessStartMode.normal,
        runInShell: false,
      );
      _process = proc;
      _restartAttempt = 0;
      _statusCtrl.add(AgentStatus.running);

      proc.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((l) => debugPrint('[Agent] $l'));
      proc.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((l) => debugPrint('[Agent ERR] $l'));

      proc.exitCode.then((code) {
        debugPrint('[Agent] exited with code $code');
        _process = null;
        _statusCtrl.add(AgentStatus.stopped);
        if (_wantRunning) _scheduleRestart();
      });
    } catch (e, st) {
      debugPrint('[Agent] start failed: $e\n$st');
      _statusCtrl.add(AgentStatus.failed);
      _scheduleRestart();
    } finally {
      _starting = false;
    }
  }

  /// Extract bundled binary on first run or when the bundled asset differs in
  /// size from the cached copy. We avoid rewriting on every launch (fast path).
  Future<File?> _ensureExecutable() async {
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}/agent');
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final exeName = Platform.isWindows
          ? 'touchifymouse_agent.exe'
          : 'touchifymouse_agent';
      final exe = File('${dir.path}/$exeName');

      final assetData = await rootBundle.load('assets/bin/$exeName');
      final assetBytes = assetData.buffer.asUint8List();

      final needsWrite =
          !exe.existsSync() || exe.lengthSync() != assetBytes.length;
      if (needsWrite) {
        debugPrint('[Agent] Extracting binary → ${exe.path}');
        await exe.writeAsBytes(assetBytes, flush: true);
        if (!Platform.isWindows) {
          final r = await Process.run('chmod', ['+x', exe.path]);
          if (r.exitCode != 0) {
            debugPrint('[Agent] chmod failed: ${r.stderr}');
          }
        }
      }
      return exe;
    } catch (e) {
      debugPrint('[Agent] ensure executable failed: $e');
      return null;
    }
  }

  void _scheduleRestart() {
    if (!_wantRunning) return;
    _restartTimer?.cancel();
    _restartAttempt = (_restartAttempt + 1).clamp(1, 6);
    // 2s, 4s, 8s, 16s, 32s, 32s…
    final delay = Duration(seconds: 1 << _restartAttempt);
    debugPrint('[Agent] Restart in ${delay.inSeconds}s');
    _restartTimer = Timer(delay, _spawn);
  }

  Future<void> stop() async {
    _wantRunning = false;
    _restartTimer?.cancel();
    final p = _process;
    _process = null;
    if (p != null) {
      debugPrint('[Agent] Stopping');
      p.kill(ProcessSignal.sigterm);
      // Give it 1s to exit cleanly, then SIGKILL.
      await Future.any([
        p.exitCode,
        Future<int>.delayed(const Duration(seconds: 1), () {
          p.kill(ProcessSignal.sigkill);
          return -1;
        }),
      ]);
    }
    _statusCtrl.add(AgentStatus.stopped);
  }
}

enum AgentStatus { starting, running, stopped, failed }

/// Backwards-compatible top-level handle referenced from main.dart.
final pythonAgentService = PythonAgentService.instance;
