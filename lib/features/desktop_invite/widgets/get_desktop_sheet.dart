import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../desktop_links.dart';
import '../services/desktop_invite_service.dart';

/// Bottom sheet: "Get the desktop app" — primary CTA is Share, with
/// Open and Copy as secondary actions.
class GetDesktopSheet extends StatelessWidget {
  const GetDesktopSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const GetDesktopSheet(),
      );

  Future<void> _share(BuildContext context) async {
    Navigator.of(context).pop();
    await DesktopInviteService.shareLink();
  }

  Future<void> _open(BuildContext context) async {
    Navigator.of(context).pop();
    await launchUrl(
      Uri.parse(DesktopLinks.primaryUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: DesktopLinks.primaryUrl),
    );
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: c.surface4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.desktop_mac,
                  color: AppColors.primaryLight,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get the desktop app',
                      style:
                          AppTextStyles.sectionTitle.copyWith(color: c.text1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Install on your Mac or Windows PC, then scan the QR.',
                      style: TextStyle(fontSize: 13, color: c.text3),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Primary CTA — Share
          ElevatedButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.ios_share, size: 20),
            label: const Text('Share download link'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send to email, WhatsApp, Messages, anywhere.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: c.text3),
          ),

          const SizedBox(height: 20),

          // Secondary actions
          Row(
            children: [
              Expanded(
                child: _secondaryBtn(
                  context,
                  icon: Icons.open_in_browser,
                  label: 'Open in browser',
                  onTap: () => _open(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _secondaryBtn(
                  context,
                  icon: Icons.copy,
                  label: 'Copy link',
                  onTap: () => _copy(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _secondaryBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final c = context.appColors;
    return Material(
      color: c.surface3,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: c.text2, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.text1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
