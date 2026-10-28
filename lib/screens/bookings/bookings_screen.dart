import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'booking_status_helper.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _selectedStatus = 'All';
  String _search = '';

  final List<String> _statuses = const [
    'All',
    'Pending',
    'Walker Assigned',
    'Walker Accepted',
    'Walk In Progress',
    'Completed',
    'Cancelled',
  ];

  String _text(dynamic value, [String fallback = '—']) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'walk in progress':
        return Colors.blue;
      case 'walker accepted':
      case 'walker assigned':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _date(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return 'Date unavailable';

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  int _timestampMillis(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFAF5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bookings Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'View and monitor customer bookings',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (value) {
                    setState(() => _search = value.trim().toLowerCase());
                  },
                  decoration: InputDecoration(
                    hintText: 'Search booking, customer or status',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFFFE1C8)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Filter by status',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: _statuses.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final permissionDenied = snapshot.error
                          .toString()
                          .toLowerCase()
                          .contains('permission-denied') ||
                      snapshot.error
                          .toString()
                          .toLowerCase()
                          .contains('permission denied');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            permissionDenied
                                ? Icons.lock_outline
                                : Icons.error_outline,
                            size: 42,
                            color: permissionDenied
                                ? Colors.orange
                                : Colors.redAccent,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            permissionDenied
                                ? 'Permission denied'
                                : 'Could not load bookings',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            permissionDenied
                                ? 'Your current Admin role or assigned scope may not allow access to these bookings. Ask an authorized administrator to review access.'
                                : 'Check the connection and data access configuration. No booking status has been changed.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF7900),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                final filtered = docs.where((doc) {
                  final data = doc.data();
                  final status = displayBookingStatus(data['status']);

                  if (_selectedStatus != 'All' &&
                      status.toLowerCase() !=
                          _selectedStatus.toLowerCase()) {
                    return false;
                  }

                  final searchable = [
                    doc.id,
                    _text(data['customerName'], ''),
                    _text(data['customerId'], ''),
                    _text(data['walkerName'], ''),
                    status,
                  ].join(' ').toLowerCase();

                  return searchable.contains(_search);
                }).toList();

                filtered.sort((a, b) {
                  final aTime = _timestampMillis(a.data()['createdAt']);
                  final bTime = _timestampMillis(b.data()['createdAt']);
                  return bTime.compareTo(aTime);
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 54,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            docs.isEmpty
                                ? 'No bookings found in Firestore.'
                                : 'No bookings match your search.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Total records: ${docs.length}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final status = _text(data['status'], 'Unknown');
                    final color = _statusColor(status);

                    final customerName = _text(
                      data['customerName'] ?? data['customerId'],
                      'Customer',
                    );

                    final walkerName = _text(
                      data['walkerName'] ?? data['walkerId'],
                      'Not assigned',
                    );

                    final amount = data['amount'] ??
                        data['totalAmount'] ??
                        data['price'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  color: Color(0xFFFF7900),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Booking ${doc.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _detailRow(
                              Icons.person_outline,
                              'Customer',
                              customerName,
                            ),
                            _detailRow(
                              Icons.directions_walk_outlined,
                              'Walker',
                              walkerName,
                            ),
                            _detailRow(
                              Icons.access_time,
                              'Created',
                              _date(data['createdAt']),
                            ),
                            _detailRow(
                              Icons.calendar_month_outlined,
                              'Walk time',
                              _date(
                                data['walkDateTime'] ??
                                    data['scheduledAt'] ??
                                    data['bookingDate'],
                              ),
                            ),
                            _detailRow(
                              Icons.currency_rupee,
                              'Amount',
                              amount == null ? '—' : '₹$amount',
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
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
