import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LiveOperationsScreen extends StatefulWidget {
  const LiveOperationsScreen({super.key});

  @override
  State<LiveOperationsScreen> createState() => _LiveOperationsScreenState();
}

class _LiveOperationsScreenState extends State<LiveOperationsScreen> {
  Position? _position;
  bool _loadingLocation = false;
  String? _locationMessage;

  Future<void> _getMyLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationMessage('Location services are off. Turn them on and try again.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _setLocationMessage('Location permission was denied. Allow it to use My Location.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _setLocationMessage('Location permission is blocked. Enable it in your device/browser settings.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(() {
        _position = position;
        _locationMessage = 'Location fetched on this device. It has not been uploaded or shared.';
      });
    } catch (error) {
      _setLocationMessage(
        'Could not get your location. Check browser/device permission and try again.',
      );
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _setLocationMessage(String message) {
    if (!mounted) return;
    setState(() => _locationMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Live Walk Monitoring',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Live bookings and walker status will appear here after their '
            'trusted read contracts and access rules are verified.',
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_searching, size: 32, color: Color(0xFFFF7900)),
                  const SizedBox(height: 12),
                  Text('My Location', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Fetches this device/browser location only after permission. '
                    'Coordinates stay in this screen and are not uploaded.',
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _loadingLocation ? null : _getMyLocation,
                    icon: _loadingLocation
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: Text(_loadingLocation ? 'Getting location…' : 'My Location'),
                  ),
                  if (position != null) ...[
                    const SizedBox(height: 12),
                    SelectableText('Latitude: ${position.latitude.toStringAsFixed(6)}'),
                    SelectableText('Longitude: ${position.longitude.toStringAsFixed(6)}'),
                    Text('Accuracy: about ${position.accuracy.toStringAsFixed(0)} m'),
                  ],
                  if (_locationMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_locationMessage!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radar, color: Color(0xFFFF7900)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Possible Walker Nearby',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Chip(label: Text('Not checked')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nearby status is not connected yet. It will only be shown '
                    'after the trusted walker-location data contract, consent, '
                    'freshness limit and access rules are verified. A possible '
                    'nearby signal must never be presented as a confirmed walker presence.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
