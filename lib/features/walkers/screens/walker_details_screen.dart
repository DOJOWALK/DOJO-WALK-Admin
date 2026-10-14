import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

const Color walkerDetailsOrange = Color(0xFFFF7900);
const Color walkerDetailsBackground = Color(0xFFFFFAF5);
const Color walkerDetailsText = Color(0xFF292524);
const Color walkerDetailsMuted = Color(0xFF78716C);
const Color walkerDetailsBorder = Color(0xFFE7E5E4);

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
  bool _saving = false;

  Map<String, dynamic> get _data => widget.walkerData;

  Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  String _text(dynamic value, {String fallback = 'Not provided'}) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    if (result.isEmpty || result == 'null') return fallback;

    return result;
  }

  String _firstValue(List<dynamic> values) {
    for (final value in values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        final result = value.toString().trim();
        if (result != 'null') return result;
      }
    }

    return 'Not provided';
  }

  String get _name => _firstValue([
        _data['name'],
        _data['fullName'],
        _data['displayName'],
      ]);

  String get _phone => _firstValue([
        _data['phoneNumber'],
        _data['phone'],
        _data['mobile'],
      ]);

  String get _status {
    final verificationStatus =
        _text(_data['verificationStatus'], fallback: '').toLowerCase();

    final status = _text(_data['status'], fallback: '').toLowerCase();

    if (status == 'suspended') return 'Suspended';
    if (status == 'rejected' || verificationStatus == 'rejected') {
      return 'Rejected';
    }

    if (verificationStatus == 'pending') return 'Pending Verification';
    if (status == 'under_review' ||
        verificationStatus == 'under_review') {
      return 'Under Review';
    }

    if (verificationStatus == 'verified' ||
        _data['isApproved'] == true) {
      if (_data['isActive'] == true) return 'Active';
      return 'Verified';
    }

    if (status == 'approved') return 'Approved';
    if (status == 'active') return 'Active';

    return _text(_data['status'], fallback: 'Unknown');
  }

  bool get _isVerified =>
      _text(_data['verificationStatus'], fallback: '').toLowerCase() ==
          'verified' ||
      _data['isApproved'] == true;

  bool get _isActive => _data['isActive'] == true;

  String get _photoUrl => _firstValue([
        _data['photoUrl'],
        _data['profilePhotoUrl'],
        _data['selfieUrl'],
      ]);

  Map<String, dynamic> get _kyc => _mapValue(_data['kyc']);

  Map<String, dynamic> get _documents =>
      _mapValue(_kyc['documents']);

  Map<String, dynamic> get _selfie =>
      _mapValue(_kyc['selfie']);

  Map<String, dynamic> get _address =>
      _mapValue(_data['residentialAddress']);

  Map<String, dynamic> get _workLocation =>
      _mapValue(_data['workLocation']);

  String _addressValue(String key) {
    return _firstValue([
      _address[key],
      _data[key],
    ]);
  }

  String _workValue(String key) {
    return _firstValue([
      _workLocation[key],
      _data[key],
    ]);
  }

  Future<void> _updateWalker({
    required String action,
  }) async {
    if (_saving) return;

    Map<String, dynamic> updates;

    switch (action) {
      case 'verify':
        updates = {
          'verificationStatus': 'verified',
          'status': 'approved',
          'isApproved': true,
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        break;

      case 'reject':
        updates = {
          'verificationStatus': 'rejected',
          'status': 'rejected',
          'isApproved': false,
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        break;

      case 'suspend':
        updates = {
          'status': 'suspended',
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        break;

      case 'reactivate':
        updates = {
          'verificationStatus': 'verified',
          'status': 'active',
          'isApproved': true,
          'isActive': true,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        break;

      default:
        return;
    }

    final String title;
    final String message;

    switch (action) {
      case 'verify':
        title = 'Verify Walker?';
        message =
            'The Walker will be verified but will remain inactive until activation.';
        break;

      case 'reject':
        title = 'Reject Application?';
        message =
            'This will mark the application as rejected and keep the Walker inactive.';
        break;

      case 'suspend':
        title = 'Suspend Walker?';
        message =
            'The Walker will be marked suspended and made inactive.';
        break;

      default:
        title = 'Reactivate Walker?';
        message =
            'This will mark the verified Walker as active. Confirm that the Walker is eligible to work.';
    }

    final confirmed = await showDialog<bool>(
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
              backgroundColor: walkerDetailsOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('walkers')
          .doc(widget.uid)
          .update(updates);

      if (!mounted) return;

      // Update the local data so the current page reflects the action.
      _data.addAll(updates);
      _data.remove('updatedAt');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'verify'
                ? 'Walker verified. Activation is still pending.'
                : action == 'reject'
                    ? 'Application rejected.'
                    : action == 'suspend'
                        ? 'Walker suspended.'
                        : 'Walker reactivated.',
          ),
        ),
      );

      setState(() {});
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Update failed: ${error.message ?? error.code}. '
            'Check Firestore Rules and admin permissions.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: walkerDetailsText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: walkerDetailsMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: walkerDetailsBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _infoRow(
    String label,
    dynamic value, {
    IconData? icon,
  }) {
    final text = _text(value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: walkerDetailsOrange),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(
                color: walkerDetailsMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: walkerDetailsText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      color: walkerDetailsBorder,
    );
  }

  Widget _statusBadge() {
    final status = _status;

    final Color color;
    final Color background;

    if (status == 'Active') {
      color = const Color(0xFF15803D);
      background = const Color(0xFFDCFCE7);
    } else if (status == 'Verified' || status == 'Approved') {
      color = const Color(0xFF1D4ED8);
      background = const Color(0xFFDBEAFE);
    } else if (status == 'Rejected' || status == 'Suspended') {
      color = const Color(0xFFB91C1C);
      background = const Color(0xFFFEE2E2);
    } else {
      color = const Color(0xFF92400E);
      background = const Color(0xFFFEF3C7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<String?> _resolveDocumentUrl(
    Map<String, dynamic> document,
  ) async {
    final directUrl = _firstValue([
      document['downloadUrl'],
      document['url'],
    ]);

    if (directUrl != 'Not provided') return directUrl;

    final storagePath = _text(
      document['storagePath'],
      fallback: '',
    );

    if (storagePath.isEmpty) return null;

    try {
      return await FirebaseStorage.instance
          .ref(storagePath)
          .getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  void _showDocumentPreview({
    required String title,
    required Map<String, dynamic> document,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _DocumentPreviewDialog(
          title: title,
          loadUrl: _resolveDocumentUrl(document),
        );
      },
    );
  }

  Widget _documentCard({
    required String title,
    required String description,
    required Map<String, dynamic> document,
    required IconData icon,
  }) {
    final hasPath = _text(
          document['storagePath'],
          fallback: '',
        ).isNotEmpty ||
        _text(document['downloadUrl'], fallback: '').isNotEmpty ||
        _text(document['url'], fallback: '').isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: walkerDetailsBorder),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: walkerDetailsOrange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: walkerDetailsOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: walkerDetailsText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPath ? description : 'Document not uploaded',
                  style: const TextStyle(
                    color: walkerDetailsMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: hasPath
                ? () => _showDocumentPreview(
                      title: title,
                      document: document,
                    )
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: walkerDetailsOrange,
              side: const BorderSide(color: walkerDetailsOrange),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool primary = false,
    bool danger = false,
  }) {
    final foreground = danger
        ? const Color(0xFFB91C1C)
        : primary
            ? Colors.white
            : walkerDetailsOrange;

    return SizedBox(
      height: 44,
      child: primary
          ? FilledButton.icon(
              onPressed: _saving ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: danger
                    ? const Color(0xFFB91C1C)
                    : walkerDetailsOrange,
                foregroundColor: Colors.white,
              ),
              icon: Icon(icon, size: 17),
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: _saving ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: foreground),
              ),
              icon: Icon(icon, size: 17),
              label: Text(label),
            ),
    );
  }

  Widget _buildActions() {
    final isRejected = _status == 'Rejected';
    final isSuspended = _status == 'Suspended';

    return _infoCard([
      if (!_isVerified && !isRejected) ...[
        _actionButton(
          label: 'Verify Walker',
          icon: Icons.verified_outlined,
          primary: true,
          onPressed: () => _updateWalker(action: 'verify'),
        ),
        const SizedBox(height: 10),
        _actionButton(
          label: 'Reject Application',
          icon: Icons.cancel_outlined,
          danger: true,
          onPressed: () => _updateWalker(action: 'reject'),
        ),
      ] else if (isRejected) ...[
        const Text(
          'This application has been rejected.',
          style: TextStyle(
            color: walkerDetailsMuted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        _actionButton(
          label: 'Verify Walker',
          icon: Icons.verified_outlined,
          primary: true,
          onPressed: () => _updateWalker(action: 'verify'),
        ),
      ] else if (isSuspended || !_isActive) ...[
        const Text(
          'This verified Walker is currently inactive.',
          style: TextStyle(
            color: walkerDetailsMuted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        _actionButton(
          label: 'Reactivate Walker',
          icon: Icons.play_circle_outline,
          primary: true,
          onPressed: () => _updateWalker(action: 'reactivate'),
        ),
        if (!isSuspended) ...[
          const SizedBox(height: 10),
          _actionButton(
            label: 'Suspend Walker',
            icon: Icons.pause_circle_outline,
            danger: true,
            onPressed: () => _updateWalker(action: 'suspend'),
          ),
        ],
      ] else ...[
        _actionButton(
          label: 'Suspend Walker',
          icon: Icons.pause_circle_outline,
          danger: true,
          onPressed: () => _updateWalker(action: 'suspend'),
        ),
      ],
      if (_saving) ...[
        const SizedBox(height: 14),
        const LinearProgressIndicator(
          color: walkerDetailsOrange,
        ),
        const SizedBox(height: 6),
        const Text(
          'Updating Walker status…',
          style: TextStyle(
            color: walkerDetailsMuted,
            fontSize: 12,
          ),
        ),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final selfie = _selfie;

    final aadhaarFront = _mapValue(_documents['aadhaar_front']);
    final aadhaarBack = _mapValue(_documents['aadhaar_back']);
    final panCard = _mapValue(_documents['pan_card']);

    final selfieDocument = selfie.isNotEmpty
        ? selfie
        : <String, dynamic>{
            'downloadUrl': _photoUrl == 'Not provided'
                ? null
                : _photoUrl,
          };

    return Scaffold(
      backgroundColor: walkerDetailsBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: walkerDetailsText,
        elevation: 0,
        title: const Text(
          'Walker Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: walkerDetailsBorder),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 500;

                      final avatar = CircleAvatar(
                        radius: 36,
                        backgroundColor:
                            walkerDetailsOrange.withValues(alpha: 0.12),
                        backgroundImage:
                            _photoUrl == 'Not provided'
                                ? null
                                : NetworkImage(_photoUrl),
                        child: _photoUrl == 'Not provided'
                            ? const Icon(
                                Icons.person,
                                size: 38,
                                color: walkerDetailsOrange,
                              )
                            : null,
                      );

                      final identity = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name,
                            style: const TextStyle(
                              color: walkerDetailsText,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _phone,
                            style: const TextStyle(
                              color: walkerDetailsMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _statusBadge(),
                        ],
                      );

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                avatar,
                                const SizedBox(width: 14),
                                Expanded(child: identity),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _infoRow('Walker UID', widget.uid),
                            _divider(),
                            _infoRow(
                              'Walker ID',
                              _data['walkerId'],
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          avatar,
                          const SizedBox(width: 18),
                          Expanded(child: identity),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Walker UID',
                                style: TextStyle(
                                  color: walkerDetailsMuted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                widget.uid,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ID: ${_text(_data['walkerId'])}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                _sectionTitle('Personal Details'),
                _infoCard([
                  _infoRow('Full Name', _name),
                  _divider(),
                  _infoRow('Phone Number', _phone),
                  _divider(),
                  _infoRow('Email', _data['email']),
                  _divider(),
                  _infoRow(
                    'Date of Birth',
                    _firstValue([
                      _data['dateOfBirth'],
                      _data['dob'],
                    ]),
                  ),
                  _divider(),
                  _infoRow('Gender', _data['gender']),
                ]),

                _sectionTitle('Work Location'),
                _infoCard([
                  _infoRow('State', _workValue('state')),
                  _divider(),
                  _infoRow('City', _workValue('city')),
                  _divider(),
                  _infoRow(
                    'Area',
                    _firstValue([
                      _data['area'],
                      _data['workArea'],
                      _workLocation['area'],
                    ]),
                  ),
                  _divider(),
                  _infoRow(
                    'Travel Mode',
                    _firstValue([
                      _data['travelMode'],
                      _data['transportMode'],
                      _workLocation['travelMode'],
                    ]),
                  ),
                ]),

                _sectionTitle('Residential Address'),
                _infoCard([
                  _infoRow(
                    'House / Flat',
                    _addressValue('houseFlat'),
                  ),
                  _divider(),
                  _infoRow(
                    'Street / Area',
                    _firstValue([
                      _address['street'],
                      _address['area'],
                      _data['residentialArea'],
                    ]),
                  ),
                  _divider(),
                  _infoRow(
                    'City',
                    _firstValue([
                      _address['city'],
                      _data['residentialCity'],
                    ]),
                  ),
                  _divider(),
                  _infoRow(
                    'State',
                    _firstValue([
                      _address['state'],
                      _data['residentialState'],
                    ]),
                  ),
                  _divider(),
                  _infoRow(
                    'PIN Code',
                    _firstValue([
                      _address['pincode'],
                      _address['pinCode'],
                      _data['pincode'],
                    ]),
                  ),
                ]),

                _sectionTitle(
                  'KYC Documents',
                  subtitle:
                      'Open a document to inspect it before making a decision.',
                ),

                _documentCard(
                  title: 'Selfie / Profile Photo',
                  description: 'Walker identity photo',
                  document: selfieDocument,
                  icon: Icons.face_outlined,
                ),
                const SizedBox(height: 10),

                _documentCard(
                  title: 'Aadhaar Card — Front',
                  description: 'Front side of Aadhaar',
                  document: aadhaarFront,
                  icon: Icons.credit_card_outlined,
                ),
                const SizedBox(height: 10),

                _documentCard(
                  title: 'Aadhaar Card — Back',
                  description: 'Back side of Aadhaar',
                  document: aadhaarBack,
                  icon: Icons.credit_card_outlined,
                ),
                const SizedBox(height: 10),

                _documentCard(
                  title: 'PAN Card',
                  description: 'PAN identity document',
                  document: panCard,
                  icon: Icons.badge_outlined,
                ),

                _sectionTitle('Walker Status & Actions'),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentPreviewDialog extends StatefulWidget {
  final String title;
  final Future<String?> loadUrl;

  const _DocumentPreviewDialog({
    required this.title,
    required this.loadUrl,
  });

  @override
  State<_DocumentPreviewDialog> createState() =>
      _DocumentPreviewDialogState();
}

class _DocumentPreviewDialogState
    extends State<_DocumentPreviewDialog> {
  final TransformationController _transformationController =
      TransformationController();

  double _scale = 1;

  void _zoomIn() {
    _scale = (_scale + 0.25).clamp(0.5, 4.0);
    _applyScale();
  }

  void _zoomOut() {
    _scale = (_scale - 0.25).clamp(0.5, 4.0);
    _applyScale();
  }

  void _resetZoom() {
    _scale = 1;
    _transformationController.value = Matrix4.identity();
    setState(() {});
  }

  void _applyScale() {
    _transformationController.value =
        Matrix4.identity()..scaleByDouble(_scale, _scale, 1, 1);

    setState(() {});
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 900,
          maxHeight: 700,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Zoom out',
                    onPressed: _zoomOut,
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    tooltip: 'Zoom in',
                    onPressed: _zoomIn,
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: 'Reset zoom',
                    onPressed: _resetZoom,
                    icon: const Icon(Icons.restart_alt),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<String?>(
                future: widget.loadUrl,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: walkerDetailsOrange,
                      ),
                    );
                  }

                  final url = snapshot.data;

                  if (url == null || url.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Document could not be loaded. '
                          'Check its Storage path and access permissions.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 4,
                    panEnabled: true,
                    scaleEnabled: true,
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;

                          return const Center(
                            child: CircularProgressIndicator(
                              color: walkerDetailsOrange,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Unable to display this document.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Pinch or drag to inspect the document.',
                style: TextStyle(
                  color: walkerDetailsMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
