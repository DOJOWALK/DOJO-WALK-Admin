import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'walker_details_screen.dart';

const Color wmOrange = Color(0xFFFF7900);
const Color wmBackground = Color(0xFFFFFAF5);
const Color wmText = Color(0xFF292524);
const Color wmMuted = Color(0xFF78716C);
const Color wmBorder = Color(0xFFE7E5E4);
const Color wmGreen = Color(0xFF15803D);
const Color wmRed = Color(0xFFB91C1C);

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

  String _selectedTab = 'Available';

  static const List<String> _tabLabels = [
    'Available',
    'Running',
    'Verification',
    'Rejected',
    'All Walkers',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _value(dynamic value) {
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
      final result = _value(value);

      if (result.isNotEmpty) {
        return result;
      }
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

  String _normalizedStatus(Map<String, dynamic> data) {
    final status = _value(data['status']).toLowerCase();
    final verification =
        _value(data['verificationStatus']).toLowerCase();

    // Rejection has priority over any stale approval field.
    if (status == 'rejected' || verification == 'rejected') {
      return 'rejected';
    }

    if (status == 'suspended') {
      return 'suspended';
    }

    if (status == 'left' || status == 'inactive') {
      return status;
    }

    if (verification == 'correction_required' ||
        status == 'correction_required') {
      return 'correction_required';
    }

    if (verification == 'under_review' ||
        status == 'under_review') {
      return 'under_review';
    }

    if (verification == 'pending' || status == 'pending') {
      return 'pending';
    }

    if (verification == 'verified' ||
        data['isApproved'] == true ||
        status == 'approved') {
      return data['isActive'] == true ? 'active' : 'verified';
    }

    return status.isEmpty ? 'unknown' : status;
  }

  String _status(Map<String, dynamic> data) {
    switch (_normalizedStatus(data)) {
      case 'active':
        return 'Active';

      case 'verified':
        return 'Verified';

      case 'approved':
        return 'Approved';

      case 'running':
      case 'in_progress':
      case 'active_walk':
      case 'walking':
      case 'walk_started':
        return 'Running';

      case 'pending':
        return 'Pending';

      case 'under_review':
        return 'Under Review';

      case 'correction_required':
        return 'Correction Required';

      case 'rejected':
        return 'Rejected';

      case 'suspended':
        return 'Suspended';

      case 'inactive':
        return 'Inactive';

      case 'left':
        return 'Left';

      default:
        return 'Unknown';
    }
  }

  bool _isRejected(Map<String, dynamic> data) {
    return _normalizedStatus(data) == 'rejected';
  }

  bool _isVerified(Map<String, dynamic> data) {
    return _value(data['verificationStatus']).toLowerCase() ==
            'verified' ||
        data['isApproved'] == true;
  }

  bool _isApplication(Map<String, dynamic> data) {
    final status = _normalizedStatus(data);

    if (data['applicationSubmitted'] != true) {
      return false;
    }

    // Rejected applications belong only in the Rejected tab.
    if (status == 'rejected' ||
        status == 'suspended' ||
        status == 'inactive' ||
        status == 'left') {
      return false;
    }

    // Already-approved walkers should not appear in Verification.
    if (_isVerified(data)) {
      return false;
    }

    // Keep submitted applications that need review or correction.
    return status == 'pending' ||
        status == 'under_review' ||
        status == 'correction_required';
  }

  bool _isRunningBooking(Map<String, dynamic> data) {
    return {
      'in_progress',
      'active_walk',
      'walking',
      'walk_started',
    }.contains(_value(data['status']).toLowerCase());
  }

  bool _isAvailable(
    Map<String, dynamic> data,
    String uid,
    Set<String> runningWalkerIds,
  ) {
    final status = _normalizedStatus(data);

    return _isVerified(data) &&
        data['isActive'] == true &&
        status != 'rejected' &&
        status != 'suspended' &&
        status != 'inactive' &&
        status != 'left' &&
        !runningWalkerIds.contains(uid);
  }

  bool _matchesSearch(
    Map<String, dynamic> data,
    String uid,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return true;

    // Search identity and contact details only.
    final searchable = [
      _name(data),
      _phone(data),
      _value(data['email']),
      _value(data['walkerId']),
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
            color: wmOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.groups_outlined,
            color: wmOrange,
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
                  color: wmText,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage walkers and applications',
                style: TextStyle(
                  color: wmMuted,
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
    return SizedBox(
      height: 46,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 13,
          color: wmText,
        ),
        decoration: InputDecoration(
          hintText: 'Search name, phone or Walker ID',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: wmMuted,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: wmOrange,
            size: 21,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                  ),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(
              color: wmBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(
              color: wmBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(
              color: wmOrange,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabLabels.map((tab) {
          final selected = _selectedTab == tab;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: selected ? wmOrange : Colors.white,
                  border: Border.all(
                    color: selected ? wmOrange : wmBorder,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    color: selected ? Colors.white : wmText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusBadge(String status) {
    late final Color foreground;
    late final Color background;

    switch (status) {
      case 'Active':
        foreground = const Color(0xFF166534);
        background = const Color(0xFFDCFCE7);
        break;

      case 'Running':
        foreground = const Color(0xFF9A3412);
        background = const Color(0xFFFFEDD5);
        break;

      case 'Verified':
      case 'Approved':
        foreground = const Color(0xFF1D4ED8);
        background = const Color(0xFFDBEAFE);
        break;

      case 'Rejected':
      case 'Suspended':
        foreground = wmRed;
        background = const Color(0xFFFEE2E2);
        break;

      case 'Correction Required':
        foreground = const Color(0xFF6D28D9);
        background = const Color(0xFFEDE9FE);
        break;

      case 'Inactive':
      case 'Left':
        foreground = wmMuted;
        background = const Color(0xFFF5F5F4);
        break;

      default:
        foreground = const Color(0xFF92400E);
        background = const Color(0xFFFEF3C7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _walkerCard({
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
    required bool running,
  }) {
    final data = document.data();

    final photoUrl = _firstValue([
      data['photoUrl'],
      data['profilePhotoUrl'],
    ]);

    final status = running ? 'Running' : _status(data);

    final phone = _phone(data);

    final subtitle = phone.isEmpty
        ? 'Walker ID: ${document.id}'
        : phone;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openDetails(document),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 12,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    wmOrange.withValues(alpha: 0.12),
                backgroundImage: photoUrl.isEmpty
                    ? null
                    : NetworkImage(photoUrl),
                child: photoUrl.isEmpty
                    ? const Icon(
                        Icons.person_outline,
                        color: wmOrange,
                        size: 25,
                      )
                    : null,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name(data),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: wmText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: wmMuted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'ID: ${document.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: wmMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _statusBadge(status),
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.chevron_right,
                      size: 19,
                      color: wmMuted,
                    ),
                  ],
                ),
              ),
            ],
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
        border: Border.all(color: wmBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 39,
            color: wmMuted,
          ),
          SizedBox(height: 10),
          Text(
            'No walkers found',
            style: TextStyle(
              color: wmText,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Search बदलें या दूसरे tab में देखें।',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: wmMuted,
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
            color: wmRed,
            size: 30,
          ),
          const SizedBox(height: 9),
          const Text(
            'Walker data load नहीं हुआ',
            style: TextStyle(
              color: wmText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: wmMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
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
                color: wmOrange,
              ),
            ),
          );
        }

        final walkers = walkerSnapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .snapshots(),
          builder: (context, bookingSnapshot) {
            if (bookingSnapshot.hasError) {
              return _errorState(bookingSnapshot.error!);
            }

            final runningWalkerIds = <String>{};

            for (final booking
                in bookingSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[]) {
              final data = booking.data();

              if (_isRunningBooking(data)) {
                final walkerId = _value(data['walkerId']);

                if (walkerId.isNotEmpty) {
                  runningWalkerIds.add(walkerId);
                }
              }
            }

            final filteredWalkers = walkers.where((walker) {
              final data = walker.data();

              if (!_matchesSearch(data, walker.id)) {
                return false;
              }

              switch (_selectedTab) {
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
                  .compareTo(
                    _name(b.data()).toLowerCase(),
                  );
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchBox(),
                const SizedBox(height: 12),
                _tabs(),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedTab,
                        style: const TextStyle(
                          color: wmText,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${filteredWalkers.length} walkers',
                      style: const TextStyle(
                        color: wmMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                if (filteredWalkers.isEmpty)
                  _emptyState()
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: wmBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (int index = 0;
                            index < filteredWalkers.length;
                            index++) ...[
                          _walkerCard(
                            document: filteredWalkers[index],
                            running: runningWalkerIds.contains(
                              filteredWalkers[index].id,
                            ),
                          ),
                          if (index < filteredWalkers.length - 1)
                            const Divider(
                              height: 1,
                              color: wmBorder,
                            ),
                        ],
                      ],
                    ),
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
      backgroundColor: wmBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'DOJO WALK Admin',
          style: TextStyle(
            color: wmText,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: wmText),
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 18),
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
