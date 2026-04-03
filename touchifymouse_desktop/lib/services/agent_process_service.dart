// touchifymouse_desktop/lib/services/agent_process_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class AgentProcessService {
  static final instance = AgentProcessService._();
  AgentProcessService._();

  Process? _process;
  bool get isRunning => _process != null;

  Future<void> start() async {
    if (_process != null) return;

    final appDir = p.dirname(Platform.resolvedExecutable);

    String agentPath;
    if (Platform.isMacOS) {
      agentPath = p.join(appDir, '..', 'Resources', 'flutter_assets',
          'assets', 'bin', 'touchifymouse_agent');
    } else {
      agentPath = p.join(appDir, 'assets', 'bin', 'touchifymouse_agent.exe');
    }

    debugPrint('[Agent] Starting: $agentPath');

    if (!File(agentPath).existsSync()) {
      debugPrint('[Agent] Binary not found at $agentPath — trying source');
      await _startFromSource();
      return;
    }

    try {
      _process = await Process.start(agentPath, [],
          mode: ProcessStartMode.normal);

      _process!.stdout.listen((bytes) {
        debugPrint('[Agent] ${String.fromCharCodes(bytes).trim()}');
      });
      _process!.stderr.listen((bytes) {
        debugPrint('[Agent ERR] ${String.fromCharCodes(bytes).trim()}');
      });

      debugPrint('[Agent] Started with PID ${_process!.pid}');
    } catch (e) {
      debugPrint('[Agent] Failed to start binary: $e');
      await _startFromSource();
    }
  }

  Future<void> _startFromSource() async {
    final scriptPath = p.join(
      Directory.current.path,
      '__agent_rebuild', 'touchifymouse_agent.py',
    );
    if (!File(scriptPath).existsSync()) {
      debugPrint('[Agent] Source script not found: $scriptPath');
      return;
    }
    try {
      _process = await Process.start('python3', [scriptPath]);
      _process!.stdout.listen((b) =>
          debugPrint('[Agent] ${String.fromCharCodes(b).trim()}'));
      _process!.stderr.listen((b) =>
          debugPrint('[Agent ERR] ${String.fromCharCodes(b).trim()}'));
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
