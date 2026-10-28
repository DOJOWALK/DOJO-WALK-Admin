import 'package:flutter/material.dart';

import '../models/walker_admin_model.dart';
import '../services/walker_admin_service.dart';
import '../utils/walker_admin_helpers.dart';
import '../widgets/walker_admin_widgets.dart';
import '../../../utils/admin_error_classifier.dart';
import 'walker_details_screen.dart';

class WalkerManagementDashboardScreen extends StatefulWidget {
  const WalkerManagementDashboardScreen({super.key});

  @override
  State<WalkerManagementDashboardScreen> createState() =>
      _WalkerManagementDashboardScreenState();
}

class _WalkerManagementDashboardScreenState
    extends State<WalkerManagementDashboardScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final WalkerAdminService _service = WalkerAdminService();

  static const Color _orange = Color(0xFFFF7900);
  static const Color _background = Color(0xFFFFFAF5);
  static const Color _text = Color(0xFF292524);
  static const Color _muted = Color(0xFF78716C);
  static const Color _border = Color(0xFFE7E5E4);
  static const Color _red = Color(0xFFB91C1C);

  static const List<String> _tabs = [
    'Available',
    'Running',
    'Verification',
    'Rejected',
    'All Walkers',
  ];

  static const Set<String> _runningBookingStatuses = {
    'in_progress',
    'active_walk',
    'walking',
    'walk_started',
  };

  int _selectedTab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _name(WalkerAdminModel walker) {
    final name = walker.name.trim();
    return name.isEmpty ? 'Unnamed Walker' : name;
  }

  String _phone(WalkerAdminModel walker) {
    final phone = walker.phoneNumber?.trim() ?? '';
    return phone;
  }

  String _location(WalkerAdminModel walker) {
    return WalkerAdminHelpers.locationLabel(walker.rawData).trim();
  }

  String _photo(WalkerAdminModel walker) {
    return WalkerAdminHelpers.photoUrl(walker.rawData) ?? '';
  }

  bool _isRunningBooking(Map<String, dynamic> data) {
    final status = WalkerAdminHelpers.normalizeStatus(data['status']);
    return _runningBookingStatuses.contains(status);
  }

  bool _matchesSearch(WalkerAdminModel walker) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return true;

    final searchable = [
      walker.name,
      walker.phoneNumber ?? '',
      walker.email ?? '',
      walker.uid,
      walker.area,
      walker.city,
      walker.state,
    ].join(' ').toLowerCase();

    return searchable.contains(query);
  }

  void _openDetails(WalkerAdminModel walker) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WalkerDetailsScreen(
          uid: walker.uid,
          walkerData: walker.rawData,
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.groups_outlined,
            color: _orange,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Walker Management',
                style: TextStyle(
                  color: _text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage walkers and applications',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(
        fontSize: 13,
        color: _text,
      ),
      decoration: InputDecoration(
        hintText: 'Search name, phone or Walker ID',
        hintStyle: const TextStyle(
          fontSize: 12,
          color: _muted,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: _orange,
        ),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _orange,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 40,
            color: _muted,
          ),
          SizedBox(height: 10),
          Text(
            'No walkers found',
            style: TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Search बदलें या दूसरे tab में देखें।',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(Object? error) {
    final permissionDenied = isPermissionDeniedError(error);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: permissionDenied
              ? const Color(0xFFFFD2AC)
              : const Color(0xFFFECACA),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            permissionDenied ? Icons.lock_outline : Icons.error_outline,
            color: permissionDenied ? _orange : _red,
            size: 30,
          ),
          const SizedBox(height: 9),
          Text(
            permissionDenied
                ? 'Permission denied'
                : 'Walker data load नहीं हुआ',
            style: const TextStyle(
              color: _text,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            permissionDenied
                ? 'Your Admin role or assigned scope may not allow access to this walker or booking data. Ask an authorized administrator to review permissions.'
                : 'Connection और data access configuration जाँचें। No status has been changed.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _walkerList({
    required List<WalkerAdminModel> walkers,
    required Set<String> runningWalkerIds,
  }) {
    if (walkers.isEmpty) {
      return _emptyState();
    }

    return Column(
      children: walkers.map((walker) {
        final running = runningWalkerIds.contains(walker.uid);
        final phone = _phone(walker);
        final location = _location(walker);

        return WalkerAdminCard(
          name: _name(walker),
          status: running ? 'running' : walker.displayStatus,
          phone: phone.isEmpty ? null : phone,
          location: location.isEmpty ? null : location,
          photoUrl: _photo(walker),
          isActive: walker.isActive,
          isRunning: running,
          onTap: () => _openDetails(walker),
        );
      }).toList(),
    );
  }

  Widget _content() {
    return StreamBuilder<List<WalkerAdminModel>>(
      stream: _service.watchWalkers(),
      builder: (context, walkerSnapshot) {
        if (walkerSnapshot.hasError) {
          return _errorState(walkerSnapshot.error);
        }

        if (walkerSnapshot.connectionState == ConnectionState.waiting &&
            !walkerSnapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(color: _orange),
            ),
          );
        }

        final walkers = walkerSnapshot.data ?? <WalkerAdminModel>[];

        return StreamBuilder(
          stream: _service.watchBookings(),
          builder: (context, bookingSnapshot) {
            if (bookingSnapshot.hasError) {
              return _errorState(bookingSnapshot.error);
            }

            if (bookingSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !bookingSnapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _orange),
                ),
              );
            }

            final runningWalkerIds = <String>{};
            final bookings = bookingSnapshot.data?.docs ?? [];

            for (final booking in bookings) {
              final data = booking.data();

              if (!_isRunningBooking(data)) continue;

              final walkerId = WalkerAdminHelpers.firstString(
                data,
                ['walkerId'],
              );

              if (walkerId != null && walkerId.trim().isNotEmpty) {
                runningWalkerIds.add(walkerId.trim());
              }
            }

            final selectedTab = _tabs[_selectedTab];

            final filteredWalkers = walkers.where((walker) {
              if (!_matchesSearch(walker)) {
                return false;
              }

              switch (selectedTab) {
                case 'Available':
                  return walker.isEligibleForAvailability &&
                      !runningWalkerIds.contains(walker.uid);

                case 'Running':
                  return runningWalkerIds.contains(walker.uid);

                case 'Verification':
                  return walker.isUnderReview;

                case 'Rejected':
                  return walker.isRejected;

                case 'All Walkers':
                  return true;

                default:
                  return false;
              }
            }).toList();

            filteredWalkers.sort(
              (a, b) => _name(a)
                  .toLowerCase()
                  .compareTo(_name(b).toLowerCase()),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchBox(),
                const SizedBox(height: 14),
                WalkerAdminTabs(
                  tabs: _tabs,
                  selectedIndex: _selectedTab,
                  onChanged: (index) {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedTab,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${filteredWalkers.length} walkers',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _walkerList(
                  walkers: filteredWalkers,
                  runningWalkerIds: runningWalkerIds,
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'DOJO WALK Admin',
          style: TextStyle(
            color: _text,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: _text),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const maxWidth = 1000.0;

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: constraints.maxWidth > maxWidth
                    ? maxWidth
                    : constraints.maxWidth,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 20),
                      _content(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
