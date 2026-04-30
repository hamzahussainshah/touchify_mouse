import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../services/connected_clients_provider.dart';

/// Left sidebar — navigation between dashboard / devices / scan / settings.
/// Uses the brand gradient for the active item, the new violet→pink palette
/// for everything else, and shows a live connected-phones count next to
/// "Devices" so the user knows the agent is alive.
class Sidebar extends ConsumerWidget {
  final String activeRoute;
  final void Function(String) onNavigate;

  const Sidebar({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientCount = ref.watch(connectedClientsProvider).length;

    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          _SectionLabel('OVERVIEW'),
          _NavItem(
            label: 'Dashboard',
            icon: Icons.grid_view_rounded,
            route: '/dashboard',
            active: activeRoute == '/dashboard',
            onTap: onNavigate,
          ),
          _NavItem(
            label: 'Devices',
            icon: Icons.devices_rounded,
            route: '/devices',
            active: activeRoute == '/devices',
            badge: clientCount > 0 ? '$clientCount' : null,
            onTap: onNavigate,
          ),
          _NavItem(
            label: 'Permissions',
            icon: Icons.verified_user_rounded,
            route: '/permissions',
            active: activeRoute == '/permissions',
            onTap: onNavigate,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Divider(height: 1, color: AppColors.border),
          ),

          _SectionLabel('CONNECT'),
          _NavItem(
            label: 'QR Connect',
            icon: Icons.qr_code_rounded,
            route: '/qr',
            active: activeRoute == '/qr',
            onTap: onNavigate,
          ),
          _NavItem(
            label: 'Network',
            icon: Icons.radar_rounded,
            route: '/scan',
            active: activeRoute == '/scan',
            onTap: onNavigate,
          ),

          const Spacer(),

          _NavItem(
            label: 'Settings',
            icon: Icons.settings_rounded,
            route: '/settings',
            active: activeRoute == '/settings',
            onTap: onNavigate,
          ),

          // Brand mark
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mouse, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TouchifyMouse',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text1,
                          letterSpacing: -0.1,
                        ),
                      ),
                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.text3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: AppColors.text3,
          ),
        ),
      );
}

class _NavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final String route;
  final bool active;
  final String? badge;
  final void Function(String) onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.active,
    required this.onTap,
    this.badge,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onTap(widget.route),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                gradient: active
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.22),
                          AppColors.accent.withValues(alpha: 0.10),
                        ],
                      )
                    : null,
                color: active
                    ? null
                    : (_hover
                        ? AppColors.surface2
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                border: active
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      )
                    : null,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          blurRadius: 12,
                          spreadRadius: -3,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: active ? AppColors.brandGradient : null,
                      color: active ? null : AppColors.surface3,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 15,
                      color: active ? Colors.white : AppColors.text2,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: active
                            ? AppColors.text1
                            : (_hover ? AppColors.text1 : AppColors.text2),
                      ),
                    ),
                  ),
                  if (widget.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 6,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                      child: Text(
                        widget.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
