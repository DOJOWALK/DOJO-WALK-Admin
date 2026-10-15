/// DOJO WALK Admin
///
/// Administrative divisions of Gautam Buddha Nagar, Uttar Pradesh.
///
/// Official reference:
/// https://gbnagar.nic.in/demography/
/// https://gbnagar.nic.in/tehsil/
/// https://gbnagar.nic.in/subdivision-blocks/
///
/// Important:
/// - Internal IDs below are DOJO WALK IDs, not government codes.
/// - Tehsil and development block are separate administrative levels.
/// - This file does not define service coverage or map boundaries.
/// - Village records will be maintained in a separate file.

enum AdministrativeDivisionType {
  tehsil,
  developmentBlock,
}

class GautamBuddhaNagarDivision {
  final String id;
  final String name;
  final String localName;
  final AdministrativeDivisionType type;

  /// Parent tehsil ID.
  ///
  /// Null for tehsils.
  /// Required for development blocks.
  final String? parentTehsilId;

  const GautamBuddhaNagarDivision({
    required this.id,
    required this.name,
    required this.localName,
    required this.type,
    this.parentTehsilId,
  });
}

class GautamBuddhaNagarAdminDivisions {
  GautamBuddhaNagarAdminDivisions._();

  static const String stateName = 'Uttar Pradesh';
  static const String districtName = 'Gautam Buddha Nagar';

  static const String sourceUrl =
      'https://gbnagar.nic.in/demography/';

  // --------------------------------------------------
  // TEHSILS
  // --------------------------------------------------

  static const String sadarTehsilId = 'gbn_sadar';
  static const String dadriTehsilId = 'gbn_dadri';
  static const String jewarTehsilId = 'gbn_jewar';

  static const List<GautamBuddhaNagarDivision> tehsils = [
    GautamBuddhaNagarDivision(
      id: sadarTehsilId,
      name: 'Sadar',
      localName: 'सदर',
      type: AdministrativeDivisionType.tehsil,
    ),
    GautamBuddhaNagarDivision(
      id: dadriTehsilId,
      name: 'Dadri',
      localName: 'दादरी',
      type: AdministrativeDivisionType.tehsil,
    ),
    GautamBuddhaNagarDivision(
      id: jewarTehsilId,
      name: 'Jewar',
      localName: 'जेवर',
      type: AdministrativeDivisionType.tehsil,
    ),
  ];

  // --------------------------------------------------
  // DEVELOPMENT BLOCKS
  // --------------------------------------------------

  static const List<GautamBuddhaNagarDivision> developmentBlocks = [
    GautamBuddhaNagarDivision(
      id: 'gbn_bisrakh',
      name: 'Bisrakh',
      localName: 'बिसरख',
      type: AdministrativeDivisionType.developmentBlock,
      parentTehsilId: dadriTehsilId,
    ),
    GautamBuddhaNagarDivision(
      id: 'gbn_dadri_block',
      name: 'Dadri',
      localName: 'दादरी',
      type: AdministrativeDivisionType.developmentBlock,
      parentTehsilId: dadriTehsilId,
    ),
    GautamBuddhaNagarDivision(
      id: 'gbn_dankaur',
      name: 'Dankaur',
      localName: 'दनकौर',
      type: AdministrativeDivisionType.developmentBlock,
      parentTehsilId: sadarTehsilId,
    ),
    GautamBuddhaNagarDivision(
      id: 'gbn_jewar_block',
      name: 'Jewar',
      localName: 'जेवर',
      type: AdministrativeDivisionType.developmentBlock,
      parentTehsilId: jewarTehsilId,
    ),
  ];

  // --------------------------------------------------
  // LOOKUP HELPERS
  // --------------------------------------------------

  static List<GautamBuddhaNagarDivision> get allDivisions => [
        ...tehsils,
        ...developmentBlocks,
      ];

  static List<GautamBuddhaNagarDivision> blocksForTehsil(
    String tehsilId,
  ) {
    return developmentBlocks
        .where((block) => block.parentTehsilId == tehsilId)
        .toList(growable: false);
  }

  static GautamBuddhaNagarDivision? tehsilById(String id) {
    for (final tehsil in tehsils) {
      if (tehsil.id == id) {
        return tehsil;
      }
    }

    return null;
  }

  static GautamBuddhaNagarDivision? blockById(String id) {
    for (final block in developmentBlocks) {
      if (block.id == id) {
        return block;
      }
    }

    return null;
  }
}
