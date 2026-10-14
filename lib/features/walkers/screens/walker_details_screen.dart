import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

const Color walkerOrange = Color(0xFFFF7900);
const Color walkerBackground = Color(0xFFFFFAF5);
const Color walkerText = Color(0xFF292524);
const Color walkerMuted = Color(0xFF78716C);
const Color walkerBorder = Color(0xFFE7E5E4);
const Color walkerGreen = Color(0xFF15803D);
const Color walkerRed = Color(0xFFB91C1C);
const Color walkerBlue = Color(0xFF1D4ED8);

class WalkerDetailsScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> walkerData;

  const WalkerDetailsScreen({
    super.key,
    required this.uid,
    required this.walkerData,
  });

  @override
  State<WalkerDetailsScreen> createState() =>
      _WalkerDetailsScreenState();
}

class _WalkerDetailsScreenState extends State<WalkerDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _walkerRef =>
      _firestore.collection('walkers').doc(widget.uid);

  bool _actionLoading = false;

  String _text(dynamic value, [String fallback = 'Not provided']) {
    if (value == null) return fallback;

    if (value is Timestamp) return _date(value);

    if (value is DateTime) return _date(value);

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  String _date(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return 'Not available';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _statusLabel(Map<String, dynamic> data) {
    final status = _text(data['status'], 'in_progress');
    final verification =
        _text(data['verificationStatus'], 'pending');

    if (status == 'suspended') return 'Suspended';

    if (status == 'rejected' || verification == 'rejected') {
      return 'Rejected';
    }

    if (status == 'correction_required' ||
        verification == 'correction_required') {
      return 'Correction Required';
    }

    if (status == 'under_review') return 'Under Review';
    if (status == 'in_progress') return 'In Progress';
    if (status == 'inactive') return 'Inactive';
    if (status == 'left') return 'Left';

    if (status == 'approved' &&
        data['isApproved'] == true &&
        data['isActive'] == true &&
        verification == 'verified') {
      return 'Verified • Active';
    }

    if (status == 'approved' &&
        data['isApproved'] == true &&
        verification == 'verified') {
      return 'Verified • Inactive';
    }

    return status.replaceAll('_', ' ');
  }

  Color _statusColor(String status) {
    if (status.contains('Active') || status == 'Verified') {
      return walkerGreen;
    }

    if (status == 'Rejected' || status == 'Suspended') {
      return walkerRed;
    }

    if (status == 'Correction Required') {
      return const Color(0xFFB45309);
    }

    return walkerBlue;
  }

  bool _isVerified(Map<String, dynamic> data) {
    return data['verificationStatus'] == 'verified' &&
        data['isApproved'] == true;
  }

  bool _isActive(Map<String, dynamic> data) {
    return data['isActive'] == true;
  }

  bool _isSubmitted(Map<String, dynamic> data) {
    return data['applicationSubmitted'] == true ||
        data['status'] == 'under_review' ||
        data['status'] == 'approved' ||
        data['status'] == 'rejected' ||
        data['status'] == 'correction_required' ||
        data['status'] == 'suspended';
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? walkerRed : walkerGreen,
        ),
      );
  }

  Future<String?> _askReason({
    required String title,
    required String description,
    required String actionLabel,
  }) async {
    final controller = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Enter the reason',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: walkerOrange,
                ),
                onPressed: () {
                  final reason = controller.text.trim();

                  if (reason.length < 3) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a reason of at least 3 characters.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext, reason);
                },
                child: Text(actionLabel),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: walkerOrange,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return result == true;
  }

  String _actionTitle(String action) {
    switch (action) {
      case 'approve':
        return 'Verify & Approve';
      case 'reject':
        return 'Reject Application';
      case 'suspend':
        return 'Suspend Walker';
      case 'reactivate':
        return 'Reactivate Walker';
      case 'correction':
        return 'Request Correction';
      default:
        return 'Update Walker';
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'approve':
        return 'Approve';
      case 'reject':
        return 'Reject';
      case 'suspend':
        return 'Suspend';
      case 'reactivate':
        return 'Reactivate';
      case 'correction':
        return 'Request Correction';
      default:
        return 'Continue';
    }
  }

  String _actionMessage(String action) {
    switch (action) {
      case 'approve':
        return 'Approve this walker and activate the account?';
      case 'reject':
        return 'Reject this application? The account will remain inactive.';
      case 'suspend':
        return 'Suspend this active walker account?';
      case 'reactivate':
        return 'Reactivate this previously approved walker?';
      case 'correction':
        return 'Mark this application as requiring correction?';
      default:
        return 'Continue with this action?';
    }
  }

  Future<void> _runAdminAction({
    required String action,
    required Map<String, dynamic> latest,
    String? reason,
  }) async {
    if (_actionLoading) return;

    final adminUid = FirebaseAuth.instance.currentUser?.uid;

    if (adminUid == null) {
      _message('Admin login required.', error: true);
      return;
    }

    final status = _text(latest['status'], 'in_progress');
    final verification =
        _text(latest['verificationStatus'], 'pending');
    final approved = latest['isApproved'] == true;
    final active = latest['isActive'] == true;
    final submitted = _isSubmitted(latest);
    final cleanReason = reason?.trim();

    if (['reject', 'suspend', 'correction'].contains(action) &&
        (cleanReason == null || cleanReason.length < 3)) {
      _message(
        'Please enter a valid reason before continuing.',
        error: true,
      );
      return;
    }

    late String newStatus;
    late String newVerification;
    late bool newApproved;
    late bool newActive;
    late String auditAction;

    switch (action) {
      case 'approve':
        if (!submitted ||
            status == 'suspended' ||
            status == 'rejected' ||
            status == 'inactive' ||
            status == 'left' ||
            verification == 'rejected') {
          _message(
            'This application cannot be approved in its current state.',
            error: true,
          );
          return;
        }

        if (verification == 'verified' && approved && active) {
          _message('This walker is already active.');
          return;
        }

        newStatus = 'approved';
        newVerification = 'verified';
        newApproved = true;
        newActive = true;
        auditAction = 'walker_approved';
        break;

      case 'reject':
        if (!submitted ||
            verification == 'verified' ||
            status == 'suspended' ||
            status == 'inactive' ||
            status == 'left') {
          _message(
            'This application cannot be rejected in its current state.',
            error: true,
          );
          return;
        }

        newStatus = 'rejected';
        newVerification = 'rejected';
        newApproved = false;
        newActive = false;
        auditAction = 'walker_rejected';
        break;

      case 'suspend':
        if (!approved ||
            verification != 'verified' ||
            !active ||
            status != 'approved') {
          _message(
            'Only a verified, active walker can be suspended.',
            error: true,
          );
          return;
        }

        newStatus = 'suspended';
        newVerification = 'verified';
        newApproved = true;
        newActive = false;
        auditAction = 'walker_suspended';
        break;

      case 'reactivate':
        if (!approved ||
            verification != 'verified' ||
            status != 'suspended') {
          _message(
            'Only a previously approved, verified, suspended walker '
            'can be reactivated.',
            error: true,
          );
          return;
        }

        newStatus = 'approved';
        newVerification = 'verified';
        newApproved = true;
        newActive = true;
        auditAction = 'walker_reactivated';
        break;

      case 'correction':
        if (!submitted ||
            status == 'suspended' ||
            status == 'rejected' ||
            status == 'inactive' ||
            status == 'left' ||
            (verification == 'verified' && approved)) {
          _message(
            'Correction cannot be requested in the current state.',
            error: true,
          );
          return;
        }

        newStatus = 'correction_required';
        newVerification = 'correction_required';
        newApproved = false;
        newActive = false;
        auditAction = 'walker_correction_requested';
        break;

      default:
        _message('Unknown action.', error: true);
        return;
    }

    final confirmed = await _confirm(
      title: _actionTitle(action),
      message: _actionMessage(action),
      confirmLabel: _actionLabel(action),
    );

    if (!confirmed || !mounted) return;

    setState(() => _actionLoading = true);

    try {
      // Re-read the record before making a decision.
      final snapshot = await _walkerRef.get();

      if (!snapshot.exists) {
        throw StateError('Walker record no longer exists.');
      }

      final current = snapshot.data()!;

      if (_text(current['status'], 'in_progress') != status ||
          _text(current['verificationStatus'], 'pending') !=
              verification ||
          (current['isApproved'] == true) != approved ||
          (current['isActive'] == true) != active) {
        throw StateError(
          'Walker status changed. Refresh and try again.',
        );
      }

      final now = FieldValue.serverTimestamp();
      final batch = _firestore.batch();

      final changes = <String, dynamic>{
        'status': newStatus,
        'verificationStatus': newVerification,
        'isApproved': newApproved,
        'isActive': newActive,
        'updatedAt': now,
        'decisionBy': adminUid,
        'decisionAt': now,
      };

      if (cleanReason != null && cleanReason.isNotEmpty) {
        changes['decisionReason'] = cleanReason;
      }

      batch.update(_walkerRef, changes);

      final auditRef = _firestore.collection('audit_logs').doc();

      final audit = <String, dynamic>{
        'actorUid': adminUid,
        'actorRole': 'super_admin',
        'action': auditAction,
        'targetType': 'walker',
        'targetId': widget.uid,
        'beforeStatus': status,
        'afterStatus': newStatus,
        'createdAt': now,
      };

      if (cleanReason != null && cleanReason.isNotEmpty) {
        audit['reason'] = cleanReason;
      }

      batch.set(auditRef, audit);

      // Walker update and audit entry commit together.
      await batch.commit();

      if (!mounted) return;

      _message('${_actionTitle(action)} successful.');
    } on FirebaseException catch (e) {
      _message(
        e.code == 'permission-denied'
            ? 'Permission denied. Check Admin authentication and Firestore Rules.'
            : 'Could not update walker: ${e.message ?? e.code}',
        error: true,
      );
    } catch (e) {
      _message(
        'Action failed: ${e.toString().replaceFirst('Bad state: ', '')}',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _startReasonAction({
    required String action,
    required Map<String, dynamic> data,
  }) async {
    String title;
    String description;

    switch (action) {
      case 'reject':
        title = 'Reject Application';
        description = 'Enter the reason for rejecting this application.';
        break;
      case 'suspend':
        title = 'Suspend Walker';
        description = 'Explain why this walker is being suspended.';
        break;
      default:
        title = 'Request Correction';
        description = 'Explain what information needs to be corrected.';
    }

    final reason = await _askReason(
      title: title,
      description: description,
      actionLabel: 'Continue',
    );

    if (reason == null || !mounted) return;

    await _runAdminAction(
      action: action,
      latest: data,
      reason: reason,
    );
  }

  Future<void> _openDocument({
    required String title,
    required dynamic document,
  }) async {
    String? url;
    String? path;

    if (document is String) {
      if (document.startsWith('https://')) {
        url = document;
      } else if (document.trim().isNotEmpty) {
        path = document.trim();
      }
    } else if (document is Map) {
      final map = _map(document);

      final rawUrl = map['downloadUrl'] ?? map['url'];
      final rawPath = map['storagePath'] ?? map['path'];

      if (rawUrl is String && rawUrl.trim().isNotEmpty) {
        url = rawUrl.trim();
      }

      if (rawPath is String && rawPath.trim().isNotEmpty) {
        path = rawPath.trim();
      }
    }

    if ((url == null || url.isEmpty) && path != null) {
      try {
        url = await FirebaseStorage.instance
            .ref(path)
            .getDownloadURL();
      } on FirebaseException catch (e) {
        _message(
          'Cannot access $title. Check Storage Rules (${e.code}).',
          error: true,
        );
        return;
      }
    }

    if (url == null || url.isEmpty) {
      _message('$title is not available.', error: true);
      return;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: SelectableText(
              url!,
              style: const TextStyle(
                color: walkerBlue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: walkerBackground,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _walkerRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _errorView(
                'Could not load walker details.\n${snapshot.error}',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: walkerOrange,
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _errorView('Walker record not found.');
            }

            final data = snapshot.data!.data()!;

            return _buildContent(data);
          },
        ),
      ),
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: walkerRed,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: walkerText),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final kyc = _map(data['kyc']);
    final documents = _map(kyc['documents']);

    final status = _statusLabel(data);
    final verified = _isVerified(data);
    final active = _isActive(data);
    final submitted = _isSubmitted(data);
    final rejected = data['status'] == 'rejected';
    final suspended = data['status'] == 'suspended';

    final screenWidth = MediaQuery.sizeOf(context).width;
    final wide = screenWidth >= 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(wide ? 28 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreadcrumb(),
              const SizedBox(height: 18),
              _buildPageHeader(
                data: data,
                status: status,
                submitted: submitted,
                verified: verified,
                active: active,
                rejected: rejected,
                suspended: suspended,
              ),
              const SizedBox(height: 22),

              _buildProfileCard(data, status),

              const SizedBox(height: 16),
              _sectionCard(
                title: 'Personal Details',
                icon: Icons.person_outline,
                child: _responsiveGrid([
                  _info('Full Name', data['fullName'] ?? data['name']),
                  _info('Walker ID', data['walkerId'] ?? widget.uid),
                  _info('Mobile', data['phone'] ?? data['phoneNumber']),
                  _info('Email', data['email']),
                  _info('Gender', data['gender']),
                  _info('Date of Birth', data['dateOfBirth']),
                  _info('Registration Date', data['createdAt']),
                ]),
              ),

              const SizedBox(height: 16),
              _sectionCard(
                title: 'Current Address',
                icon: Icons.location_on_outlined,
                child: _responsiveGrid([
                  _info(
                    'House / Flat',
                    _map(data['currentAddress'])['flatHouse'] ??
                        _map(data['address'])['flatHouse'],
                  ),
                  _info(
                    'Building / Society',
                    _map(data['currentAddress'])['buildingSociety'] ??
                        _map(data['address'])['buildingSociety'],
                  ),
                  _info(
                    'Area / Locality',
                    data['area'] ??
                        _map(data['currentAddress'])['area'] ??
                        _map(data['address'])['area'],
                  ),
                  _info(
                    'Landmark',
                    _map(data['currentAddress'])['landmark'] ??
                        _map(data['address'])['landmark'],
                  ),
                  _info('City', data['city']),
                  _info('State', data['state']),
                  _info(
                    'PIN Code',
                    _map(data['currentAddress'])['pincode'] ??
                        _map(data['address'])['pincode'],
                  ),
                ]),
              ),

              const SizedBox(height: 16),
              _sectionCard(
                title: 'Work Location',
                icon: Icons.map_outlined,
                child: _responsiveGrid([
                  _info('State', data['state']),
                  _info('City', data['city']),
                  _info(
                    'Area / Zone',
                    data['zoneName'] ??
                        data['area'] ??
                        (data['zoneNames'] is List
                            ? (data['zoneNames'] as List).join(', ')
                            : null),
                  ),
                  _info('Travel Mode', data['travelMode']),
                  _info('Services', _listText(data['services'])),
                  _info(
                    'Availability',
                    _availabilityText(data['availability']),
                  ),
                ]),
              ),

              const SizedBox(height: 16),
              _sectionCard(
                title: 'KYC Documents',
                icon: Icons.verified_user_outlined,
                trailing: _statusPill(
                  _text(
                    kyc['status'],
                    _text(data['verificationStatus'], 'pending'),
                  ),
                  data['verificationStatus'] == 'verified'
                      ? walkerGreen
                      : const Color(0xFFB45309),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _documentRow(
                      'Selfie / Profile Photo',
                      kyc['selfie'] ??
                          data['photoUrl'] ??
                          data['profileImage'],
                    ),
                    _documentRow(
                      'Aadhaar Front',
                      documents['aadhaar_front'] ??
                          documents['aadhaarFront'],
                    ),
                    _documentRow(
                      'Aadhaar Back',
                      documents['aadhaar_back'] ??
                          documents['aadhaarBack'],
                    ),
                    _documentRow(
                      'PAN Card',
                      documents['pan_card'] ?? documents['panCard'],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _outlineAction(
                          'Request Correction',
                          Icons.edit_note,
                          () => _startReasonAction(
                            action: 'correction',
                            data: data,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Document replacement needs separate secure '
                      'Storage Rules and upload handling.',
                      style: TextStyle(
                        color: walkerMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _sectionCard(
                title: 'Performance Snapshot',
                icon: Icons.insights_outlined,
                child: _responsiveGrid([
                  _info('Completed Walks', data['completedWalks'] ?? 0),
                  _info('Complaints', data['complaintCount'] ?? 0),
                  _info('Rating', data['rating'] ?? 'Not rated'),
                  _info(
                    'Payout Summary',
                    data['totalPayout'] ?? 'Not available',
                  ),
                ]),
              ),

              const SizedBox(height: 16),
              _sectionCard(
                title: 'Account Security',
                icon: Icons.security_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _responsiveGrid([
                      _info('Account Status', status),
                      _info(
                        'Suspected',
                        data['isSuspected'] == true ? 'Yes' : 'No',
                      ),
                      _info('Last Updated', data['updatedAt']),
                    ]),
                    const SizedBox(height: 14),
                    const Text(
                      'The suspected flag is an administrative review '
                      'marker, not proof of wrongdoing.',
                      style: TextStyle(
                        fontSize: 12,
                        color: walkerMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _outlineAction(
                          'View Security Details',
                          Icons.info_outline,
                          () => _showSecurityDetails(data),
                        ),
                        _outlineAction(
                          'Activity History',
                          Icons.history,
                          _openActivityHistory,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildFooterNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return const Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'DOJO WALK ADMIN',
          style: TextStyle(
            color: walkerOrange,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        Icon(
          Icons.chevron_right,
          size: 15,
          color: walkerMuted,
        ),
        Text(
          'WALKER MANAGER',
          style: TextStyle(
            color: walkerMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader({
    required Map<String, dynamic> data,
    required String status,
    required bool submitted,
    required bool verified,
    required bool active,
    required bool rejected,
    required bool suspended,
  }) {
    final actions = <Widget>[];

    if (rejected) {
      actions.add(
        _outlineAction(
          'Review Again',
          Icons.refresh,
          () => _message(
            'Review Again does not automatically reactivate a rejected walker. '
            'A separate resubmission workflow is required.',
            error: true,
          ),
        ),
      );
    } else if (suspended) {
      actions.add(
        _primaryAction(
          'Reactivate',
          Icons.play_arrow,
          () => _runAdminAction(
            action: 'reactivate',
            latest: data,
          ),
        ),
      );
    } else if (verified && active) {
      actions.add(
        _primaryAction(
          'Suspend',
          Icons.pause_circle_outline,
          () => _startReasonAction(
            action: 'suspend',
            data: data,
          ),
        ),
      );
    } else if (submitted) {
      actions.add(
        _primaryAction(
          'Verify & Approve',
          Icons.verified_outlined,
          () => _runAdminAction(
            action: 'approve',
            latest: data,
          ),
        ),
      );

      actions.add(
        _outlineAction(
          'Reject',
          Icons.close,
          () => _startReasonAction(
            action: 'reject',
            data: data,
          ),
        ),
      );
    } else {
      actions.add(
        _disabledAction(
          'Application Not Submitted',
          Icons.hourglass_empty,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Walker Details',
          style: TextStyle(
            fontSize: 28,
            color: walkerText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Profile, verification & security',
          style: TextStyle(
            color: walkerMuted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions,
        ),
        if (_actionLoading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(color: walkerOrange),
        ],
      ],
    );
  }

  Widget _buildProfileCard(
    Map<String, dynamic> data,
    String status,
  ) {
    final name = _text(data['fullName'] ?? data['name'], 'Walker');
    final photo = _text(
      data['photoUrl'] ?? data['profileImage'],
      '',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: walkerBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 520;

          final profile = Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: const Color(0xFFFFE7D1),
                backgroundImage:
                    photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 32,
                        color: walkerOrange,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: walkerText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Walker ID: ${_text(data['walkerId'], widget.uid)}',
                      style: const TextStyle(
                        color: walkerMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registered: ${_date(data['createdAt'])}',
                      style: const TextStyle(
                        color: walkerMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final badges = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusPill(status, _statusColor(status)),
              if (data['isSuspected'] == true)
                _statusPill('Suspected • Review', walkerRed),
              _statusPill(
                _isActive(data) ? 'Account Active' : 'Account Inactive',
                _isActive(data) ? walkerGreen : walkerMuted,
              ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                profile,
                const SizedBox(height: 16),
                badges,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: profile),
              const SizedBox(width: 18),
              Flexible(child: badges),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: walkerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: walkerOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: walkerText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _responsiveGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 800
            ? 3
            : constraints.maxWidth >= 480
                ? 2
                : 1;

        final width = (constraints.maxWidth - (columns - 1) * 18) /
            columns;

        return Wrap(
          spacing: 18,
          runSpacing: 20,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _info(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: walkerMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SelectableText(
          _text(value),
          style: const TextStyle(
            color: walkerText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _documentRow(String title, dynamic document) {
    final available = document != null &&
        (document is Map
            ? (_map(document)['downloadUrl'] != null ||
                _map(document)['url'] != null ||
                _map(document)['storagePath'] != null ||
                _map(document)['path'] != null)
            : document.toString().trim().isNotEmpty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: walkerBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: walkerBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              color: walkerOrange,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: walkerText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    available ? 'Document available' : 'Not uploaded',
                    style: TextStyle(
                      color: available ? walkerGreen : walkerMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'View document',
              onPressed: available
                  ? () => _openDocument(
                        title: title,
                        document: document,
                      )
                  : null,
              icon: const Icon(
                Icons.visibility_outlined,
                color: walkerOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _primaryAction(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: walkerOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      onPressed: _actionLoading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _outlineAction(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: walkerOrange,
        side: const BorderSide(color: walkerOrange),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      onPressed: _actionLoading ? null : onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }

  Widget _disabledAction(String label, IconData icon) {
    return OutlinedButton.icon(
      onPressed: null,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  String _listText(dynamic value) {
    if (value is List) return value.join(', ');

    if (value is Map) {
      return value.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString())
          .join(', ');
    }

    return _text(value);
  }

  String _availabilityText(dynamic value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      return map.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .join(', ');
    }

    return _listText(value);
  }

  Future<void> _openActivityHistory() async {
    if (_actionLoading) return;

    try {
      final snapshot = await _firestore
          .collection('audit_logs')
          .where('targetType', isEqualTo: 'walker')
          .where('targetId', isEqualTo: widget.uid)
          .limit(50)
          .get();

      if (!mounted) return;

      final logs = snapshot.docs.toList()
        ..sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];

          final aDate = aTime is Timestamp
              ? aTime.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          final bDate = bTime is Timestamp
              ? bTime.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          return bDate.compareTo(aDate);
        });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Walker Activity History'),
          content: SizedBox(
            width: 560,
            child: logs.isEmpty
                ? const Text('No activity records found.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: logs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final log = logs[index].data();
                      final createdAt = log['createdAt'];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFF0E2),
                          child: Icon(
                            Icons.history,
                            color: walkerOrange,
                          ),
                        ),
                        title: Text(
                          _text(log['action'], 'Admin action')
                              .replaceAll('_', ' '),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('By: ${_text(log['actorUid'])}'),
                            if (log['beforeStatus'] != null ||
                                log['afterStatus'] != null)
                              Text(
                                '${_text(log['beforeStatus'])} → '
                                '${_text(log['afterStatus'])}',
                              ),
                            if (log['reason'] != null)
                              Text('Reason: ${log['reason']}'),
                            Text(
                              createdAt is Timestamp
                                  ? _date(createdAt)
                                  : 'Date unavailable',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on FirebaseException catch (e) {
      _message(
        'Could not load activity history: ${e.message ?? e.code}',
        error: true,
      );
    }
  }

  void _showSecurityDetails(Map<String, dynamic> data) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Account Security'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _info('UID', widget.uid),
                const SizedBox(height: 14),
                _info('Status', data['status']),
                const SizedBox(height: 14),
                _info('Verification', data['verificationStatus']),
                const SizedBox(height: 14),
                _info('Approved', data['isApproved']),
                const SizedBox(height: 14),
                _info('Active', data['isActive']),
                const SizedBox(height: 14),
                _info(
                  'Suspected',
                  data['isSuspected'] == true ? 'Yes' : 'No',
                ),
                const SizedBox(height: 14),
                _info('Decision Reason', data['decisionReason']),
                const SizedBox(height: 14),
                _info('Decision By', data['decisionBy']),
                const SizedBox(height: 14),
                _info('Decision Date', data['decisionAt']),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: walkerOrange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Walker details update live from Firestore. Admin decisions '
              'and their audit entries are written together. Document '
              'replacement, editable profile fields, suspected-flag '
              'management and Partner resubmission require separate '
              'implementation and permissions.',
              style: TextStyle(
                color: walkerText,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
