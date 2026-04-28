import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../desktop_links.dart';
import '../services/desktop_invite_service.dart';

/// Bottom sheet: "Get the desktop app" with three options —
/// open in browser, copy link, or email it to yourself.
class GetDesktopSheet extends StatefulWidget {
  const GetDesktopSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const GetDesktopSheet(),
      );

  @override
  State<GetDesktopSheet> createState() => _GetDesktopSheetState();
}

class _GetDesktopSheetState extends State<GetDesktopSheet> {
  final _emailCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final ok = await launchUrl(
      Uri.parse(DesktopLinks.primaryUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) _toast('Could not open browser');
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: DesktopLinks.primaryUrl));
    if (mounted) _toast('Link copied to clipboard');
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final err = await DesktopInviteService.sendDownloadLink(_emailCtrl.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (err == null) {
      _toast('Sent! Check your email.');
      Navigator.of(context).pop();
    } else {
      _toast(err);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.surface4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.desktop_mac,
                      color: AppColors.primaryLight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Get the desktop app',
                          style: AppTextStyles.sectionTitle
                              .copyWith(color: c.text1)),
                      const SizedBox(height: 2),
                      Text(
                        'Install on your Mac or Windows PC, then scan the QR.',
                        style: TextStyle(fontSize: 12, color: c.text3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: _quickBtn(
                    icon: Icons.open_in_browser,
                    label: 'Open',
                    onTap: _open,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickBtn(
                    icon: Icons.copy,
                    label: 'Copy link',
                    onTap: _copy,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: c.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or email it',
                      style: TextStyle(fontSize: 11, color: c.text3)),
                ),
                Expanded(child: Divider(color: c.border)),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(color: c.text1),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: TextStyle(color: c.text3),
                filled: true,
                fillColor: c.surface3,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.alternate_email, color: c.text3),
              ),
              onSubmitted: (_) => _sending ? null : _send(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Email me the link'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickBtn({
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
              Icon(icon, color: AppColors.primaryLight),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
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
