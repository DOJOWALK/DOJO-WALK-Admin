import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

const Color wdOrange = Color(0xFFFF7900);
const Color wdBackground = Color(0xFFFFFAF5);
const Color wdText = Color(0xFF292929);
const Color wdMuted = Color(0xFF777777);
const Color wdBorder = Color(0xFFEAE2DA);
const Color wdGreen = Color(0xFF16834A);
const Color wdRed = Color(0xFFC62828);

class WalkerDetailsScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> walkerData;

  const WalkerDetailsScreen({
    super.key,
    required this.uid,
    required this.walkerData,
  });

  @override
  State<WalkerDetailsScreen> createState() => _WalkerDetailsScreenState();
}

class _WalkerDetailsScreenState extends State<WalkerDetailsScreen> {
  bool _actionLoading = false;

  DocumentReference<Map<String, dynamic>> get _walkerRef =>
      FirebaseFirestore.instance.collection('walkers').doc(widget.uid);

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _string(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }
    if (value is DateTime) {
      return '${value.day.toString().padLeft(2, '0')}/'
          '${value.month.toString().padLeft(2, '0')}/'
          '${value.year}';
    }
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).join(', ');
    }
    return value.toString().trim();
  }

  String _first(List<dynamic> values, {String fallback = 'Not provided'}) {
    for (final value in values) {
      final result = _string(value);
      if (result.isNotEmpty && result != 'null') return result;
    }
    return fallback;
  }

  Map<String, dynamic> get _currentData => widget.walkerData;

  Map<String, dynamic> get _currentAddress =>
      _map(_currentData['currentAddress']);

  Map<String, dynamic> get _kyc => _map(_currentData['kyc']);

  Map<String, dynamic> get _documents => _map(_kyc['documents']);

  String get _name => _first([
        _currentData['fullName'],
        _currentData['name'],
        _currentData['displayName'],
      ], fallback: 'Walker');

  String get _phone => _first([
        _currentData['phone'],
        _currentData['phoneNumber'],
        _currentData['mobile'],
      ]);

  String get _email => _first([_currentData['email']]);

  String get _status {
    final status = _string(_currentData['status']).toLowerCase();
    final verification =
        _string(_currentData['verificationStatus']).toLowerCase();

    if (status == 'suspended') return 'Suspended';
    if (verification == 'rejected' || status == 'rejected') return 'Rejected';
    if (verification == 'verified' ||
        _currentData['isApproved'] == true) {
      if (_currentData['isActive'] == true || status == 'active') {
        return 'Active';
      }
      return 'Verified';
    }
    if (status == 'under_review') return 'Under Review';
    if (status == 'in_progress') return 'In Progress';
    if (verification == 'pending' || status == 'pending') return 'Pending';
    return status.isEmpty ? 'Unknown' : _titleCase(status);
  }

  String _titleCase(String value) {
    return value
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  bool get _isVerified {
    return _string(_currentData['verificationStatus']).toLowerCase() ==
            'verified' ||
        _currentData['isApproved'] == true;
  }

  bool get _isSuspended =>
      _string(_currentData['status']).toLowerCase() == 'suspended';

  bool get _isActive =>
      _currentData['isActive'] == true ||
      _string(_currentData['status']).toLowerCase() == 'active';

  bool get _isSubmitted => _currentData['applicationSubmitted'] == true;

  Color get _statusColor {
    switch (_status) {
      case 'Active':
      case 'Verified':
        return wdGreen;
      case 'Rejected':
      case 'Suspended':
        return wdRed;
      case 'Under Review':
      case 'Pending':
        return wdOrange;
      default:
        return wdMuted;
    }
  }

  Future<void> _performAction(_WalkerAction action) async {
    if (_actionLoading) return;

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isReject = action == _WalkerAction.reject;
        final isSuspend = action == _WalkerAction.suspend;
        final title = switch (action) {
          _WalkerAction.verify => 'Approve Walker?',
          _WalkerAction.reject => 'Reject Application?',
          _WalkerAction.suspend => 'Suspend Walker?',
          _WalkerAction.reactivate => 'Reactivate Walker?',
        };
        final message = switch (action) {
          _WalkerAction.verify =>
            'Confirm that you have reviewed the submitted details and KYC documents.',
          _WalkerAction.reject =>
            'The application will be marked as rejected.',
          _WalkerAction.suspend =>
            'The walker will be made inactive.',
          _WalkerAction.reactivate =>
            'The verified walker will be activated again.',
        };

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: wdText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: wdMuted),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isReject || isSuspend ? wdRed : wdOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                isReject
                    ? 'Reject'
                    : isSuspend
                        ? 'Suspend'
                        : action == _WalkerAction.verify
                            ? 'Approve'
                            : 'Reactivate',
              ),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !mounted) return;

    setState(() => _actionLoading = true);

    try {
      // Always read the latest document before changing its status.
      final snapshot = await _walkerRef.get();

      if (!snapshot.exists) {
        throw Exception('Walker record not found.');
      }

      final latest = snapshot.data()!;

      final latestStatus =
          _string(latest['status']).toLowerCase();
      final latestVerification =
          _string(latest['verificationStatus']).toLowerCase();

      if (action == _WalkerAction.verify) {
        if (latest['applicationSubmitted'] != true ||
            latestStatus != 'under_review' ||
            latestVerification == 'verified' ||
            latestStatus == 'suspended') {
          throw Exception(
            'This application is no longer awaiting verification. Refresh and check its latest status.',
          );
        }
      }

      if (action == _WalkerAction.reject) {
        if (latest['applicationSubmitted'] != true ||
            latestVerification == 'verified' ||
            latestStatus == 'suspended') {
          throw Exception(
            'This application cannot be rejected in its current state.',
          );
        }
      }

      if (action == _WalkerAction.suspend) {
        if (latest['isApproved'] != true &&
            latestVerification != 'verified') {
          throw Exception('Only a verified walker can be suspended.');
        }
      }

      if (action == _WalkerAction.reactivate) {
        if (latest['isApproved'] != true ||
            latestVerification != 'verified' ||
            latestStatus != 'suspended') {
          throw Exception(
            'Only a verified, suspended walker can be reactivated.',
          );
        }
      }

      final Map<String, dynamic> updates;

      switch (action) {
        case _WalkerAction.verify:
          updates = {
            'verificationStatus': 'verified',
            'status': 'approved',
            'isApproved': true,
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          break;

        case _WalkerAction.reject:
          updates = {
            'verificationStatus': 'rejected',
            'status': 'rejected',
            'isApproved': false,
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          break;

        case _WalkerAction.suspend:
          updates = {
            'status': 'suspended',
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          break;

        case _WalkerAction.reactivate:
          updates = {
            'verificationStatus': 'verified',
            'status': 'active',
            'isApproved': true,
            'isActive': true,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          break;
      }

      await _walkerRef.update(updates);

      if (!mounted) return;

      setState(() {
        widget.walkerData.addAll(updates);
        if (action == _WalkerAction.verify) {
          widget.walkerData['status'] = 'approved';
          widget.walkerData['verificationStatus'] = 'verified';
          widget.walkerData['isApproved'] = true;
          widget.walkerData['isActive'] = false;
        } else if (action == _WalkerAction.reject) {
          widget.walkerData['status'] = 'rejected';
          widget.walkerData['verificationStatus'] = 'rejected';
          widget.walkerData['isApproved'] = false;
          widget.walkerData['isActive'] = false;
        } else if (action == _WalkerAction.suspend) {
          widget.walkerData['status'] = 'suspended';
          widget.walkerData['isActive'] = false;
        } else {
          widget.walkerData['status'] = 'active';
          widget.walkerData['verificationStatus'] = 'verified';
          widget.walkerData['isApproved'] = true;
          widget.walkerData['isActive'] = true;
        }
      });

      _showMessage(
        switch (action) {
          _WalkerAction.verify => 'Walker approved successfully.',
          _WalkerAction.reject => 'Application rejected.',
          _WalkerAction.suspend => 'Walker suspended.',
          _WalkerAction.reactivate => 'Walker reactivated.',
        },
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Action failed: ${error.toString().replaceFirst('Exception: ', '')}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? wdRed : wdGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: wdBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Walker Details',
          style: TextStyle(
            color: wdText,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: wdText),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                children: [
                  _buildBasicCard(),
                  const SizedBox(height: 14),
                  _buildPersonalSection(),
                  const SizedBox(height: 14),
                  _buildWorkSection(),
                  const SizedBox(height: 14),
                  _buildAddressSection(),
                  const SizedBox(height: 14),
                  _buildKycSection(),
                ],
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicCard() {
    final photoUrl = _first([
      _currentData['photoUrl'],
      _currentData['profilePhotoUrl'],
      _currentData['selfieUrl'],
      _map(_kyc['selfie'])['downloadUrl'],
      _map(_kyc['selfie'])['url'],
    ], fallback: '');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: wdBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: const Color(0xFFFFE6D1),
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: wdOrange,
                      )
                    : null,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 19,
                        color: wdText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_rounded,
                          size: 16,
                          color: wdOrange,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SelectableText(
                            _phone,
                            style: const TextStyle(
                              color: wdText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Walker ID: ${widget.uid}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: wdMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: wdBorder),
          const SizedBox(height: 13),
          Row(
            children: [
              const Text(
                'Verification Status',
                style: TextStyle(
                  fontSize: 13,
                  color: wdMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (!_isSubmitted) ...[
            const SizedBox(height: 12),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: wdOrange, size: 18),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'This application has not been submitted for review.',
                    style: TextStyle(
                      color: wdMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return _section(
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      children: [
        _infoRow('Full Name', _name),
        _infoRow('Mobile Number', _phone),
        _infoRow('Email', _email),
        _infoRow(
          'Date of Birth',
          _first([
            _currentData['dateOfBirth'],
            _currentData['dob'],
          ]),
        ),
        _infoRow('Gender', _first([_currentData['gender']])),
      ],
    );
  }

  Widget _buildWorkSection() {
    final zones = _currentData['zoneNames'];
    final zoneText = zones is List
        ? _first([zones])
        : _first([
            _currentData['zoneName'],
            _currentData['zone'],
          ]);

    return _section(
      title: 'Work Location',
      icon: Icons.location_on_outlined,
      children: [
        _infoRow('State', _first([_currentData['state']])),
        _infoRow('City', _first([_currentData['city']])),
        _infoRow('Area', _first([_currentData['area']])),
        _infoRow('Zone', zoneText),
        _infoRow(
          'Travel Mode',
          _first([
            _currentData['travelMode'],
            _currentData['vehicleType'],
          ]),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return _section(
      title: 'Residential Address',
      icon: Icons.home_outlined,
      children: [
        _infoRow(
          'House / Flat',
          _first([
            _currentAddress['houseNumber'],
            _currentAddress['houseFlat'],
            _currentAddress['flatHouse'],
          ]),
        ),
        _infoRow(
          'Street / Locality',
          _first([
            _currentAddress['street'],
            _currentAddress['area'],
            _currentAddress['residentialArea'],
          ]),
        ),
        _infoRow(
          'Landmark',
          _first([_currentAddress['landmark']]),
        ),
        _infoRow(
          'City',
          _first([
            _currentAddress['city'],
            _currentAddress['residentialCity'],
          ]),
        ),
        _infoRow(
          'State',
          _first([
            _currentAddress['state'],
            _currentAddress['residentialState'],
          ]),
        ),
        _infoRow(
          'PIN Code',
          _first([
            _currentAddress['pinCode'],
            _currentAddress['pincode'],
          ]),
        ),
      ],
    );
  }

  Widget _buildKycSection() {
    final selfie = _map(_kyc['selfie']);

    final aadhaarFront = _map(_documents['aadhaar_front']);
    final aadhaarBack = _map(_documents['aadhaar_back']);
    final panCard = _map(_documents['pan_card']);

    return _section(
      title: 'KYC Documents',
      icon: Icons.verified_user_outlined,
      children: [
        _documentTile(
          title: 'Selfie',
          document: selfie,
          fallbackPaths: const [],
        ),
        _documentTile(
          title: 'Aadhaar Card — Front',
          document: aadhaarFront,
          fallbackPaths: const [],
        ),
        _documentTile(
          title: 'Aadhaar Card — Back',
          document: aadhaarBack,
          fallbackPaths: const [],
        ),
        _documentTile(
          title: 'PAN Card',
          document: panCard,
          fallbackPaths: const [],
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: wdBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E3),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: wdOrange, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: wdText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: wdMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: wdText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentTile({
    required String title,
    required Map<String, dynamic> document,
    required List<String> fallbackPaths,
  }) {
    final path = _first([
      document['storagePath'],
      document['path'],
      ...fallbackPaths,
    ], fallback: '');

    final url = _first([
      document['downloadUrl'],
      document['url'],
    ], fallback: '');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: wdBackground,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: wdBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              title == 'Selfie'
                  ? Icons.face_retouching_natural
                  : Icons.badge_outlined,
              color: wdOrange,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: wdText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url.isNotEmpty
                      ? 'Document URL available'
                      : path.isNotEmpty
                          ? 'Secure storage file'
                          : 'Document not uploaded',
                  style: const TextStyle(
                    color: wdMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: url.isEmpty && path.isEmpty
                ? null
                : () => _showDocument(
                      title: title,
                      url: url,
                      path: path,
                    ),
            style: OutlinedButton.styleFrom(
              foregroundColor: wdOrange,
              side: const BorderSide(color: wdOrange),
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

  Future<void> _showDocument({
    required String title,
    required String url,
    required String path,
  }) async {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: wdText,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 500,
                    minHeight: 150,
                  ),
                  child: FutureBuilder<String>(
                    future: url.isNotEmpty
                        ? Future<String>.value(url)
                        : FirebaseStorage.instance
                            .ref()
                            .child(path)
                            .getDownloadURL(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(
                              color: wdOrange,
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 38,
                                color: wdRed,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Document could not be loaded. Check Admin Storage permissions.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: wdMuted),
                              ),
                            ],
                          ),
                        );
                      }

                      return InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4,
                        child: Image.network(
                          snapshot.data!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text(
                              'Unable to display this document.',
                              style: TextStyle(color: wdMuted),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() {
    final buttons = <Widget>[];

    if (!_isSubmitted) {
      buttons.add(
        _actionButton(
          label: 'Application Not Submitted',
          icon: Icons.info_outline,
          color: wdMuted,
          enabled: false,
          onPressed: null,
        ),
      );
    } else if (!_isVerified &&
        !_isSuspended &&
        _status != 'Rejected') {
      buttons.add(
        _actionButton(
          label: 'Verify & Approve',
          icon: Icons.verified_outlined,
          color: wdGreen,
          onPressed: () => _performAction(_WalkerAction.verify),
        ),
      );
      buttons.add(
        _actionButton(
          label: 'Reject Application',
          icon: Icons.close_rounded,
          color: wdRed,
          outlined: true,
          onPressed: () => _performAction(_WalkerAction.reject),
        ),
      );
    } else if (_status == 'Rejected') {
      buttons.add(
        _actionButton(
          label: 'Approve Application',
          icon: Icons.verified_outlined,
          color: wdGreen,
          onPressed: () => _performAction(_WalkerAction.verify),
        ),
      );
      buttons.add(
        _actionButton(
          label: 'Rejected',
          icon: Icons.block,
          color: wdRed,
          enabled: false,
          onPressed: null,
        ),
      );
    } else if (_isSuspended) {
      buttons.add(
        _actionButton(
          label: 'Reactivate Walker',
          icon: Icons.play_circle_outline,
          color: wdGreen,
          onPressed: () => _performAction(_WalkerAction.reactivate),
        ),
      );
    } else if (_isVerified && _isActive) {
      buttons.add(
        _actionButton(
          label: 'Suspend Walker',
          icon: Icons.pause_circle_outline,
          color: wdRed,
          outlined: true,
          onPressed: () => _performAction(_WalkerAction.suspend),
        ),
      );
    } else if (_isVerified) {
      buttons.add(
        _actionButton(
          label: 'Reactivate Walker',
          icon: Icons.play_circle_outline,
          color: wdGreen,
          onPressed: () => _performAction(_WalkerAction.reactivate),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: wdBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_actionLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(
                  color: wdOrange,
                  minHeight: 3,
                ),
              ),
            if (buttons.isEmpty)
              const Text(
                'No action is available for this status.',
                style: TextStyle(color: wdMuted, fontSize: 12),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 390 ||
                      buttons.length > 2;

                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: buttons
                          .map(
                            (button) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: button,
                            ),
                          )
                          .toList(),
                    );
                  }

                  return Row(
                    children: [
                      for (int i = 0; i < buttons.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: buttons[i]),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool outlined = false,
    bool enabled = true,
  }) {
    return SizedBox(
      height: 48,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: _actionLoading || !enabled ? null : onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: _actionLoading || !enabled ? null : onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E1DD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }
}

enum _WalkerAction {
  verify,
  reject,
  suspend,
  reactivate,
}
