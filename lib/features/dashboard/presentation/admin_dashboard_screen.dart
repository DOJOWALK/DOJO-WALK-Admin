import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.onOpenServiceLocation,
    required this.onOpenLiveOperations,
  });

  final VoidCallback onOpenServiceLocation;
  final VoidCallback onOpenLiveOperations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            return SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 16 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Company operations at a glance',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const _StatusNotice(
                    title: 'Fresh Admin UI foundation',
                    message:
                        'This new presentation layer is being built separately. '
                        'Live metrics and actions will be connected only after '
                        'their API, permissions and data contracts are verified.',
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: compact ? 1 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: compact ? 3.0 : 2.6,
                    children: [
                      _FeatureCard(
                        title: 'Service Location',
                        subtitle: 'States, cities, areas and verified boundaries',
                        icon: Icons.map_outlined,
                        onTap: onOpenServiceLocation,
                      ),
                      _FeatureCard(
                        title: 'Live Operations',
                        subtitle: 'Walk status and approximate walker location',
                        icon: Icons.near_me_outlined,
                        onTap: onOpenLiveOperations,
                      ),
                      const _FeatureCard(
                        title: 'Bookings',
                        subtitle: 'Booking state and verified payment status',
                        icon: Icons.calendar_month_outlined,
                      ),
                      const _FeatureCard(
                        title: 'Walkers / Partners',
                        subtitle: 'Availability, assignment and operational review',
                        icon: Icons.pets_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD2AD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: const Color(0xFFFF7900), size: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
