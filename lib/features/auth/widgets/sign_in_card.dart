import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class SignInCard extends ConsumerWidget {
  const SignInCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final controllerState = ref.watch(authControllerProvider);
    final isLoading = controllerState.isLoading;

    if (user != null) {
      return _SignedInCard(
        email: user.email ?? '',
        name: user.displayName ?? 'Signed in',
        photoUrl: user.photoURL,
        onSignOut: isLoading
            ? null
            : () => ref.read(authControllerProvider.notifier).signOut(),
      );
    }

    return _SignInCta(
      isLoading: isLoading,
      onSignIn: () async {
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
        final err = ref.read(authControllerProvider).error;
        if (err != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in failed: $err')),
          );
        }
      },
    );
  }
}

class _SignInCta extends StatelessWidget {
  const _SignInCta({required this.isLoading, required this.onSignIn});

  final bool isLoading;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle_outlined,
              color: AppColors.primaryLight, size: 32),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sign in to sync',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('Save your devices and connections',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: isLoading ? null : onSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({
    required this.email,
    required this.name,
    required this.photoUrl,
    required this.onSignOut,
  });

  final String email;
  final String name;
  final String? photoUrl;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage:
                photoUrl != null ? NetworkImage(photoUrl!) : null,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: photoUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(email,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white60),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          TextButton(
            onPressed: onSignOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
