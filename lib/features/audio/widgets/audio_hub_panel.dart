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
    // Reactive: true as soon as TCP socket connects
    final isConnected     = ref.watch(isSocketConnectedProvider).valueOrNull ?? false;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.2)),
            ),
            child: Row(
              children: const [
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
                      final socket = TrackpadSocketService.instance.tcpSocket;
                      if (socket != null) {
                        ref.read(micStreamProvider.notifier).startStreaming(socket);
                      }
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
                      final socket = TrackpadSocketService.instance.tcpSocket;
                      if (socket != null) {
                        ref.read(speakerStreamProvider.notifier).startReceiving(socket);
                      }
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.08) : AppColors.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color.withOpacity(0.4) : AppColors.border,
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
                  color: isActive ? color.withOpacity(0.2) : AppColors.surface3,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isActive ? color : AppColors.text2),
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
                        color: isActive ? color : AppColors.text1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: AppColors.text3),
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
                    color: AppColors.surface3,
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
                                  )),
                        )
                      : Container(
                          height: 2,
                          width: 40,
                          color: AppColors.surface4,
                        ),
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
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_outlined, size: 18, color: AppColors.text2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
