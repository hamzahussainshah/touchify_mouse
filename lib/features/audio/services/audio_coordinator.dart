import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mic_stream_service.dart';
import 'speaker_stream_service.dart';

/// Reason an automatic disable happened — surfaces a snackbar explaining
/// what changed without being intrusive.
enum AutoOffReason { mutex, timeout }

class AudioAutoEvent {
  final String channel; // 'mic' | 'speaker'
  final AutoOffReason reason;
  const AudioAutoEvent(this.channel, this.reason);
}

/// Coordinates mic + speaker so they're mutually exclusive (both running
/// at once produces a feedback loop) and auto-disables either after an
/// inactivity timeout (defaults to 15 minutes — a common default that's
/// long enough for a real call but short enough to save battery if the
/// user forgets).
final audioCoordinatorProvider = Provider<AudioCoordinator>((ref) {
  final coord = AudioCoordinator(ref);
  ref.onDispose(coord.dispose);
  return coord;
});

/// Stream of auto-off events for the UI to show snackbars / toasts.
final audioAutoEventProvider = StreamProvider<AudioAutoEvent>(
  (ref) => ref.watch(audioCoordinatorProvider).events,
);

class AudioCoordinator {
  AudioCoordinator(this._ref);

  final Ref _ref;
  Timer? _micTimer;
  Timer? _speakerTimer;
  final _events = StreamController<AudioAutoEvent>.broadcast();
  Stream<AudioAutoEvent> get events => _events.stream;

  /// Auto-disable timeout. 15 minutes is the default; users can flip it
  /// down to 10 from settings later if we expose the option.
  static const Duration autoOffAfter = Duration(minutes: 15);

  /// Turn the mic on (off). When turning on, also forces the speaker off
  /// to avoid feedback. Returns true on success, false when the user is
  /// not connected (caller should show a snackbar).
  Future<void> setMic(bool enable) async {
    final mic = _ref.read(micStreamProvider.notifier);
    if (enable) {
      // Mutex: kill the speaker first so we don't loop audio back.
      if (_ref.read(speakerStreamProvider)) {
        _ref.read(speakerStreamProvider.notifier).stopReceiving();
        _cancelSpeakerTimer();
        _emit('speaker', AutoOffReason.mutex);
      }
      await mic.startStreaming(null);
      _armMicTimer();
    } else {
      mic.stopStreaming();
      _cancelMicTimer();
    }
  }

  Future<void> setSpeaker(bool enable) async {
    final spk = _ref.read(speakerStreamProvider.notifier);
    if (enable) {
      if (_ref.read(micStreamProvider)) {
        _ref.read(micStreamProvider.notifier).stopStreaming();
        _cancelMicTimer();
        _emit('mic', AutoOffReason.mutex);
      }
      await spk.startReceiving(null);
      _armSpeakerTimer();
    } else {
      spk.stopReceiving();
      _cancelSpeakerTimer();
    }
  }

  // ── Timers ──────────────────────────────────────────────────────────────
  void _armMicTimer() {
    _cancelMicTimer();
    _micTimer = Timer(autoOffAfter, () {
      // Re-check at fire time — user may have already turned it off.
      if (!_ref.read(micStreamProvider)) return;
      _ref.read(micStreamProvider.notifier).stopStreaming();
      _emit('mic', AutoOffReason.timeout);
      debugPrint('[AudioCoord] mic auto-off after ${autoOffAfter.inMinutes}m');
    });
  }

  void _armSpeakerTimer() {
    _cancelSpeakerTimer();
    _speakerTimer = Timer(autoOffAfter, () {
      if (!_ref.read(speakerStreamProvider)) return;
      _ref.read(speakerStreamProvider.notifier).stopReceiving();
      _emit('speaker', AutoOffReason.timeout);
      debugPrint('[AudioCoord] speaker auto-off after ${autoOffAfter.inMinutes}m');
    });
  }

  void _cancelMicTimer() {
    _micTimer?.cancel();
    _micTimer = null;
  }

  void _cancelSpeakerTimer() {
    _speakerTimer?.cancel();
    _speakerTimer = null;
  }

  void _emit(String channel, AutoOffReason reason) {
    if (_events.isClosed) return;
    _events.add(AudioAutoEvent(channel, reason));
  }

  void dispose() {
    _cancelMicTimer();
    _cancelSpeakerTimer();
    _events.close();
  }
}
