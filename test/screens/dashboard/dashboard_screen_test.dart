import 'package:dojo_admin/screens/dashboard/dashboard_data_source.dart';
import 'package:dojo_admin/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardDataSource implements DashboardDataSource {
  @override
  Stream<int> countAll(String collection) => Stream<int>.value(
        switch (collection) {
          'bookings' => 12,
          'users' => 8,
          'walkers' => 5,
          _ => 0,
        },
      );

  @override
  Stream<int> countWhere(String collection, String field, dynamic value) =>
      Stream<int>.value(2);

  @override
  Stream<int> countBookingStatus(String canonicalLabel) => Stream<int>.value(
        switch (canonicalLabel) {
          'Pending' => 3,
          'Completed' => 4,
          'Walk In Progress' => 1,
          _ => 0,
        },
      );

  @override
  Stream<double> totalPaidAmount() => Stream<double>.value(1499);

  @override
  Stream<List<DashboardBooking>> recentBookings() =>
      Stream<List<DashboardBooking>>.value(const [
        DashboardBooking(
          id: 'booking-001',
          petId: 'pet-001',
          status: 'Completed',
        ),
      ]);

  @override
  Stream<List<DashboardActivity>> recentActivity() =>
      Stream<List<DashboardActivity>>.value(const [
        DashboardActivity(
          action: 'Created booking',
          actorRole: 'Central Admin',
        ),
      ]);
}

void main() {
  group('DashboardScreen', () {
    testWidgets('renders dashboard sections from injected streams',
        (tester) async {
      await tester.view.setPhysicalSize(const Size(1440, 1200));
      await tester.view.setDevicePixelRatio(1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DOJO WALK Command Center'), findsOneWidget);
      expect(find.text('Total Bookings'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Walkers'), findsOneWidget);
      expect(find.text('Paid Payments (All Time)'), findsOneWidget);
      expect(find.text('Live Operations'), findsOneWidget);
      expect(find.text('Booking Status'), findsOneWidget);
      expect(find.text('Recent Bookings'), findsOneWidget);
      expect(find.text('Booking #booking-001'), findsOneWidget);
      expect(find.text('Operations Alerts'), findsOneWidget);
      expect(find.text('System Activity'), findsOneWidget);
      expect(find.text('Created booking'), findsOneWidget);
      expect(find.text('Performed by Central Admin'), findsOneWidget);

      await tester.view.resetPhysicalSize();
      await tester.view.resetDevicePixelRatio();
    });

    testWidgets('header actions call the supplied navigation callbacks',
        (tester) async {
      var liveOperationsOpened = false;
      var serviceLocationsOpened = false;

      await tester.view.setPhysicalSize(const Size(1440, 1000));
      await tester.view.setDevicePixelRatio(1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              dataSource: _FakeDashboardDataSource(),
              onOpenLiveOperations: () => liveOperationsOpened = true,
              onOpenServiceLocations: () => serviceLocationsOpened = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Live Operations'));
      await tester.tap(find.text('Add / Manage Locations'));

      expect(liveOperationsOpened, isTrue);
      expect(serviceLocationsOpened, isTrue);

      await tester.view.resetPhysicalSize();
      await tester.view.resetDevicePixelRatio();
    });
  });
}
