import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../services/speaker_stream_service.dart';
import '../widgets/waveform_visualizer.dart';
import '../widgets/eq_visualizer.dart';
import '../../trackpad/services/trackpad_socket_service.dart';

class SpeakerScreen extends ConsumerStatefulWidget {
  const SpeakerScreen({super.key});

  @override
  ConsumerState<SpeakerScreen> createState() => _SpeakerScreenState();
}

class _SpeakerScreenState extends ConsumerState<SpeakerScreen> {
  bool stereoOutput = true;
  bool lowLatency = true;
  String currentEq = 'Flat';

  void _showMacAudioSetupInfo() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface2,
      title: const Text('One-time Mac Setup', style: TextStyle(color: AppColors.text1)),
      content: const Text(
        'To route Mac audio to your phone:\n\n'
        '1. Install BlackHole (free): brew install blackhole-2ch\n'
        '2. In Mac Sound settings → Output → select BlackHole 2ch\n'
        '3. Mac audio will now play through your phone.\n\n'
        'To hear both Mac speakers AND phone, create a Multi-Output Device in Audio MIDI Setup.',
        style: TextStyle(color: AppColors.text2, fontSize: 13),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
      ],
    ));
  }

  void _toggleSpeaker(bool isReceiving) async {
    if (isReceiving) {
      ref.read(speakerStreamProvider.notifier).stopReceiving();
    } else {
      final socket = TrackpadSocketService.instance.tcpSocket;
      if (socket == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not connected to desktop')));
        return;
      }
      _showMacAudioSetupInfo();
      await ref.read(speakerStreamProvider.notifier).startReceiving(socket);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReceiving = ref.watch(speakerStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Speaker'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        _toggleSpeaker(isReceiving);
                      },
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isReceiving ? AppColors.success.withOpacity(0.1) : AppColors.surface2,
                          border: Border.all(
                            color: isReceiving ? AppColors.success : AppColors.border,
                            width: 2,
                          ),
                          boxShadow: isReceiving ? [
                            BoxShadow(color: AppColors.success.withOpacity(0.35), blurRadius: 40, spreadRadius: 10),
                          ] : null,
                        ),
                        child: Icon(
                          Icons.speaker,
                          size: 60,
                          color: isReceiving ? AppColors.success : AppColors.text3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  WaveformVisualizer(
                    isRecording: isReceiving,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 48),
                  
                  // Settings
                  Text('Output Processing', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 16),
                  _buildToggleRow('Stereo Output', stereoOutput, (v) => setState(() => stereoOutput = v)),
                  _buildToggleRow('Low Latency Mode', lowLatency, (v) => setState(() => lowLatency = v)),
                  
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Equalizer', style: AppTextStyles.sectionLabel),
                      const SizedBox(width: 60, child: EqVisualizer()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildEqChip('Bass Boost'),
                      _buildEqChip('Flat'),
                      _buildEqChip('Voice'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(String title, bool val, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.bodyText),
          AppToggle(value: val, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildEqChip(String label) {
    final isSelected = currentEq == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => currentEq = label),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.success.withOpacity(0.1) : AppColors.surface2,
            border: Border.all(color: isSelected ? AppColors.success : AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.success : AppColors.text2,
            ),
          ),
        ),
      ),
    );
  }
}

