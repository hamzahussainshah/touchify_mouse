// lib/features/audio/services/mic_stream_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../trackpad/services/trackpad_socket_service.dart';

// ── Setup-required notification stream ──────────────────────────────────────
final micSetupRequiredProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  return MicStreamService.instance.onSetupRequired;
});

// ── Install-progress stream ───────────────────────────────────────────────────
// Emits status strings while the desktop auto-installs the audio driver.
final micInstallProgressProvider = StreamProvider<String>((ref) {
  return MicStreamService.instance.onInstallProgress;
});

// ── Active state ─────────────────────────────────────────────────────────────
final micStreamProvider =
    StateNotifierProvider<MicStreamNotifier, bool>((ref) => MicStreamNotifier());

class MicStreamNotifier extends StateNotifier<bool> {
  MicStreamNotifier() : super(false);

  Future<bool> startStreaming(dynamic socket, {int sampleRate = 44100}) async {
    final ok = await MicStreamService.instance.start(sampleRate: sampleRate);
    if (ok) state = true;
    return ok;
  }

  void stopStreaming() {
    MicStreamService.instance.stop();
    state = false;
  }

  // Called by MicStreamService when setup_required arrives
  void onSetupRequired() => state = false;
}

// ── Service ─────────────────────────────────────────────────────────────────
class MicStreamService {
  static final instance = MicStreamService._();
  MicStreamService._();

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<List<int>>? _sub;
  bool _active = false;

  bool get isActive => _active;

  final StreamController<Map<String, dynamic>> _setupRequiredCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onSetupRequired =>
      _setupRequiredCtrl.stream;

  // Called by TrackpadSocketService on audio_setup_required (for == 'mic')
  void handleSetupRequired(Map<String, dynamic> info) {
    debugPrint('[Mic] Setup required — notifying UI');
    stop();
    _setupRequiredCtrl.add(info);
  }

  // Called while agent is auto-installing the audio driver
  void handleInstallProgress(String message) {
    debugPrint('[Mic] Install progress: $message');
    _installProgressCtrl.add(message);
  }

  final StreamController<String> _installProgressCtrl =
      StreamController<String>.broadcast();
  Stream<String> get onInstallProgress => _installProgressCtrl.stream;

  Future<bool> start({int sampleRate = 44100}) async {
    if (_active) return true;

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

      // Tell desktop to prepare the virtual device and auto-switch Mac input
      TrackpadSocketService.instance.sendRaw(
        jsonEncode({'type': 'mic_start', 'sampleRate': sampleRate}),
      );

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
    if (_active) {
      // Tell desktop to restore Mac's original default input device
      TrackpadSocketService.instance.sendRaw(
        jsonEncode({'type': 'mic_stop'}),
      );
    }
    await _sub?.cancel();
    await _recorder.stop();
    _active = false;
    debugPrint('[Mic] Stopped');
  }
}
