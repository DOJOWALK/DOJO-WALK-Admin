import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  String? _selectedVerificationUid;
  bool _processingVerification = false;

  static const List<String> _tabLabels = [
    'Available',
    'Running',
    'Verification',
    'All Walkers',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
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
    return _firstValue([
      data['fullName'],
      data['name'],
      data['displayName'],
    ]).isEmpty
        ? 'Unnamed Walker'
        : _firstValue([
            data['fullName'],
            data['name'],
            data['displayName'],
          ]);
  }

  String _phone(Map<String, dynamic> data) {
    return _firstValue([
      data['phone'],
      data['phoneNumber'],
      data['mobile'],
    ]);
  }

  String _status(Map<String, dynamic> data) {
    final status = _value(data['status']).toLowerCase();

    final verification =
        _value(data['verificationStatus']).toLowerCase();

    if (status == 'suspended') {
      return 'Suspended';
    }

    if (status == 'rejected' || verification == 'rejected') {
      return 'Rejected';
    }

    if (verification == 'verified' || data['isApproved'] == true) {
      return data['isActive'] == true ? 'Active' : 'Verified';
    }

    if (status == 'under_review' ||
        verification == 'under_review') {
      return 'Under Review';
    }

    if (status == 'pending' || verification == 'pending') {
      return 'Pending';
    }

    if (status == 'approved') {
      return 'Approved';
    }

    return status.isEmpty ? 'Unknown' : status;
  }

  bool _isVerified(Map<String, dynamic> data) {
    return _value(data['verificationStatus']).toLowerCase() ==
            'verified' ||
        data['isApproved'] == true;
  }

  bool _isApplication(Map<String, dynamic> data) {
    final status = _value(data['status']).toLowerCase();

    final verification =
        _value(data['verificationStatus']).toLowerCase();

    return data['applicationSubmitted'] == true &&
        !_isVerified(data) &&
        status != 'suspended' &&
        (status == 'under_review' ||
            status == 'pending' ||
            status == 'rejected' ||
            verification == 'pending' ||
            verification == 'under_review' ||
            verification == 'rejected');
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
    return _isVerified(data) &&
        data['isActive'] == true &&
        _value(data['status']).toLowerCase() != 'suspended' &&
        !runningWalkerIds.contains(uid);
  }

  bool _matchesSearch(
    Map<String, dynamic> data,
    String uid,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return true;
    }

    // Search only by walker identity and contact details.
    // Service area/location is intentionally excluded.
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

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _updateVerification({
    required String uid,
    required bool approve,
  }) async {
    if (_processingVerification) return;

    final action = approve ? 'Verify' : 'Reject';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$action Walker?'),
          content: Text(
            approve
                ? 'क्या आप इस Walker के KYC documents verify करना चाहते हैं?'
                : 'क्या आप इस Walker का application reject करना चाहते हैं?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: approve ? wmGreen : wmRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(action),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processingVerification = true;
    });

    try {
      final ref = FirebaseFirestore.instance
          .collection('walkers')
          .doc(uid);

      final snapshot = await ref.get();

      if (!snapshot.exists) {
        _showMessage('Walker application नहीं मिला।');
        return;
      }

      final data = snapshot.data() ?? <String, dynamic>{};

      final status = _value(data['status']).toLowerCase();

      final verification =
          _value(data['verificationStatus']).toLowerCase();

      if (data['applicationSubmitted'] != true) {
        _showMessage('यह application submit नहीं हुआ है।');
        return;
      }

      if (_isVerified(data)) {
        _showMessage('यह Walker पहले से verified है।');
        return;
      }

      if (status == 'suspended') {
        _showMessage(
          'Suspended Walker को इस स्क्रीन से verify नहीं किया जा सकता।',
        );
        return;
      }

      if (approve &&
          status != 'under_review' &&
          verification != 'under_review') {
        _showMessage(
          'Application Under Review स्थिति में नहीं है।',
        );
        return;
      }

      await ref.update({
        'verificationStatus': approve ? 'verified' : 'rejected',
        'status': approve ? 'approved' : 'rejected',
        'isApproved': approve,
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _selectedVerificationUid = null;
      });

      _showMessage(
        approve
            ? 'KYC verified. Walker अभी inactive रहेगा।'
            : 'Walker application rejected.',
      );
    } on FirebaseException catch (error) {
      _showMessage(
        'Update नहीं हुआ: ${error.message ?? error.code}',
      );
    } catch (error) {
      _showMessage('Update नहीं हुआ: $error');
    } finally {
      if (mounted) {
        setState(() {
          _processingVerification = false;
        });
      }
    }
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: wmOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.groups_outlined,
            color: wmOrange,
            size: 25,
          ),
        ),
        const SizedBox(width: 11),
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
        onChanged: (_) {
          setState(() {
            _selectedVerificationUid = null;
          });
        },
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

                    setState(() {
                      _selectedVerificationUid = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: wmBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: wmBorder),
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

  Widget _statistics({
    required int available,
    required int running,
    required int verification,
    required int total,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: wmBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _statItem(
            'Available',
            available,
            Icons.check_circle_outline,
            wmGreen,
          ),
          _statDivider(),
          _statItem(
            'Running',
            running,
            Icons.directions_walk,
            wmOrange,
          ),
          _statDivider(),
          _statItem(
            'Verification',
            verification,
            Icons.fact_check_outlined,
            const Color(0xFF1D4ED8),
          ),
          _statDivider(),
          _statItem(
            'All',
            total,
            Icons.groups_outlined,
            wmText,
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 5),
          Text(
            '$count',
            style: const TextStyle(
              color: wmText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: wmMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 47,
      color: wmBorder,
    );
  }

  Widget _tabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabLabels.map((tab) {
          final selected = _selectedTab == tab;

          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                  _selectedVerificationUid = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
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

    final isVerification = _selectedTab == 'Verification';

    final selected =
        _selectedVerificationUid == document.id;

    final phone = _phone(data);

    final subtitle = phone.isEmpty
        ? 'Walker ID: ${document.id}'
        : phone;

    return Material(
      color: selected ? const Color(0xFFFFF1E5) : Colors.white,
      child: InkWell(
        onTap: () {
          if (isVerification) {
            setState(() {
              _selectedVerificationUid =
                  selected ? null : document.id;
            });
          } else {
            _openDetails(document);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 12,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: wmOrange.withValues(alpha: 0.12),
                backgroundImage:
                    photoUrl.isEmpty ? null : NetworkImage(photoUrl),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusBadge(status),
                  const SizedBox(height: 6),
                  Icon(
                    isVerification
                        ? selected
                            ? Icons.expand_less
                            : Icons.expand_more
                        : Icons.chevron_right,
                    size: 19,
                    color: wmMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: wmMuted,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: wmText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentPreview(
    String title,
    String storagePath,
  ) {
    if (storagePath.trim().isEmpty) {
      return Container(
        width: 145,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: wmBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              color: wmMuted,
              size: 27,
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: wmText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Document path missing',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: wmMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 145,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: wmBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 110,
            child: FutureBuilder<String>(
              future: FirebaseStorage.instance
                  .ref()
                  .child(storagePath)
                  .getDownloadURL(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: wmOrange,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: wmMuted,
                            size: 25,
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Preview unavailable',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: wmMuted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final imageUrl = snapshot.data!;

                return InkWell(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) {
                        return Dialog(
                          backgroundColor: Colors.white,
                          child: InteractiveViewer(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                return const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'Image could not be loaded.',
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: wmMuted,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: wmText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationPanel(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final currentAddress = _asMap(data['currentAddress']);
    final kyc = _asMap(data['kyc']);
    final selfie = _asMap(kyc['selfie']);
    final documents = _asMap(kyc['documents']);

    final aadhaarFront = _asMap(documents['aadhaar_front']);
    final aadhaarBack = _asMap(documents['aadhaar_back']);
    final panCard = _asMap(documents['pan_card']);

    final address = [
      currentAddress['houseNumber'],
      currentAddress['street'],
      currentAddress['landmark'],
      currentAddress['city'],
      currentAddress['state'],
      currentAddress['pinCode'],
    ].map(_value).where((part) => part.isNotEmpty).join(', ');

    final status = _status(data);

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: wmBackground,
        border: Border.all(
          color: wmOrange.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'KYC Application Review',
                  style: TextStyle(
                    color: wmText,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 13),
          const Text(
            'Personal Details',
            style: TextStyle(
              color: wmText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          _infoRow('Full name', _name(data)),
          _infoRow('Phone', _phone(data)),
          _infoRow('Email', _value(data['email'])),
          _infoRow('Gender', _value(data['gender'])),
          _infoRow('Date of birth', _value(data['dateOfBirth'])),
          _infoRow('Address', address),
          _infoRow(
            'Travel mode',
            _value(data['travelMode']),
          ),
          const SizedBox(height: 5),
          const Text(
            'KYC Documents',
            style: TextStyle(
              color: wmText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _documentPreview(
                'Selfie',
                _value(selfie['storagePath']),
              ),
              _documentPreview(
                'Aadhaar Front',
                _value(aadhaarFront['storagePath']),
              ),
              _documentPreview(
                'Aadhaar Back',
                _value(aadhaarBack['storagePath']),
              ),
              _documentPreview(
                'PAN Card',
                _value(panCard['storagePath']),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_processingVerification)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  color: wmOrange,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _updateVerification(
                        uid: document.id,
                        approve: false,
                      );
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 17,
                    ),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: wmRed,
                      side: const BorderSide(color: wmRed),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: status == 'Rejected'
                        ? null
                        : () {
                            _updateVerification(
                              uid: document.id,
                              approve: true,
                            );
                          },
                    icon: const Icon(
                      Icons.verified_outlined,
                      size: 17,
                    ),
                    label: const Text('Verify & Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: wmGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          const Text(
            'Verification के बाद Walker inactive रहेगा; activation अलग से करना होगा।',
            style: TextStyle(
              color: wmMuted,
              fontSize: 10,
            ),
          ),
        ],
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
        border: Border.all(color: const Color(0xFFFECACA)),
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

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
              final data = booking.data();

              if (_isRunningBooking(data)) {
                final walkerId = _value(data['walkerId']);

                if (walkerId.isNotEmpty) {
                  runningWalkerIds.add(walkerId);
                }
              }
            }

            final availableCount = walkers.where((walker) {
              return _isAvailable(
                walker.data(),
                walker.id,
                runningWalkerIds,
              );
            }).length;

            final runningCount = runningWalkerIds.length;

            final verificationCount = walkers
                .where((walker) => _isApplication(walker.data()))
                .length;

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

                case 'All Walkers':
                  return true;

                default:
                  return true;
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
                _statistics(
                  available: availableCount,
                  running: runningCount,
                  verification: verificationCount,
                  total: walkers.length,
                ),
                const SizedBox(height: 14),
                _searchBox(),
                const SizedBox(height: 12),
                _tabs(),
                const SizedBox(height: 12),
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
                const SizedBox(height: 8),
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
                          if (_selectedTab == 'Verification' &&
                              _selectedVerificationUid ==
                                  filteredWalkers[index].id)
                            _verificationPanel(
                              filteredWalkers[index],
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
            final maxWidth =
                constraints.maxWidth > 1000 ? 1000.0 : 1000.0;

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: maxWidth,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
