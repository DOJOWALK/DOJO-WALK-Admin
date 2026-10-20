/// DOJO WALK Admin
///
/// Interactive polygon boundary editor for Flutter Web.
///
/// Features:
/// - Display Google Map
/// - Draw a polygon by clicking on the map
/// - Undo the last point
/// - Clear the polygon
/// - Close the polygon visually
/// - Return coordinates to the parent screen
///
/// Important:
/// This widget does not save data to Firestore.
/// The parent screen must validate, verify and save the boundary.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/service_location_geometry.dart';

class ServiceBoundaryEditor extends StatefulWidget {
  const ServiceBoundaryEditor({
    super.key,
    this.initialPoints = const [],
    this.initialCenter = const LatLng(28.4744, 77.5040),
    this.initialZoom = 12,
    this.onBoundaryChanged,
    this.onSaveRequested,
    this.readOnly = false,
  });

  /// Previously saved polygon vertices.
  final List<LatLng> initialPoints;

  /// Default center: Greater Noida area.
  final LatLng initialCenter;

  final double initialZoom;

  /// Called whenever the user adds, removes or clears points.
  final ValueChanged<List<LatLng>>? onBoundaryChanged;

  /// Called when the user requests saving the boundary.
  ///
  /// The parent screen is responsible for persistence.
  final ValueChanged<List<GeoPoint>>? onSaveRequested;

  /// Prevents editing when true.
  final bool readOnly;

  @override
  State<ServiceBoundaryEditor> createState() =>
      _ServiceBoundaryEditorState();
}

class _ServiceBoundaryEditorState
    extends State<ServiceBoundaryEditor> {
  static const Color _orange = Color(0xFFFF7900);
  static const Color _background = Color(0xFFFFFAF5);

  GoogleMapController? _mapController;

  late List<LatLng> _points;

  @override
  void initState() {
    super.initState();
    _points = List<LatLng>.of(widget.initialPoints);
  }

  @override
  void didUpdateWidget(covariant ServiceBoundaryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialPoints != widget.initialPoints) {
      _points = List<LatLng>.of(widget.initialPoints);
    }
  }

  Set<Marker> get _markers {
    return {
      for (var i = 0; i < _points.length; i++)
        Marker(
          markerId: MarkerId('boundary_point_$i'),
          position: _points[i],
          infoWindow: InfoWindow(
            title: 'Boundary Point ${i + 1}',
            snippet:
                '${_points[i].latitude}, ${_points[i].longitude}',
          ),
        ),
    };
  }

  Set<Polygon> get _polygons {
    if (_points.length < 3) {
      return {};
    }

    return {
      Polygon(
        polygonId: const PolygonId('service_boundary'),
        points: _points,
        strokeColor: _orange,
        strokeWidth: 3,
        fillColor: _orange.withValues(alpha: 0.18),
        geodesic: true,
      ),
    };
  }

  void _addPoint(LatLng point) {
    if (widget.readOnly) return;

    setState(() {
      _points.add(point);
    });

    _notifyChanged();
  }

  void _undoLastPoint() {
    if (widget.readOnly || _points.isEmpty) return;

    setState(() {
      _points.removeLast();
    });

    _notifyChanged();
  }

  void _clearBoundary() {
    if (widget.readOnly || _points.isEmpty) return;

    setState(() {
      _points.clear();
    });

    _notifyChanged();
  }

  void _notifyChanged() {
    widget.onBoundaryChanged?.call(
      List<LatLng>.unmodifiable(_points),
    );
  }

  List<GeoPoint> _toGeoPoints() {
    return _points
        .map(
          (point) => GeoPoint(
            point.latitude,
            point.longitude,
          ),
        )
        .toList(growable: false);
  }

  bool get _hasValidBasicShape {
    if (_points.length < 3) return false;

    final distinctPoints = _points
        .map(
          (point) =>
              '${point.latitude.toStringAsFixed(7)},'
              '${point.longitude.toStringAsFixed(7)}',
        )
        .toSet();

    if (distinctPoints.length < 3 ||
        !_points.every(
          (point) =>
              point.latitude.isFinite &&
              point.longitude.isFinite &&
              point.latitude >= -90 &&
              point.latitude <= 90 &&
              point.longitude >= -180 &&
              point.longitude <= 180,
        )) {
      return false;
    }

    return ServiceLocationGeometry.isValidPolygon(_toGeoPoints());
  }

  void _requestSave() {
    if (widget.readOnly) return;

    if (!_hasValidBasicShape) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'सेव करने से पहले सही सीमा बनाएं: कम-से-कम 3 पॉइंट, बिना self-intersection और वास्तविक क्षेत्रफल के साथ।',
          ),
        ),
      );
      return;
    }

    widget.onSaveRequested?.call(_toGeoPoints());
  }

  Future<void> _fitBoundary() async {
    final controller = _mapController;

    if (controller == null || _points.isEmpty) return;

    if (_points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(_points.first, 16),
      );
      return;
    }

    var minLat = _points.first.latitude;
    var maxLat = minLat;
    var minLng = _points.first.longitude;
    var maxLng = minLng;

    for (final point in _points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Avoid an invalid zero-area camera bounds rectangle.
    if (minLat == maxLat) {
      minLat -= 0.001;
      maxLat += 0.001;
    }

    if (minLng == maxLng) {
      minLng -= 0.001;
      maxLng += 0.001;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        56,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _orange.withValues(alpha: 0.25),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(),
          SizedBox(
            height: 420,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initialCenter,
                zoom: widget.initialZoom,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: _addPoint,
              markers: _markers,
              polygons: _polygons,
              mapType: MapType.normal,
              compassEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: true,
              myLocationButtonEnabled: false,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: false,
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(
            Icons.map_outlined,
            color: _orange,
          ),
          const Text(
            'Service Boundary Editor',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!widget.readOnly) ...[
            OutlinedButton.icon(
              onPressed: _points.isEmpty ? null : _undoLastPoint,
              icon: const Icon(Icons.undo),
              label: const Text('Undo'),
            ),
            OutlinedButton.icon(
              onPressed: _points.isEmpty ? null : _clearBoundary,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear'),
            ),
          ],
          OutlinedButton.icon(
            onPressed: _points.isEmpty ? null : _fitBoundary,
            icon: const Icon(Icons.fit_screen),
            label: const Text('Fit Boundary'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Boundary points: ${_points.length}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.readOnly
                ? 'यह boundary केवल देखने के लिए है।'
                : _points.length < 3
                    ? 'कम-से-कम 3 अलग-अलग पॉइंट जोड़ें और एक बंद, बिना काटती रेखाओं वाला क्षेत्र बनाएं।'
                    : 'Polygon की मूल जाँच पास है। सेव करने से पहले वास्तविक सीमा जाँचें।',
            style: const TextStyle(fontSize: 13),
          ),
          if (!widget.readOnly) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    _hasValidBasicShape ? _requestSave : null,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Use This Boundary'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
