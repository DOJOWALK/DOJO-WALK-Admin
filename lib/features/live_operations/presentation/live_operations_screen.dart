import 'package:flutter/material.dart';

class LiveOperationsScreen extends StatelessWidget {
  const LiveOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Operations')),
      body: SafeArea(
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
              'Live status must come from verified booking and walker records. '
              'This screen is a UI scaffold until read permissions and data '
              'contracts are tested.',
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_searching,
                      size: 32,
                      color: Color(0xFFFF7900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'My Location',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Device/browser location permission and unavailable or '
                      'denied states will be handled before showing location.',
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.my_location),
                      label: const Text('My Location (integration pending)'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Possible Walker Nearby',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No live location is shown in this scaffold. When wired, '
                      'any proximity signal must be approximate, permission-aware '
                      'and clearly distinguished from a confirmed walker presence.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
