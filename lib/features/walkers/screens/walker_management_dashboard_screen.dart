import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/walker_admin_widgets.dart';
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

  int _selectedTab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';

    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    final result = value.toString().trim();

    if (result.isEmpty || result == 'null') {
      return '';
    }

    return result;
  }

  String _firstValue(List<dynamic> values) {
    for (final value in values) {
      final result = _stringValue(value);

      if (result.isNotEmpty) return result;
    }

    return '';
  }

  String _name(Map<String, dynamic> data) {
    final name = _firstValue([
      data['fullName'],
      data['name'],
      data['displayName'],
    ]);

    return name.isEmpty ? 'Unnamed Walker' : name;
  }

  String _phone(Map<String, dynamic> data) {
    return _firstValue([
      data['phone'],
      data['phoneNumber'],
      data['mobile'],
    ]);
  }

  String _location(Map<String, dynamic> data) {
    final parts = [
      data['area'],
      data['city'],
      data['state'],
    ]
        .map(_stringValue)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    return parts.join(', ');
  }

  String _normalizedStatus(Map<String, dynamic> data) {
    final status = _stringValue(data['status']).toLowerCase();
    final verification =
        _stringValue(data['verificationStatus']).toLowerCase();

    if (status == 'rejected' || verification == 'rejected') {
      return 'rejected';
    }

    if (status == 'suspended') return 'suspended';

    if (status == 'left' || status == 'inactive') {
      return status;
    }

    if (status == 'correction_required' ||
        verification == 'correction_required') {
      return 'correction_required';
    }

    if (status == 'under_review' ||
        verification == 'under_review') {
      return 'under_review';
    }

    if (status == 'pending' || verification == 'pending') {
      return 'pending';
    }

    if (verification == 'verified' ||
        data['isApproved'] == true ||
        status == 'approved') {
      return data['isActive'] == true ? 'active' : 'verified';
    }

    return status.isEmpty ? 'unknown' : status;
  }

  String _displayStatus(Map<String, dynamic> data) {
    switch (_normalizedStatus(data)) {
      case 'active':
        return 'Active';
      case 'verified':
        return 'Verified';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'suspended':
        return 'Suspended';
      case 'inactive':
        return 'Inactive';
      case 'left':
        return 'Left';
      case 'pending':
        return 'Pending';
      case 'under_review':
        return 'Under Review';
      case 'correction_required':
        return 'Correction Required';
      default:
        return 'Unknown';
    }
  }

  bool _isRejected(Map<String, dynamic> data) {
    return _normalizedStatus(data) == 'rejected';
  }

  bool _isVerified(Map<String, dynamic> data) {
    final verification =
        _stringValue(data['verificationStatus']).toLowerCase();

    return verification == 'verified' ||
        data['isApproved'] == true;
  }

  bool _isApplication(Map<String, dynamic> data) {
    if (data['applicationSubmitted'] != true) {
      return false;
    }

    final status = _normalizedStatus(data);

    if ({
      'rejected',
      'suspended',
      'inactive',
      'left',
    }.contains(status)) {
      return false;
    }

    if (_isVerified(data)) return false;

    return {
      'pending',
      'under_review',
      'correction_required',
    }.contains(status);
  }

  bool _isRunningBooking(Map<String, dynamic> data) {
    return {
      'in_progress',
      'active_walk',
      'walking',
      'walk_started',
    }.contains(
      _stringValue(data['status']).toLowerCase(),
    );
  }

  bool _isAvailable(
    Map<String, dynamic> data,
    String uid,
    Set<String> runningWalkerIds,
  ) {
    final status = _normalizedStatus(data);

    return _isVerified(data) &&
        data['isActive'] == true &&
        !{
          'rejected',
          'suspended',
          'inactive',
          'left',
        }.contains(status) &&
        !runningWalkerIds.contains(uid);
  }

  bool _matchesSearch(
    Map<String, dynamic> data,
    String uid,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return true;

    final searchable = [
      _name(data),
      _phone(data),
      _stringValue(data['email']),
      _stringValue(data['walkerId']),
      uid,
    ].join(' ').toLowerCase();

    return searchable.contains(query);
  }

  void _openDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> walker,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WalkerDetailsScreen(
          uid: walker.id,
          walkerData: walker.data(),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
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

  Widget _errorState(Object error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: _red,
            size: 30,
          ),
          const SizedBox(height: 9),
          const Text(
            'Walker data load नहीं हुआ',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _walkerList({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        walkers,
    required Set<String> runningWalkerIds,
  }) {
    if (walkers.isEmpty) return _emptyState();

    return Column(
      children: walkers.map((walker) {
        final data = walker.data();
        final running = runningWalkerIds.contains(walker.id);

        return WalkerAdminCard(
          name: _name(data),
          status: running ? 'running' : _displayStatus(data),
          phone: _phone(data).isEmpty ? null : _phone(data),
          location: _location(data).isEmpty
              ? null
              : _location(data),
          photoUrl: _firstValue([
            data['photoUrl'],
            data['profilePhotoUrl'],
          ]),
          isActive: data['isActive'] is bool
              ? data['isActive'] as bool
              : null,
          isRunning: running,
          onTap: () => _openDetails(walker),
        );
      }).toList(),
    );
  }

  Widget _content() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('walkers')
          .snapshots(),
      builder: (context, walkerSnapshot) {
        if (walkerSnapshot.hasError) {
          return _errorState(walkerSnapshot.error!);
        }

        if (walkerSnapshot.connectionState ==
                ConnectionState.waiting &&
            !walkerSnapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(
                color: _orange,
              ),
            ),
          );
        }

        final walkers = walkerSnapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .snapshots(),
          builder: (context, bookingSnapshot) {
            if (bookingSnapshot.hasError) {
              return _errorState(bookingSnapshot.error!);
            }

            if (bookingSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !bookingSnapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: _orange,
                  ),
                ),
              );
            }

            final runningWalkerIds = <String>{};

            for (final booking in bookingSnapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
              final data = booking.data();

              if (_isRunningBooking(data)) {
                final walkerId = _stringValue(data['walkerId']);

                if (walkerId.isNotEmpty) {
                  runningWalkerIds.add(walkerId);
                }
              }
            }

            final selectedTab = _tabs[_selectedTab];

            final filteredWalkers = walkers.where((walker) {
              final data = walker.data();

              if (!_matchesSearch(data, walker.id)) {
                return false;
              }

              switch (selectedTab) {
                case 'Available':
                  return _isAvailable(
                    data,
                    walker.id,
                    runningWalkerIds,
                  );

                case 'Running':
                  return runningWalkerIds.contains(walker.id);

                case 'Verification':
                  return _isApplication(data);

                case 'Rejected':
                  return _isRejected(data);

                case 'All Walkers':
                  return true;

                default:
                  return false;
              }
            }).toList();

            filteredWalkers.sort((a, b) {
              return _name(a.data())
                  .toLowerCase()
                  .compareTo(_name(b.data()).toLowerCase());
            });

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
