/// DOJO WALK Admin
///
/// Gautam Buddha Nagar official village reference data.
///
/// Official source:
/// https://upbhulekh.gov.in/GeoDashboard/public_report?distCode=141
///
/// IMPORTANT:
/// 1. Government village codes must not be invented.
/// 2. Village records and service areas are different.
/// 3. Missing boundaries must remain unverified.
/// 4. This file contains verified source examples, not the
///    complete district village list.

enum VillageBoundaryStatus {
  notAvailable,
  pendingVerification,
  verified,
}

class GautamBuddhaNagarVillage {
  final String governmentCode;
  final String nameHindi;

  /// Name as shown by the official source.
  final String officialTehsilName;

  /// Internal DOJO WALK ID, not a government code.
  final String tehsilId;

  /// Official source for the record.
  final String sourceUrl;

  /// Government village code does not prove boundary accuracy.
  final VillageBoundaryStatus boundaryStatus;

  const GautamBuddhaNagarVillage({
    required this.governmentCode,
    required this.nameHindi,
    required this.officialTehsilName,
    required this.tehsilId,
    required this.sourceUrl,
    this.boundaryStatus = VillageBoundaryStatus.pendingVerification,
  });
}

class GautamBuddhaNagarVillages {
  GautamBuddhaNagarVillages._();

  static const String districtName = 'Gautam Buddha Nagar';
  static const String stateName = 'Uttar Pradesh';

  static const String dadriSource =
      'https://upbhulekh.gov.in/GeoDashboard/public_report'
      '?distCode=141&tehsilCode=00742';

  static const String sadarSource =
      'https://upbhulekh.gov.in/GeoDashboard/public_report'
      '?distCode=141&tehsilCode=00743';

  static const String jewarSource =
      'https://upbhulekh.gov.in/GeoDashboard/public_report'
      '?distCode=141&tehsilCode=00744';

  /// Initial source-checked records.
  ///
  /// This is intentionally not presented as the complete list.
  /// Add further records only after checking the official source.

  static const List<GautamBuddhaNagarVillage> records = [
    // --------------------------------------------------
    // DADRI — official source examples
    // --------------------------------------------------

    GautamBuddhaNagarVillage(
      governmentCode: '120128',
      nameHindi: 'अच्छेजा',
      officialTehsilName: 'Dadri',
      tehsilId: 'gbn_dadri',
      sourceUrl: dadriSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120217',
      nameHindi: 'अजायबपुर',
      officialTehsilName: 'Dadri',
      tehsilId: 'gbn_dadri',
      sourceUrl: dadriSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '216937',
      nameHindi: 'अलावर्दीपुर',
      officialTehsilName: 'Dadri',
      tehsilId: 'gbn_dadri',
      sourceUrl: dadriSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '216938',
      nameHindi: 'असगरपुर जागीर',
      officialTehsilName: 'Dadri',
      tehsilId: 'gbn_dadri',
      sourceUrl: dadriSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120135',
      nameHindi: 'आकलपुर जागीर',
      officialTehsilName: 'Dadri',
      tehsilId: 'gbn_dadri',
      sourceUrl: dadriSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '216939',
      nameHindi: 'आगाहपुर',
      officialTehsilName: 'Dadri',
      tehsilId: 'gbn_dadri',
      sourceUrl: dadriSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120202',
      nameHindi: 'आनन्दपुर',
      officialTehsilName: 'Dadri',
      tehsilId: 'gbn_dadri',
      sourceUrl: dadriSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120173',
      nameHindi: 'आमका',
      officialTehsilName: 'Dadri',
      tehsilId: 'gbn_dadri',
      sourceUrl: dadriSource,
    ),

    // --------------------------------------------------
    // GAUTAM BUDDHA NAGAR — official source examples
    // --------------------------------------------------

    GautamBuddhaNagarVillage(
      governmentCode: '120337',
      nameHindi: 'अछेजा बुजुर्ग',
      officialTehsilName: 'Gautam Buddha Nagar',
      tehsilId: 'gbn_sadar',
      sourceUrl: sadarSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120316',
      nameHindi: 'अटटा गुजरान',
      officialTehsilName: 'Gautam Buddha Nagar',
      tehsilId: 'gbn_sadar',
      sourceUrl: sadarSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120271',
      nameHindi: 'अटाई मुरादपुर',
      officialTehsilName: 'Gautam Buddha Nagar',
      tehsilId: 'gbn_sadar',
      sourceUrl: sadarSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120311',
      nameHindi: 'अमरपुर',
      officialTehsilName: 'Gautam Buddha Nagar',
      tehsilId: 'gbn_sadar',
      sourceUrl: sadarSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120274',
      nameHindi: 'अमीनाबाद उर्फ न्याना',
      officialTehsilName: 'Gautam Buddha Nagar',
      tehsilId: 'gbn_sadar',
      sourceUrl: sadarSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120234',
      nameHindi: 'असदुल्लापुर',
      officialTehsilName: 'Gautam Buddha Nagar',
      tehsilId: 'gbn_sadar',
      sourceUrl: sadarSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120291',
      nameHindi: 'अस्तौली',
      officialTehsilName: 'Gautam Buddha Nagar',
      tehsilId: 'gbn_sadar',
      sourceUrl: sadarSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120340',
      nameHindi: 'आछेपुर',
      officialTehsilName: 'Gautam Buddha Nagar',
      tehsilId: 'gbn_sadar',
      sourceUrl: sadarSource,
    ),

    // --------------------------------------------------
    // JEWAR — official source examples
    // --------------------------------------------------

    GautamBuddhaNagarVillage(
      governmentCode: '120363',
      nameHindi: 'अनवर गढ खादर',
      officialTehsilName: 'Jewar',
      tehsilId: 'gbn_jewar',
      sourceUrl: jewarSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120362',
      nameHindi: 'अनवरगढ बांगर',
      officialTehsilName: 'Jewar',
      tehsilId: 'gbn_jewar',
      sourceUrl: jewarSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120391',
      nameHindi: 'अमर पुर पलाका',
      officialTehsilName: 'Jewar',
      tehsilId: 'gbn_jewar',
      sourceUrl: jewarSource,
    ),
    GautamBuddhaNagarVillage(
      governmentCode: '120372',
      nameHindi: 'अमानुल्लापुर उर्फमारहरा',
      officialTehsilName: 'Jewar',
      tehsilId: 'gbn_jewar',
      sourceUrl: jewarSource,
    ),
  ];

  static List<GautamBuddhaNagarVillage> byTehsil(String tehsilId) {
    return records
        .where((village) => village.tehsilId == tehsilId)
        .toList(growable: false);
  }

  static GautamBuddhaNagarVillage? byGovernmentCode(String code) {
    for (final village in records) {
      if (village.governmentCode == code) {
        return village;
      }
    }

    return null;
  }
}
