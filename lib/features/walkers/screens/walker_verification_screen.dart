import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class WalkerVerificationScreen extends StatefulWidget {
  const WalkerVerificationScreen({super.key});

  @override
  State<WalkerVerificationScreen> createState() =>
      _WalkerVerificationScreenState();
}

class _WalkerVerificationScreenState
    extends State<WalkerVerificationScreen> {
  static const Color orange = Color(0xFFFF7900);
  static const Color background = Color(0xFFFFFAF5);

  String _filter = 'all';
  String _search = '';

  Future<void> _updateStatus({
    required String uid,
    required String status,
    String? reason,
  }) async {
    if (status != 'approved' && status != 'rejected') {
      return;
    }

    try {
      final walkerRef =
          FirebaseFirestore.instance.collection('walkers').doc(uid);

      final isApproved = status == 'approved';

      await walkerRef.update({
        'verificationStatus': isApproved ? 'verified' : 'rejected',
        'status': status,
        'isApproved': isApproved,
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApproved
                ? 'Verification approved. Walker activation is still pending.'
                : 'Walker application rejected.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Update failed (${e.code}): ${e.message ?? 'Please try again.'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _reject(String uid) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Walker Application'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Explain what needs correction',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (reason == null || reason.trim().isEmpty) return;

    // The current Firestore Rules do not allow rejectionReason.
    // This version therefore does not save the reason to Firestore.
    await _updateStatus(
      uid: uid,
      status: 'rejected',
    );
  }

  Future<void> _showDocument({
    required String title,
    required String storagePath,
  }) async {
    if (storagePath.trim().isEmpty) {
      _showMessage('Document path is missing.');
      return;
    }

    try {
      final reference =
          FirebaseStorage.instance.ref().child(storagePath);

      final url = await reference.getDownloadURL();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 500,
                    maxWidth: 600,
                  ),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return const SizedBox(
                          height: 250,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: orange,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Image could not be displayed.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Handle identity documents confidentially.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Cannot open document (${e.code}). Check Storage Rules and file path.',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Cannot open document: $e');
    }
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

  String _getStatus(Map<String, dynamic> data) {
    final verification =
        (data['verificationStatus'] ?? '').toString().toLowerCase();

    final status = (data['status'] ?? '').toString().toLowerCase();

    if (verification == 'rejected' || status == 'rejected') {
      return 'rejected';
    }

    if (verification == 'verified' ||
        verification == 'approved' ||
        status == 'approved') {
      return 'approved';
    }

    if (status == 'under_review' ||
        verification == 'under_review') {
      return 'under_review';
    }

    return 'pending';
  }

  Widget _statusBadge(String status) {
    final Color color = status == 'approved'
        ? Colors.green
        : status == 'rejected'
            ? Colors.red
            : status == 'under_review'
                ? Colors.blue
                : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _documentButton({
    required String title,
    required Map<String, dynamic>? document,
  }) {
    final path = (document?['storagePath'] ?? '').toString();
    final available = path.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  available
                      ? 'Status: ${(document?['status'] ?? 'submitted').toString()}'
                      : 'Document not uploaded',
                  style: TextStyle(
                    fontSize: 12,
                    color: available ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: available
                ? () => _showDocument(
                      title: title,
                      storagePath: path,
                    )
                : null,
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _detailsButton(
    String uid,
    Map<String, dynamic> data,
  ) {
    return OutlinedButton.icon(
      onPressed: () {
        final kyc = data['kyc'] is Map
            ? Map<String, dynamic>.from(data['kyc'] as Map)
            : <String, dynamic>{};

        final documents = kyc['documents'] is Map
            ? Map<String, dynamic>.from(
                kyc['documents'] as Map,
              )
            : <String, dynamic>{};

        Map<String, dynamic>? getDocument(String key) {
          final value = documents[key];

          if (value is Map) {
            return Map<String, dynamic>.from(value);
          }

          return null;
        }

        final aadhaarFront = getDocument('aadhaar_front');
        final aadhaarBack = getDocument('aadhaar_back');
        final panCard = getDocument('pan_card');

        showDialog<void>(
          context: context,
          builder: (dialogContext) => Dialog(
            child: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Walker Application Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _infoRow(
                      'Name',
                      (data['name'] ??
                              data['fullName'] ??
                              'Not provided')
                          .toString(),
                    ),
                    _infoRow(
                      'Phone',
                      (data['phoneNumber'] ??
                              data['phone'] ??
                              'Not provided')
                          .toString(),
                    ),
                    _infoRow('Walker UID', uid),
                    _infoRow(
                      'Status',
                      _getStatus(data),
                    ),
                    _infoRow(
                      'Walker ID',
                      (data['walkerId'] ?? 'Not assigned').toString(),
                    ),
                    _infoRow(
                      'Email',
                      (data['email'] ?? 'Not provided').toString(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'KYC DOCUMENTS',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _documentButton(
                      title: 'Aadhaar Card — Front',
                      document: aadhaarFront,
                    ),
                    _documentButton(
                      title: 'Aadhaar Card — Back',
                      document: aadhaarBack,
                    ),
                    _documentButton(
                      title: 'PAN Card',
                      document: panCard,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Approval does not activate the Walker account.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      icon: const Icon(Icons.visibility_outlined),
      label: const Text('View Details & KYC'),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown() {
    return DropdownButtonFormField<String>(
      value: _filter,
      decoration: const InputDecoration(
        labelText: 'Application status',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: const [
        DropdownMenuItem(
          value: 'all',
          child: Text('All Applications'),
        ),
        DropdownMenuItem(
          value: 'pending',
          child: Text('Pending'),
        ),
        DropdownMenuItem(
          value: 'under_review',
          child: Text('Under Review'),
        ),
        DropdownMenuItem(
          value: 'approved',
          child: Text('Approved'),
        ),
        DropdownMenuItem(
          value: 'rejected',
          child: Text('Rejected'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _filter = value);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Walker Verification',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review walker applications and identity documents.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 18),
                  _filterDropdown(),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search name, phone or Walker UID',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() => _search = value.trim().toLowerCase());
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('walkers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Unable to load applications. Check Admin access and Firestore Rules.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: orange,
                      ),
                    );
                  }

                  final documents = snapshot.data?.docs ?? [];

                  final filtered = documents.where((doc) {
                    final data = doc.data();
                    final status = _getStatus(data);

                    final name = (data['name'] ??
                            data['fullName'] ??
                            '')
                        .toString()
                        .toLowerCase();

                    final phone = (data['phoneNumber'] ??
                            data['phone'] ??
                            '')
                        .toString()
                        .toLowerCase();

                    final searchMatches = _search.isEmpty ||
                        name.contains(_search) ||
                        phone.contains(_search) ||
                        doc.id.toLowerCase().contains(_search);

                    final statusMatches =
                        _filter == 'all' || status == _filter;

                    return searchMatches && statusMatches;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No applications found.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      24,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data();

                      final name = (data['name'] ??
                              data['fullName'] ??
                              'Unnamed Walker')
                          .toString();

                      final phone = (data['phoneNumber'] ??
                              data['phone'] ??
                              'Phone not provided')
                          .toString();

                      final status = _getStatus(data);

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 14),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Color(0xFFECECEC),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFFFF0E5),
                                    child: Icon(
                                      Icons.directions_walk,
                                      color: orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(phone),
                                      ],
                                    ),
                                  ),
                                  _statusBadge(status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SelectableText(
                                'Walker UID: ${doc.id}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _detailsButton(doc.id, data),
                                  if (status != 'approved')
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: orange,
                                      ),
                                      onPressed: () => _updateStatus(
                                        uid: doc.id,
                                        status: 'approved',
                                      ),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Approve'),
                                    ),
                                  if (status != 'rejected')
                                    OutlinedButton.icon(
                                      onPressed: () => _reject(doc.id),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      label: const Text('Reject'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
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
