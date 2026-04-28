import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/connection_state_provider.dart';
import '../services/mic_stream_service.dart';
import '../services/speaker_stream_service.dart';
import '../../trackpad/services/trackpad_socket_service.dart';
import '../../../shared/widgets/app_toggle.dart';

class AudioHubPanel extends ConsumerWidget {
  const AudioHubPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMicActive     = ref.watch(micStreamProvider);
    final isSpeakerActive = ref.watch(speakerStreamProvider);
    // StreamProvider emits current state immediately (see connection_state_provider.dart),
    // so valueOrNull is non-null as soon as the widget is first built.
    // Fall back to the synchronous bool as an extra safety net.
    final isConnected = ref.watch(isSocketConnectedProvider).valueOrNull
        ?? TrackpadSocketService.instance.isConnected;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface1,
        border: Border(top: BorderSide(color: context.appColors.border)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Use both to replace your PC audio hardware completely.',
                    style: TextStyle(color: AppColors.warning, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildCard(
                  context: context,
                  title: 'Microphone',
                  subtitle: isMicActive ? 'Streaming to desktop' : 'Ready',
                  icon: Icons.mic,
                  color: AppColors.primary,
                  isActive: isMicActive,
                  onToggle: (val) {
                    if (val) {
                      if (!isConnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Not connected to desktop — connect first')));
                        return;
                      }
                      ref.read(micStreamProvider.notifier).startStreaming(null);
                    } else {
                      ref.read(micStreamProvider.notifier).stopStreaming();
                    }
                  },
                  onTapSettings: () => context.push('/microphone'),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  context: context,
                  title: 'Speaker',
                  subtitle: isSpeakerActive ? 'Receiving from desktop' : 'Ready',
                  icon: Icons.speaker,
                  color: AppColors.success,
                  isActive: isSpeakerActive,
                  onToggle: (val) {
                    if (val) {
                      if (!isConnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Not connected to desktop — connect first')));
                        return;
                      }
                      ref.read(speakerStreamProvider.notifier).startReceiving(null);
                    } else {
                      ref.read(speakerStreamProvider.notifier).stopReceiving();
                    }
                  },
                  onTapSettings: () => context.push('/speaker'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isActive,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTapSettings,
  }) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.08) : c.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.4) : c.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive ? color.withValues(alpha: 0.2) : c.surface3,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isActive ? color : c.text2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isActive ? color : c.text1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: c.text3),
                    ),
                  ],
                ),
              ),
              AppToggle(value: isActive, onChanged: onToggle),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.surface3,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: isActive
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => Container(
                              width: 3,
                              height: 10.0 + (index % 3) * 5,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              color: color,
                            ),
                          ),
                        )
                      : Container(height: 2, width: 40, color: c.surface4),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onTapSettings,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.surface3,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.settings_outlined, size: 18, color: c.text2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
