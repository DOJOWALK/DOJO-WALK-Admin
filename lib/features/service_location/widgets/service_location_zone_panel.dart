import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/service_location_boundary.dart';
import '../models/service_location_zone.dart';
import '../services/service_location_boundary_service.dart';
import '../services/service_location_zone_service.dart';
import '../widgets/service_boundary_editor.dart';

const _zoneOrange = Color(0xFFFF7900);

/// Central Admin Zone workflow UI. Trusted Firebase callables remain authoritative.
class ServiceLocationZonePanel extends StatefulWidget {
  const ServiceLocationZonePanel({super.key, this.searchQuery = ''});

  final String searchQuery;

  @override
  State<ServiceLocationZonePanel> createState() => _ServiceLocationZonePanelState();
}

class _ServiceLocationZonePanelState extends State<ServiceLocationZonePanel> {
  final _zones = ServiceLocationZoneService();
  final _boundaries = ServiceLocationBoundaryService();
  final _firestore = FirebaseFirestore.instance;
  bool _busy = false;
  bool _isFounder = false;
  bool _isCentralAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentRole();
  }

  Future<void> _loadCurrentRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await _firestore.collection('admin_users').doc(user.uid).get();
      if (mounted) setState(() {
        final data = snapshot.data();
        final active = snapshot.exists && data?['isActive'] == true;
        _isFounder = active && data?['role'] == 'founder';
        _isCentralAdmin = active && data?['role'] == 'central_admin';
      });
    } catch (_) {
      if (mounted) setState(() { _isFounder = false; _isCentralAdmin = false; });
    }
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value), behavior: SnackBarBehavior.floating));
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      _message(success);
    } catch (error) {
      if (mounted) await showDialog<void>(context: context, builder: (c) => AlertDialog(
        title: const Text('Zone action failed'),
        content: SelectableText(error.toString()),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _load(String collection) async =>
      (await _firestore.collection(collection).get()).docs;

  Future<void> _createZone() async {
    final states = await _load('service_states');
    final districts = await _load('service_districts');
    final cities = await _load('service_cities');
    if (!mounted) return;
    final name = TextEditingController();
    String? stateId, districtId, cityId;
    bool saving = false;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) {
      final stateDistricts = districts.where((d) => d.data()['stateId']?.toString() == stateId).toList();
      final districtCities = cities.where((c) => c.data()['stateId']?.toString() == stateId && c.data()['districtId']?.toString() == districtId).toList();
      return AlertDialog(
        title: const Text('Create Zone Draft'),
        content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Select State/UT → District → City. A Zone cannot activate until its boundary is verified and the Founder approves the current revision.'),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(initialValue: stateId, isExpanded: true, decoration: const InputDecoration(labelText: 'State / UT'),
            items: states.map((d) => DropdownMenuItem(value: d.id, child: Text(d.data()['name']?.toString() ?? d.id))).toList(),
            onChanged: (v) => setDialogState(() { stateId = v; districtId = null; cityId = null; })),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: stateDistricts.any((d) => d.id == districtId) ? districtId : null, isExpanded: true, decoration: const InputDecoration(labelText: 'District'),
            items: stateDistricts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.data()['name']?.toString() ?? d.id))).toList(),
            onChanged: (v) => setDialogState(() { districtId = v; cityId = null; })),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: districtCities.any((c) => c.id == cityId) ? cityId : null, isExpanded: true, decoration: const InputDecoration(labelText: 'City'),
            items: districtCities.map((d) => DropdownMenuItem(value: d.id, child: Text(d.data()['name']?.toString() ?? d.id))).toList(),
            onChanged: (v) => setDialogState(() => cityId = v)),
          const SizedBox(height: 10),
          TextField(controller: name, textCapitalization: TextCapitalization.words, onChanged: (_) => setDialogState(() {}), decoration: const InputDecoration(labelText: 'Zone name')),
        ]))),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: saving || stateId == null || districtId == null || cityId == null || name.text.trim().isEmpty ? null : () async {
            setDialogState(() => saving = true);
            try {
              await _zones.saveZoneDraft(name: name.text, stateId: stateId!, districtId: districtId!, cityId: cityId!);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _message('Zone draft saved. Next, draw and submit its boundary.');
            } catch (error) {
              setDialogState(() => saving = false);
              _message(error.toString());
            }
          }, child: Text(saving ? 'Saving…' : 'Save Draft')),
        ],
      );
    }));
    name.dispose();
  }

  Future<void> _manageBoundary(ServiceLocationZone zone) async {
    final existing = await _boundaries.watchForLocation(zone.id, locationType: 'zone').first;
    final selected = selectBoundaryForManagement(existing);
    final sourceName = TextEditingController(text: selected?.sourceName ?? '');
    final sourceReference = TextEditingController(text: selected?.sourceReference ?? '');
    final notes = TextEditingController();
    List<GeoPoint> points = selected?.points ?? const [];
    bool saving = false;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text('Boundary · ' + zone.name),
      content: SizedBox(width: 820, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Status: ' + (selected?.verificationStatus.name ?? 'Not created') + '. Draw the real Zone perimeter; do not use a radius-only approximation. Saving with verification will immediately run the trusted Central Admin verification checks.'),
        const SizedBox(height: 10),
        TextField(controller: sourceName, decoration: const InputDecoration(labelText: 'Boundary source name')),
        const SizedBox(height: 8),
        TextField(controller: sourceReference, decoration: const InputDecoration(labelText: 'Source reference')),
        const SizedBox(height: 10),
        SizedBox(height: 500, child: ServiceBoundaryEditor(
          key: ValueKey('zone-boundary-' + zone.id + '-' + (selected?.id ?? 'new')),
          initialPoints: (selected?.points ?? const <GeoPoint>[]).map((p) => LatLng(p.latitude, p.longitude)).toList(),
          initialCenter: const LatLng(28.4744, 77.5040),
          onBoundaryChanged: (value) => points = value.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
          onSaveRequested: (value) => setDialogState(() => points = value),
        )),
        const SizedBox(height: 8),
        TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Verification notes')),
      ]))),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Close')),
        FilledButton(onPressed: saving || points.length < 3 || sourceName.text.trim().isEmpty || sourceReference.text.trim().isEmpty ? null : () async {
          setDialogState(() => saving = true);
          try {
            final boundary = ServiceLocationBoundary(
              id: selected?.verificationStatus == BoundaryVerificationStatus.verified ? '' : (selected?.id ?? ''), locationId: zone.id, locationType: 'zone',
              points: List<GeoPoint>.unmodifiable(points),
              sourceType: selected?.sourceType ?? BoundarySourceType.manuallyDrawn,
              sourceName: sourceName.text.trim(), sourceReference: sourceReference.text.trim(),
              verificationStatus: selected?.verificationStatus == BoundaryVerificationStatus.verified ? BoundaryVerificationStatus.pending : (selected?.verificationStatus ?? BoundaryVerificationStatus.pending),
              verifiedBy: null, verifiedAt: null, verificationNotes: null,
              createdAt: selected?.createdAt ?? DateTime.now(), updatedAt: DateTime.now(),
            );
            final boundaryId = await _boundaries.saveDraft(boundary);
            await _boundaries.markVerified(boundaryId: boundaryId, verificationNotes: notes.text.trim().isEmpty ? 'Submitted for boundary verification from Admin.' : notes.text.trim());
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            _message('Boundary verification completed by the trusted workflow. Zone activation remains blocked until Founder approval of the current revision.');
          } catch (error) {
            setDialogState(() => saving = false);
            _message(error.toString());
          }
        }, child: Text(saving ? 'Saving & verifying…' : 'Save & Verify Boundary')),
      ],
    )));
    sourceName.dispose(); sourceReference.dispose(); notes.dispose();
  }

  Future<void> _founderReview(ServiceLocationZone zone) async {
    final notes = TextEditingController();
    final isDeactivation = zone.workflowStatus == ZoneWorkflowStatus.deactivationSubmitted;
    final isReactivation = zone.workflowStatus == ZoneWorkflowStatus.reactivationSubmitted;
    String decision = isDeactivation ? 'deactivate' : (isReactivation ? 'reactivate' : 'approve');
    const decisions = <String, String>{
      'approve': 'Approve Zone',
      'reject': 'Reject submission',
      'changes_required': 'Request changes',
      'deactivate': 'Approve deactivation',
      'reactivate': 'Approve reactivation',
    };
    final available = isDeactivation
        ? const ['deactivate', 'changes_required', 'reject']
        : isReactivation
            ? const ['reactivate', 'changes_required', 'reject']
            : const ['approve', 'changes_required', 'reject'];
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text('Founder review · ' + zone.name),
      content: SizedBox(width: 440, child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Review the submitted revision and boundary evidence before deciding. The backend rechecks Founder role, revision and boundary hash.'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: decision, isExpanded: true, decoration: const InputDecoration(labelText: 'Decision'),
          items: available.map((value) => DropdownMenuItem(value: value, child: Text(decisions[value]!))).toList(),
          onChanged: (value) { if (value != null) setDialogState(() => decision = value); }),
        const SizedBox(height: 12),
        TextField(controller: notes, maxLines: 3, onChanged: (_) => setDialogState(() {}), decoration: const InputDecoration(labelText: 'Decision notes', hintText: 'Required except for direct approval')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: decision != 'approve' && notes.text.trim().isEmpty ? null : () => Navigator.pop(dialogContext, true), child: const Text('Record decision')),
      ],
    )));
    if (confirmed == true) {
      await _run(() => _zones.decideFounderApproval(zoneId: zone.id, decision: decision, notes: notes.text), 'Founder decision recorded.');
    }
    notes.dispose();
  }

  Future<void> _requestReactivation(ServiceLocationZone zone) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text('Request reactivation · ' + zone.name),
      content: TextField(controller: reason, maxLines: 3, onChanged: (_) => setDialogState(() {}), decoration: const InputDecoration(labelText: 'Mandatory reason')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: reason.text.trim().isEmpty ? null : () => Navigator.pop(dialogContext, true), child: const Text('Submit for Founder review')),
      ],
    )));
    if (confirmed == true) {
      await _run(() => _zones.requestReactivation(zoneId: zone.id, reason: reason.text), 'Reactivation request submitted for Founder review.');
    }
    reason.dispose();
  }

  Future<void> _emergencySuspend(ServiceLocationZone zone) async {
    final reason = TextEditingController();
    String severity = 'SEV-2';
    final confirmed = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('Emergency suspend Zone?'),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('This requests immediate service suspension through the trusted backend. The action should be audited and escalated.'),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(initialValue: severity, decoration: const InputDecoration(labelText: 'Severity'), items: const ['SEV-1','SEV-2','SEV-3','SEV-4'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { if (v != null) setDialogState(() => severity = v); }),
        const SizedBox(height: 10),
        TextField(controller: reason, maxLines: 3, onChanged: (_) => setDialogState(() {}), decoration: const InputDecoration(labelText: 'Mandatory reason')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: reason.text.trim().isEmpty ? null : () => Navigator.pop(context, true), child: const Text('Suspend Zone'))],
    )));
    if (confirmed == true) await _run(() => _zones.suspendForEmergency(zoneId: zone.id, reason: reason.text, severity: severity), 'Emergency suspension requested.');
    reason.dispose();
  }

  String _status(ZoneWorkflowStatus value) {
    switch (value) {
      case ZoneWorkflowStatus.changesRequired: return 'Changes required';
      case ZoneWorkflowStatus.deactivationSubmitted: return 'Deactivation pending Founder';
      case ZoneWorkflowStatus.deactivationApproved: return 'Deactivation approved';
      case ZoneWorkflowStatus.reactivationSubmitted: return 'Reactivation pending Founder';
      default: return value.name[0].toUpperCase() + value.name.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(width: double.infinity, margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFF7EF), border: Border.all(color: const Color(0xFFFFD2AC)), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Zone Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('State/UT → District → City → Zone. Central Admin prepares Zone records and boundaries; Founder approval is required before activation. Only Zone controls service availability.'),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _busy || !_isCentralAdmin ? null : _createZone, icon: const Icon(Icons.add_location_alt_outlined), label: const Text('Create Zone Draft'), style: FilledButton.styleFrom(backgroundColor: _zoneOrange, foregroundColor: Colors.white))),
      ])),
    Expanded(child: StreamBuilder<List<ServiceLocationZone>>(stream: _zones.watchZones(), builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Unable to load Zones. Check service_zones read access.\\n' + snapshot.error.toString())));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _zoneOrange));
      final query = widget.searchQuery.trim().toLowerCase();
      final items = snapshot.data!.where((zone) {
        if (query.isEmpty) return true;
        return zone.name.toLowerCase().contains(query) ||
            zone.id.toLowerCase().contains(query) ||
            zone.stateId.toLowerCase().contains(query) ||
            zone.districtId.toLowerCase().contains(query) ||
            zone.cityId.toLowerCase().contains(query) ||
            zone.workflowStatus.name.toLowerCase().contains(query);
      }).toList(growable: false);
      if (items.isEmpty) {
        return Center(
          child: Text(query.isEmpty
              ? 'No Zone records found. Create a draft to begin.'
              : 'No Zones match “${widget.searchQuery.trim()}”.'),
        );
      }
      return ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, index) {
        final zone = items[index];
        return Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFECE5DE))),
          child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.location_on_outlined, color: _zoneOrange), const SizedBox(width: 8), Expanded(child: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), Chip(label: Text(zone.isServiceActive ? 'ACTIVE' : _status(zone.workflowStatus), overflow: TextOverflow.ellipsis), backgroundColor: zone.isServiceActive ? const Color(0xFFE4F5E9) : const Color(0xFFFFF0E2))]),
            Text('State/UT: ' + zone.stateId + ' • District: ' + zone.districtId + ' • City: ' + zone.cityId, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text('Revision ' + zone.revision.toString() + ' · Boundary: ' + (zone.verifiedBoundaryId ?? 'Not verified/attached'), style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(onPressed: _busy || !_isCentralAdmin ? null : () => _manageBoundary(zone), icon: const Icon(Icons.map_outlined), label: const Text('Manage Boundary')),
              if (_isCentralAdmin && zone.verifiedBoundaryId != null && !zone.isServiceActive && (zone.workflowStatus == ZoneWorkflowStatus.draft || zone.workflowStatus == ZoneWorkflowStatus.changesRequired))
                FilledButton.tonal(onPressed: _busy ? null : () => _run(() => _zones.submitForFounderReview(zone.id), 'Zone submitted for Founder review.'), child: const Text('Submit for Founder Review')),
              if (_isCentralAdmin && !zone.isServiceActive && zone.workflowStatus == ZoneWorkflowStatus.suspended)
                OutlinedButton(onPressed: _busy ? null : () => _requestReactivation(zone), child: const Text('Request Reactivation')),
              if (_isFounder && (zone.workflowStatus == ZoneWorkflowStatus.submitted || zone.workflowStatus == ZoneWorkflowStatus.deactivationSubmitted || zone.workflowStatus == ZoneWorkflowStatus.reactivationSubmitted))
                FilledButton.tonal(onPressed: _busy ? null : () => _founderReview(zone), child: const Text('Founder Review')),
              if (_isCentralAdmin && zone.mayRequestActivation)
                FilledButton(onPressed: _busy ? null : () => _run(() => _zones.activateZone(zone.id), 'Activation request sent to trusted backend.'), child: const Text('Activate Approved Zone')),
              if (_isCentralAdmin && zone.workflowStatus == ZoneWorkflowStatus.deactivationApproved && zone.isServiceActive)
                FilledButton.tonal(onPressed: _busy ? null : () => _run(() => _zones.executeApprovedDeactivation(zone.id), 'Approved Zone deactivation executed.'), child: const Text('Execute Approved Deactivation')),
              if (_isCentralAdmin && zone.isServiceActive)
                OutlinedButton(onPressed: _busy ? null : () async {
                  final reason = TextEditingController();
                  final ok = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(title: const Text('Request Zone deactivation'), content: TextField(controller: reason, maxLines: 3, onChanged: (_) => setDialogState(() {}), decoration: const InputDecoration(labelText: 'Mandatory reason')), actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                    FilledButton(onPressed: reason.text.trim().isEmpty ? null : () => Navigator.pop(dialogContext, true), child: const Text('Submit request')),
                  ])));
                  if (ok == true) await _run(() => _zones.requestDeactivation(zoneId: zone.id, notes: reason.text), 'Deactivation request submitted for Founder review.');
                  reason.dispose();
                }, child: const Text('Request Deactivation')),
              if (_isCentralAdmin) OutlinedButton.icon(onPressed: _busy ? null : () => _emergencySuspend(zone), icon: const Icon(Icons.warning_amber_rounded, color: Colors.red), label: const Text('Emergency Suspend')),
            ]),
          ])));
      });
    })),
  ]);
}
