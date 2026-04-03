import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PythonAgentService {
  Process? _process;
  bool _isRunning = false;

  Future<void> start() async {
    if (_isRunning) return;
    try {
      final appSupport = await getApplicationSupportDirectory();
      final agentDir = Directory('${appSupport.path}/agent');
      if (!agentDir.existsSync()) {
        agentDir.createSync(recursive: true);
      }

      final executableFile = File('${agentDir.path}/touchifymouse_agent');
      
      // Always overwrite to ensure latest version is used
      final byteData = await rootBundle.load('assets/bin/touchifymouse_agent');
      await executableFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      
      // Make it executable
      if (Platform.isMacOS || Platform.isLinux) {
        await Process.run('chmod', ['+x', executableFile.path]);
      }

      print('Starting Python Agent at ${executableFile.path}...');
      _process = await Process.start(executableFile.path, []);
      _isRunning = true;

      _process!.stdout.listen((event) => print('[Agent]: ${String.fromCharCodes(event)}'));
      _process!.stderr.listen((event) => print('[Agent ERROR]: ${String.fromCharCodes(event)}'));
    } catch (e) {
      print('Failed to start python agent: $e');
    }
  }

  void stop() {
    if (_process != null) {
      _process!.kill();
      _process = null;
    }
    _isRunning = false;
  }
}

final pythonAgentService = PythonAgentService();
