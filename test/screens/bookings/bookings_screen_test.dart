import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/screens/bookings/booking_data_source.dart';
import 'package:dojo_admin/screens/bookings/bookings_screen.dart';

class _FakeBookingsDataSource implements BookingsDataSource {
  _FakeBookingsDataSource(this.stream);

  final Stream<List<BookingRecord>> stream;

  @override
  Stream<List<BookingRecord>> watchBookings() => stream;
}

Widget _screen(BookingsDataSource source) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 800,
        child: BookingsScreen(dataSource: source),
      ),
    ),
  );
}

void main() {
  testWidgets('shows loading while the booking stream is waiting',
      (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await controller.close();
  });

  testWidgets('renders booking data and canonical lifecycle status',
      (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));
    controller.add([
      const BookingRecord(
        id: 'DW-1001',
        data: {
          'status': 'picked_up',
          'customerName': 'Asha',
          'walkerName': 'Ravi',
          'createdAt': '2026-10-31T08:00:00Z',
          'walkDateTime': '2026-10-31T09:00:00Z',
          'amount': 149,
        },
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Booking DW-1001'), findsOneWidget);
    expect(find.text('Picked Up'), findsOneWidget);
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Ravi'), findsOneWidget);
    expect(find.text('₹149'), findsOneWidget);
    await controller.close();
  });

  testWidgets('shows empty Firestore state when stream has no records',
      (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));
    controller.add(const []);
    await tester.pump();
    await tester.pump();

    expect(find.text('No bookings found in Firestore.'), findsOneWidget);
    await controller.close();
  });

  testWidgets('shows permission denied state without mutating data',
      (tester) async {
    final controller = StreamController<List<BookingRecord>>();
    await tester.pumpWidget(_screen(_FakeBookingsDataSource(controller.stream)));
    controller.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Permission denied'), findsOneWidget);
    expect(find.textContaining('No booking status has been changed.'), findsNothing);
    await controller.close();
  });
}
