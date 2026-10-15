/// DOJO WALK Admin
///
/// National Capital Region (NCR) constituent areas.
///
/// Source:
/// National Capital Region Planning Board (NCRPB)
///
/// Important:
/// - This file defines NCR membership, not service coverage.
/// - Delhi is represented as the whole NCT region.
/// - Districts and service areas must remain separate.
/// - Verify against the latest official NCR notification
///   before marking this dataset as final.

enum NcrAreaType {
  entireNationalCapitalTerritory,
  district,
}

class NcrConstituentArea {
  final String id;
  final String stateName;
  final String name;
  final NcrAreaType type;

  const NcrConstituentArea({
    required this.id,
    required this.stateName,
    required this.name,
    required this.type,
  });
}

class NcrConstituentAreas {
  NcrConstituentAreas._();

  static const String source =
      'National Capital Region Planning Board (NCRPB)';

  static const List<NcrConstituentArea> all = [
    // --------------------------------------------------
    // DELHI
    // NCR includes the entire NCT of Delhi.
    // Individual Delhi districts will be maintained
    // separately in the administrative reference dataset.
    // --------------------------------------------------

    NcrConstituentArea(
      id: 'ncr_delhi_nct',
      stateName: 'Delhi',
      name: 'Entire National Capital Territory of Delhi',
      type: NcrAreaType.entireNationalCapitalTerritory,
    ),

    // --------------------------------------------------
    // HARYANA — 14 DISTRICTS
    // --------------------------------------------------

    NcrConstituentArea(
      id: 'ncr_hr_faridabad',
      stateName: 'Haryana',
      name: 'Faridabad',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_gurugram',
      stateName: 'Haryana',
      name: 'Gurugram',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_nuh',
      stateName: 'Haryana',
      name: 'Nuh',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_rohtak',
      stateName: 'Haryana',
      name: 'Rohtak',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_sonipat',
      stateName: 'Haryana',
      name: 'Sonipat',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_rewari',
      stateName: 'Haryana',
      name: 'Rewari',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_jhajjar',
      stateName: 'Haryana',
      name: 'Jhajjar',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_panipat',
      stateName: 'Haryana',
      name: 'Panipat',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_palwal',
      stateName: 'Haryana',
      name: 'Palwal',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_bhiwani',
      stateName: 'Haryana',
      name: 'Bhiwani',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_charkhi_dadri',
      stateName: 'Haryana',
      name: 'Charkhi Dadri',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_mahendragarh',
      stateName: 'Haryana',
      name: 'Mahendragarh',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_jind',
      stateName: 'Haryana',
      name: 'Jind',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_hr_karnal',
      stateName: 'Haryana',
      name: 'Karnal',
      type: NcrAreaType.district,
    ),

    // --------------------------------------------------
    // UTTAR PRADESH — 8 DISTRICTS
    // --------------------------------------------------

    NcrConstituentArea(
      id: 'ncr_up_meerut',
      stateName: 'Uttar Pradesh',
      name: 'Meerut',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_up_ghaziabad',
      stateName: 'Uttar Pradesh',
      name: 'Ghaziabad',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_up_gautam_buddha_nagar',
      stateName: 'Uttar Pradesh',
      name: 'Gautam Buddha Nagar',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_up_bulandshahr',
      stateName: 'Uttar Pradesh',
      name: 'Bulandshahr',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_up_baghpat',
      stateName: 'Uttar Pradesh',
      name: 'Baghpat',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_up_hapur',
      stateName: 'Uttar Pradesh',
      name: 'Hapur',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_up_shamli',
      stateName: 'Uttar Pradesh',
      name: 'Shamli',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_up_muzaffarnagar',
      stateName: 'Uttar Pradesh',
      name: 'Muzaffarnagar',
      type: NcrAreaType.district,
    ),

    // --------------------------------------------------
    // RAJASTHAN — 2 DISTRICTS
    // --------------------------------------------------

    NcrConstituentArea(
      id: 'ncr_rj_alwar',
      stateName: 'Rajasthan',
      name: 'Alwar',
      type: NcrAreaType.district,
    ),
    NcrConstituentArea(
      id: 'ncr_rj_bharatpur',
      stateName: 'Rajasthan',
      name: 'Bharatpur',
      type: NcrAreaType.district,
    ),
  ];

  static List<NcrConstituentArea> byState(String stateName) {
    return all
        .where((area) => area.stateName == stateName)
        .toList(growable: false);
  }

  static List<NcrConstituentArea> get districts {
    return all
        .where((area) => area.type == NcrAreaType.district)
        .toList(growable: false);
  }

  static List<String> get states {
    return all
        .map((area) => area.stateName)
        .toSet()
        .toList(growable: false);
  }
}
