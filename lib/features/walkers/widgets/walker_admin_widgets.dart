import 'package:flutter/material.dart';

const Color walkerAdminOrange = Color(0xFFFF7900);
const Color walkerAdminBackground = Color(0xFFFFFAF5);
const Color walkerAdminText = Color(0xFF292524);
const Color walkerAdminMuted = Color(0xFF78716C);
const Color walkerAdminBorder = Color(0xFFE7E5E4);

/// ===========================================================
/// WALKER MANAGEMENT TABS
/// ===========================================================

class WalkerAdminTabs extends StatelessWidget {
  const WalkerAdminTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = index == selectedIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? walkerAdminOrange
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected
                        ? walkerAdminOrange
                        : walkerAdminBorder,
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : walkerAdminText,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// ===========================================================
/// WALKER CARD
/// ===========================================================

class WalkerAdminCard extends StatelessWidget {
  const WalkerAdminCard({
    super.key,
    required this.name,
    required this.status,
    required this.onTap,
    this.phone,
    this.location,
    this.photoUrl,
    this.isActive,
    this.isRunning = false,
  });

  final String name;
  final String status;
  final String? phone;
  final String? location;
  final String? photoUrl;
  final bool? isActive;
  final bool isRunning;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
      case 'available':
        return const Color(0xFF15803D);

      case 'running':
      case 'walking':
      case 'active_walk':
        return const Color(0xFF2563EB);

      case 'rejected':
      case 'suspended':
      case 'inactive':
        return const Color(0xFFDC2626);

      case 'correction_required':
        return const Color(0xFFB45309);

      default:
        return const Color(0xFF78716C);
    }
  }

  String get _displayStatus {
    if (isRunning) return 'Running';

    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final safeName =
        name.trim().isEmpty ? 'Walker' : name.trim();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: walkerAdminBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WalkerAvatar(
                name: safeName,
                photoUrl: photoUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safeName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: walkerAdminText,
                      ),
                    ),
                    if (phone != null &&
                        phone!.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      _CardDetail(
                        icon: Icons.phone_outlined,
                        text: phone!,
                      ),
                    ],
                    if (location != null &&
                        location!.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      _CardDetail(
                        icon: Icons.location_on_outlined,
                        text: location!,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusBadge(
                          text: _displayStatus,
                          color: _statusColor,
                        ),
                        if (isActive != null)
                          _StatusBadge(
                            text: isActive! ? 'Active' : 'Inactive',
                            color: isActive!
                                ? const Color(0xFF15803D)
                                : const Color(0xFF78716C),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: walkerAdminMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===========================================================
/// WALKER AVATAR
/// ===========================================================

class _WalkerAvatar extends StatelessWidget {
  const _WalkerAvatar({
    required this.name,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';

    return CircleAvatar(
      radius: 27,
      backgroundColor: const Color(0xFFFFE8D2),
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      onBackgroundImageError: url.isNotEmpty
          ? (_, __) {}
          : null,
      child: url.isEmpty
          ? Text(
              name.isEmpty ? 'W' : name[0].toUpperCase(),
              style: const TextStyle(
                color: walkerAdminOrange,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            )
          : null,
    );
  }
}

/// ===========================================================
/// DETAILS SECTION CONTAINER
/// ===========================================================

class WalkerAdminSection extends StatelessWidget {
  const WalkerAdminSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: walkerAdminBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: walkerAdminOrange,
                ),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: walkerAdminText,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// ===========================================================
/// DETAILS INFORMATION ROW
/// ===========================================================

class WalkerAdminInfoRow extends StatelessWidget {
  const WalkerAdminInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String? value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: walkerAdminMuted,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: walkerAdminMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              displayValue == null || displayValue.isEmpty
                  ? 'Not provided'
                  : displayValue,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: walkerAdminText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===========================================================
/// KYC DOCUMENT LIST ITEM
/// ===========================================================

class WalkerAdminKycDocumentTile extends StatelessWidget {
  const WalkerAdminKycDocumentTile({
    super.key,
    required this.title,
    required this.onView,
    this.subtitle,
    this.isAvailable = true,
  });

  final String title;
  final String? subtitle;
  final bool isAvailable;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: walkerAdminBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: walkerAdminBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8D2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: walkerAdminOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: walkerAdminText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle ??
                      (isAvailable
                          ? 'Document submitted'
                          : 'Document not available'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: walkerAdminMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: isAvailable ? onView : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: walkerAdminOrange,
              side: const BorderSide(color: walkerAdminOrange),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

/// ===========================================================
/// STATUS BADGE
/// ===========================================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// ===========================================================
/// SMALL CARD DETAIL
/// ===========================================================

class _CardDetail extends StatelessWidget {
  const _CardDetail({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: walkerAdminMuted,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: walkerAdminMuted,
            ),
          ),
        ),
      ],
    );
  }
}
