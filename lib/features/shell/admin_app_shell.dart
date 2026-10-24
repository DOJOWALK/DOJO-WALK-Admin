import 'package:flutter/material.dart';

import '../../core/auth/admin_auth_repository.dart';
import '../../core/auth/admin_identity.dart';
import '../../core/theme/admin_theme.dart';
import '../dashboard/presentation/admin_dashboard_screen.dart';
import '../live_operations/presentation/live_operations_screen.dart';
import '../service_location/presentation/add_location_screen.dart';

class AdminAppShell extends StatefulWidget {
  const AdminAppShell({
    super.key,
    required this.identity,
    required this.authRepository,
  });

  final AdminIdentity identity;
  final AdminAuthRepository authRepository;

  @override
  State<AdminAppShell> createState() => _AdminAppShellState();
}

class _AdminAppShellState extends State<AdminAppShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.add_location_alt_outlined),
      selectedIcon: Icon(Icons.add_location_alt),
      label: 'Add Location',
    ),
    NavigationDestination(
      icon: Icon(Icons.radar_outlined),
      selectedIcon: Icon(Icons.radar),
      label: 'Live Operations',
    ),
  ];

  static const _screens = [
    AdminDashboardScreen(),
    AddLocationScreen(),
    LiveOperationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'DOJO WALK Admin',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (wide && widget.identity.displayName != null)
                Center(child: Text(widget.identity.displayName!)),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Sign out',
                onPressed: () async {
                  await widget.authRepository.signOut();
                },
                icon: const Icon(Icons.logout),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations
                      .map(
                        (destination) => NavigationRailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: Text(destination.label),
                        ),
                      )
                      .toList(),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Icon(
                      Icons.pets,
                      size: 30,
                      color: AdminTheme.brandOrange,
                    ),
                  ),
                ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  destinations: _destinations,
                ),
        );
      },
    );
  }
}
