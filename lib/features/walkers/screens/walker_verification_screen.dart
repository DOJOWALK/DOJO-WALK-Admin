import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'walker_details_screen.dart';

const Color walkerVerificationOrange = Color(0xFFFF7900);
const Color walkerVerificationBackground = Color(0xFFFFFAF5);
const Color walkerVerificationText = Color(0xFF252525);

class WalkerVerificationScreen extends StatefulWidget {
  const WalkerVerificationScreen({super.key});

  @override
  State<WalkerVerificationScreen> createState() =>
      _WalkerVerificationScreenState();
}

class _WalkerVerificationScreenState
    extends State<WalkerVerificationScreen> {
  String _filter = 'all';
  String _search = '';

  static const List<_VerificationFilter> _filters = [
    _VerificationFilter(
      value: 'all',
      label: 'All',
    ),
    _VerificationFilter(
      value: 'pending',
      label: 'Pending',
    ),
    _VerificationFilter(
      value: 'under_review',
      label: 'Under Review',
    ),
    _VerificationFilter(
      value: 'approved',
      label: 'Approved',
    ),
    _VerificationFilter(
      value: 'rejected',
      label: 'Rejected',
    ),
  ];

  String _getStatus(Map<String, dynamic> data) {
    final verificationStatus = (data['verificationStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final status = (data['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (verificationStatus == 'rejected' ||
        status == 'rejected') {
      return 'rejected';
    }

    if (verificationStatus == 'verified' ||
        verificationStatus == 'approved' ||
        status == 'approved') {
      return 'approved';
    }

    if (verificationStatus == 'under_review' ||
        status == 'under_review') {
      return 'under_review';
    }

    return 'pending';
  }

  bool _isApplication(Map<String, dynamic> data) {
    // आवेदन की स्थिति वास्तविक Walker document से पढ़ी जाती है।
    // ऐसे Walker जिनका आवेदन submit नहीं हुआ है, उन्हें
    // Verification Applications में नहीं दिखाया जाएगा।
    final applicationSubmitted = data['applicationSubmitted'];

    if (applicationSubmitted == true) {
      return true;
    }

    // पुराने documents में applicationSubmitted न होने पर
    // status fields के आधार पर आवेदन पहचानें।
    final status = (data['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final verificationStatus = (data['verificationStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return status == 'pending' ||
        status == 'under_review' ||
        status == 'approved' ||
        status == 'rejected' ||
        verificationStatus == 'pending' ||
        verificationStatus == 'under_review' ||
        verificationStatus == 'verified' ||
        verificationStatus == 'approved' ||
        verificationStatus == 'rejected';
  }

  bool _matchesSearch(
    String uid,
    Map<String, dynamic> data,
  ) {
    if (_search.isEmpty) return true;

    final name = (data['name'] ?? data['fullName'] ?? '')
        .toString()
        .toLowerCase();

    final phone = (data['phoneNumber'] ?? data['phone'] ?? '')
        .toString()
        .toLowerCase();

    final email = (data['email'] ?? '')
        .toString()
        .toLowerCase();

    final walkerId = (data['walkerId'] ?? '')
        .toString()
        .toLowerCase();

    return name.contains(_search) ||
        phone.contains(_search) ||
        email.contains(_search) ||
        walkerId.contains(_search) ||
        uid.toLowerCase().contains(_search);
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterApplications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where((document) {
      final data = document.data();

      if (!_isApplication(data)) return false;

      final status = _getStatus(data);

      final matchesStatus =
          _filter == 'all' || status == _filter;

      final matchesSearch = _matchesSearch(
        document.id,
        data,
      );

      return matchesStatus && matchesSearch;
    }).toList();
  }

  Future<void> _openWalkerDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WalkerDetailsScreen(
          uid: document.id,
          walkerData: document.data(),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      case 'under_review':
        return Colors.blue;

      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'VERIFIED';

      case 'rejected':
        return 'REJECTED';

      case 'under_review':
        return 'UNDER REVIEW';

      default:
        return 'PENDING';
    }
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _search = value.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search name, phone, email or Walker ID',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: walkerVerificationOrange,
        ),
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  setState(() {
                    _search = '';
                  });
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE9E9E9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE9E9E9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: walkerVerificationOrange,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _filterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final selected = _filter == filter.value;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                setState(() {
                  _filter = filter.value;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? walkerVerificationOrange
                      : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected
                        ? walkerVerificationOrange
                        : const Color(0xFFE5E5E5),
                  ),
                ),
                child: Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : walkerVerificationText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _countSummary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    var pending = 0;
    var underReview = 0;
    var approved = 0;
    var rejected = 0;

    for (final document in documents) {
      final data = document.data();

      if (!_isApplication(data)) continue;

      switch (_getStatus(data)) {
        case 'pending':
          pending++;
          break;

        case 'under_review':
          underReview++;
          break;

        case 'approved':
          approved++;
          break;

        case 'rejected':
          rejected++;
          break;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _summaryItem(
            'Pending',
            pending,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryItem(
            'Review',
            underReview,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryItem(
            'Verified',
            approved,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryItem(
            'Rejected',
            rejected,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(
    String label,
    int count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFECECEC),
        ),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _walkerCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final name = (data['name'] ??
            data['fullName'] ??
            'Unnamed Walker')
        .toString();

    final phone = (data['phoneNumber'] ??
            data['phone'] ??
            'Phone not provided')
        .toString();

    final walkerId = (data['walkerId'] ?? '').toString();

    final status = _getStatus(data);

    final photoUrl = (data['photoUrl'] ??
            data['profilePhotoUrl'] ??
            '')
        .toString();

    final area = (data['area'] ??
            data['workArea'] ??
            data['city'] ??
            '')
        .toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => _openWalkerDetails(document),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: const Color(0xFFEAEAEA),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFFFF0E5),
                backgroundImage: photoUrl.startsWith('http')
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.startsWith('http')
                    ? null
                    : const Icon(
                        Icons.person_rounded,
                        color: walkerVerificationOrange,
                        size: 25,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: walkerVerificationText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    if (area.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        area,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                    if (walkerId.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'ID: $walkerId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusBadge(status),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.black45,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: walkerVerificationOrange.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                size: 32,
                color: walkerVerificationOrange,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No applications found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: walkerVerificationText,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Try another status filter or search term.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _filter = 'all';
                  _search = '';
                });
              },
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: walkerVerificationBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verification Applications',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: walkerVerificationText,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Review applications and open a Walker profile.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _searchField(),
                  const SizedBox(height: 13),
                  _filterBar(),
                  const SizedBox(height: 13),
                  StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('walkers')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const SizedBox.shrink();
                      }

                      if (!snapshot.hasData) {
                        return const SizedBox(
                          height: 68,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: walkerVerificationOrange,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      return _countSummary(
                        snapshot.data!.docs,
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              color: Color(0xFFEAEAEA),
            ),
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('walkers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Unable to load applications.\n'
                          'Check Admin permissions and Firestore Rules.\n\n'
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            height: 1.5,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: walkerVerificationOrange,
                      ),
                    );
                  }

                  final documents = snapshot.data?.docs ?? [];
                  final applications = _filterApplications(documents);

                  if (applications.isEmpty) {
                    return _emptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      24,
                    ),
                    itemCount: applications.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      return _walkerCard(applications[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationFilter {
  final String value;
  final String label;

  const _VerificationFilter({
    required this.value,
    required this.label,
  });
}
