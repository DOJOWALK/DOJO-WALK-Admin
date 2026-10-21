import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onOpenLiveOperations;
  final VoidCallback? onOpenServiceLocations;

  const DashboardScreen({
    super.key,
    this.onOpenLiveOperations,
    this.onOpenServiceLocations,
  });

  final Color orange = const Color(0xFFFF7900);

  // ============================================================
  // FIRESTORE COUNTS
  // ============================================================

  Stream<int> _countAll(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<int> _countWhere(
    String collection,
    String field,
    dynamic value,
  ) {
    return FirebaseFirestore.instance
        .collection(collection)
        .where(field, isEqualTo: value)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // ============================================================
  // REVENUE
  // ============================================================

  Stream<double> _totalRevenue() {
    return FirebaseFirestore.instance
        .collection('payments')
        .where('status', isEqualTo: 'paid')
        .snapshots()
        .map((snapshot) {
      double total = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final amount = data['amount'];

        if (amount is num) {
          total += amount.toDouble();
        }
      }

      return total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFAF5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 28),

            // ==================================================
            // TOP STAT CARDS
            // ==================================================

            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                int columns = 4;

                if (width < 1100) {
                  columns = 2;
                }

                if (width < 600) {
                  columns = 1;
                }

                final cardWidth =
                    (width - ((columns - 1) * 16)) /
                        columns;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _StatCard(
                        title: 'Total Bookings',
                        icon: Icons.calendar_month_outlined,
                        stream: _countAll('bookings'),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _StatCard(
                        title: 'Customers',
                        icon: Icons.people_outline,
                        stream: _countAll('users'),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _StatCard(
                        title: 'Walkers',
                        icon: Icons.directions_walk_outlined,
                        stream: _countAll('walkers'),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _RevenueCard(
                        stream: _totalRevenue(),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ==================================================
            // LIVE OVERVIEW + BOOKING STATUS
            // ==================================================

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      _buildLiveOverview(),
                      const SizedBox(height: 20),
                      _buildBookingStatus(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildLiveOverview(),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildBookingStatus(),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ==================================================
            // RECENT BOOKINGS + ALERTS
            // ==================================================

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      _buildRecentBookings(),
                      const SizedBox(height: 20),
                      _buildAlerts(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildRecentBookings(),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildAlerts(),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            _buildSystemActivity(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final date = DateFormat(
      'EEEE, dd MMMM yyyy',
    ).format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFFEAD7),
            Color(0xFFFFF7EF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD8B5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7900).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9A3D), Color(0xFFFF7900)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7900).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'DOJO WALK Command Center',
                  style: TextStyle(
                    color: Color(0xFF292524),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(
                Icons.circle,
                size: 9,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 6),
              const Text(
                'Overview',
                style: TextStyle(
                  color: Color(0xFF15803D),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Good morning, Admin 👋',
            style: TextStyle(
              color: Color(0xFF292524),
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Your company overview: bookings, customers, walkers and live walk operations.',
            style: TextStyle(
              color: Colors.brown.shade700,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onOpenLiveOperations,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7900),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  elevation: 3,
                  shadowColor: const Color(0x55FF7900),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.radar_rounded),
                label: const Text(
                  'Open Live Operations',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOpenServiceLocations,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF7900),
                  side: const BorderSide(color: Color(0xFFFF7900)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Add / Manage Locations'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIVE OVERVIEW
  // ============================================================

  Widget _buildLiveOverview() {
    return _DashboardCard(
      title: 'Live Operations',
      icon: Icons.location_on_outlined,
      child: Column(
        children: [
          _LiveStreamRow(
            label: 'Active Walks',
            icon: Icons.directions_walk,
            stream: _countWhere(
              'bookings',
              'status',
              'walking',
            ),
          ),
          const Divider(),

          _LiveStreamRow(
            label: 'Available Walkers',
            icon: Icons.person_outline,
            stream: _countWhere(
              'walkers',
              'isOnline',
              true,
            ),
          ),
          const Divider(),

          _LiveStreamRow(
            label: 'Waiting Assignment',
            icon: Icons.hourglass_empty,
            stream: _countWhere(
              'bookings',
              'status',
              'pending',
            ),
          ),
          const Divider(),

          _LiveStreamRow(
            label: 'Completed Walks',
            icon: Icons.check_circle_outline,
            stream: _countWhere(
              'bookings',
              'status',
              'completed',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING STATUS
  // ============================================================

  Widget _buildBookingStatus() {
    return _DashboardCard(
      title: 'Booking Status',
      icon: Icons.pie_chart_outline,
      child: Column(
        children: [
          _StatusStreamRow(
            label: 'Pending',
            stream: _countWhere(
              'bookings',
              'status',
              'Pending',
            ),
          ),
          const SizedBox(height: 12),

          _StatusStreamRow(
            label: 'Picked Up',
            stream: _countWhere(
              'bookings',
              'status',
              'picked_up',
            ),
          ),
          const SizedBox(height: 12),

          _StatusStreamRow(
            label: 'Accepted',
            stream: _countWhere(
              'bookings',
              'status',
              'accepted',
            ),
          ),
          const SizedBox(height: 12),

          _StatusStreamRow(
            label: 'In Progress',
            stream: _countWhere(
              'bookings',
              'status',
              'walking',
            ),
          ),
          const SizedBox(height: 12),

          _StatusStreamRow(
            label: 'Completed',
            stream: _countWhere(
              'bookings',
              'status',
              'Completed',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT BOOKINGS
  // ============================================================

  Widget _buildRecentBookings() {
    return _DashboardCard(
      title: 'Recent Bookings',
      icon: Icons.receipt_long_outlined,
      child: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .limit(8)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return _errorMessage(
              'Unable to load recent bookings.',
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _emptyMessage(
              'No bookings yet.',
              Icons.calendar_month_outlined,
            );
          }

          return Column(
            children: docs.map((doc) {
              final data = doc.data();

              final status =
                  data['status']?.toString() ??
                      'Pending';

              final petId =
                  data['petId']?.toString() ?? '';

              return Padding(
                padding:
                    const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.zero,

                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: orange.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.pets,
                      color: orange,
                    ),
                  ),

                  title: Text(
                    'Booking #${doc.id}',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  subtitle: Text(
                    petId.isEmpty
                        ? 'Pet booking'
                        : 'Pet: $petId',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                  ),

                  trailing:
                      _StatusBadge(
                    status: status,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ============================================================
  // ALERTS
  // ============================================================

  Widget _buildAlerts() {
    return _DashboardCard(
      title: 'Operations Alerts',
      icon: Icons.warning_amber_outlined,
      child: Column(
        children: [
          _AlertStreamRow(
            title: 'Unassigned bookings',
            subtitle:
                'Bookings waiting for a walker',
            icon: Icons.person_search_outlined,
            stream: _countWhere(
              'bookings',
              'status',
              'Pending',
            ),
          ),
          const Divider(),

          _AlertStreamRow(
            title: 'Payment failures',
            subtitle:
                'Payments requiring attention',
            icon: Icons.payment_outlined,
            stream: _countWhere(
              'payments',
              'status',
              'failed',
            ),
          ),
          const Divider(),

          _AlertStreamRow(
            title: 'Inactive walkers',
            subtitle:
                'Walkers currently offline',
            icon: Icons.person_off_outlined,
            stream: _countWhere(
              'walkers',
              'isOnline',
              false,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SYSTEM ACTIVITY
  // ============================================================

  Widget _buildSystemActivity() {
    return _DashboardCard(
      title: 'System Activity',
      icon: Icons.bolt_outlined,
      child: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('audit_logs')
            .orderBy(
              'timestamp',
              descending: true,
            )
            .limit(6)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return _errorMessage(
              'Unable to load activity.',
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Column(
              children: const [
                _ActivityItem(
                  title: 'Dashboard connected',
                  subtitle:
                      'Firebase realtime connection ready',
                  icon:
                      Icons.cloud_done_outlined,
                ),
                Divider(),
                _ActivityItem(
                  title: 'Admin security active',
                  subtitle:
                      'Role verification enabled',
                  icon:
                      Icons.security_outlined,
                ),
              ],
            );
          }

          return Column(
            children: docs.map((doc) {
              final data = doc.data();

              final action =
                  data['action']?.toString() ??
                      'System activity';

              final actor =
                  data['actorRole']?.toString() ??
                      'Admin';

              return Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 4,
                ),
                child: _ActivityItem(
                  title: action,
                  subtitle:
                      'Performed by $actor',
                  icon: Icons.bolt_outlined,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _errorMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _emptyMessage(
    String message,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            icon,
            size: 36,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// STAT CARD
// ================================================================

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Stream<int> stream;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF7900);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF7F0)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFE1C8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16FF7900),
            blurRadius: 24,
            offset: Offset(0, 9),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            spreadRadius: 1,
            offset: Offset(-1, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color:
                  orange.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: orange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                StreamBuilder<int>(
                  stream: stream,
                  builder:
                      (context, snapshot) {
                    return Text(
                      '${snapshot.data ?? 0}',
                      style:
                          const TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// REVENUE CARD
// ================================================================

class _RevenueCard extends StatelessWidget {
  final Stream<double> stream;

  const _RevenueCard({
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF7900);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF7F0)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFE1C8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16FF7900),
            blurRadius: 24,
            offset: Offset(0, 9),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            spreadRadius: 1,
            offset: Offset(-1, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color:
                  orange.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.currency_rupee,
              color: orange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Revenue',
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                StreamBuilder<double>(
                  stream: stream,
                  builder:
                      (context, snapshot) {
                    final value =
                        snapshot.data ?? 0;

                    return Text(
                      '₹${value.toStringAsFixed(0)}',
                      style:
                          const TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// DASHBOARD CARD
// ================================================================

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF7900);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF7F0)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFE1C8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16FF7900),
            blurRadius: 24,
            offset: Offset(0, 9),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            spreadRadius: 1,
            offset: Offset(-1, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: orange,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ================================================================
// LIVE ROW
// ================================================================

class _LiveStreamRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Stream<int> stream;

  const _LiveStreamRow({
    required this.label,
    required this.icon,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label),
        ),
        StreamBuilder<int>(
          stream: stream,
          builder:
              (context, snapshot) {
            return Text(
              '${snapshot.data ?? 0}',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w800,
                fontSize: 16,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ================================================================
// STATUS ROW
// ================================================================

class _StatusStreamRow extends StatelessWidget {
  final String label;
  final Stream<int> stream;

  const _StatusStreamRow({
    required this.label,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ),
        StreamBuilder<int>(
          stream: stream,
          builder:
              (context, snapshot) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFF7900,
                ).withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                '${snapshot.data ?? 0}',
                style:
                    const TextStyle(
                  color:
                      Color(0xFFFF7900),
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ================================================================
// ALERT ROW
// ================================================================

class _AlertStreamRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Stream<int> stream;

  const _AlertStreamRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(
              0xFFFF7900,
            ).withValues(alpha: 0.10),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.warning_amber_outlined,
            color: Color(0xFFFF7900),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<int>(
          stream: stream,
          builder:
              (context, snapshot) {
            return Text(
              '${snapshot.data ?? 0}',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w800,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ================================================================
// STATUS BADGE
// ================================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          const BoxConstraints(
        maxWidth: 115,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _statusColor(status)
            .withValues(alpha: 0.10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 10,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;

      case 'walk in progress':
        return Colors.blue;

      case 'walker accepted':
        return Colors.indigo;

      case 'walker assigned':
        return Colors.orange;

      case 'cancelled':
        return Colors.red;

      case 'pending':
      default:
        return const Color(0xFFFF7900);
    }
  }
}

// ================================================================
// ACTIVITY ITEM
// ================================================================

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.bolt_outlined,
          color: Color(0xFFFF7900),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
