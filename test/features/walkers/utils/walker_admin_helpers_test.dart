import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_walk_admin/features/walkers/utils/walker_admin_helpers.dart';

void main() {
  group('WalkerAdminHelpers.documentReference', () {
    test('prefers canonical Storage path over legacy URL', () {
      final reference = WalkerAdminHelpers.documentReference({
        'downloadUrl': 'https://legacy.example.test/kyc/front.jpg',
        'storagePath': 'walker_documents/walker_123/aadhaar_front_1730000000000.jpg',
      });

      expect(
        reference,
        'walker_documents/walker_123/aadhaar_front_1730000000000.jpg',
      );
    });

    test('supports canonical path alias when storagePath is absent', () {
      expect(
        WalkerAdminHelpers.documentReference({
          'path': 'walker_documents/walker_123/pan_card_1730000000000.jpg',
          'url': 'https://legacy.example.test/kyc/pan.jpg',
        }),
        'walker_documents/walker_123/pan_card_1730000000000.jpg',
      );
    });

    test('retains legacy URL as fallback for migration detection', () {
      const legacyUrl = 'https://legacy.example.test/kyc/front.jpg';

      expect(
        WalkerAdminHelpers.documentReference({'downloadUrl': legacyUrl}),
        legacyUrl,
      );
      expect(WalkerAdminHelpers.isHttpUrl(legacyUrl), isTrue);
    });

    test('returns null when no usable reference exists', () {
      expect(WalkerAdminHelpers.documentReference(null), isNull);
      expect(WalkerAdminHelpers.documentReference({}), isNull);
      expect(
        WalkerAdminHelpers.documentReference({
          'storagePath': ' ',
          'downloadUrl': '',
        }),
        isNull,
      );
    });
  });
}
