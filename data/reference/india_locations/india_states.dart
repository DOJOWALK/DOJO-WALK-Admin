/// DOJO WALK Admin
/// India States and Union Territories Reference Data.
///
/// Source data: User-provided LGD state/UT list.
/// LGD codes are stored as integers.
/// Census codes are stored as strings to preserve leading zeros.

class IndiaState {
  final int lgdCode;
  final String name;
  final String localName;
  final String type;
  final String? census2001Code;
  final String? census2011Code;

  const IndiaState({
    required this.lgdCode,
    required this.name,
    required this.localName,
    required this.type,
    this.census2001Code,
    this.census2011Code,
  });

  bool get isUnionTerritory => type == 'UT';

  bool get isState => type == 'State';

  Map<String, dynamic> toJson() {
    return {
      'lgdCode': lgdCode,
      'name': name,
      'localName': localName,
      'type': type,
      'census2001Code': census2001Code,
      'census2011Code': census2011Code,
    };
  }

  factory IndiaState.fromJson(Map<String, dynamic> json) {
    return IndiaState(
      lgdCode: (json['lgdCode'] as num).toInt(),
      name: json['name'] as String,
      localName: json['localName'] as String,
      type: json['type'] as String,
      census2001Code: json['census2001Code'] as String?,
      census2011Code: json['census2011Code'] as String?,
    );
  }
}

/// All 36 Indian States and Union Territories.
const List<IndiaState> indiaStates = [
  IndiaState(
    lgdCode: 35,
    name: 'Andaman And Nicobar Islands',
    localName: 'ANDAMAN AND NICOBAR ISLANDS',
    type: 'UT',
    census2001Code: '35',
    census2011Code: '35',
  ),
  IndiaState(
    lgdCode: 28,
    name: 'Andhra Pradesh',
    localName: 'ANDHRA PRADESH',
    type: 'State',
    census2001Code: '28',
    census2011Code: '28',
  ),
  IndiaState(
    lgdCode: 12,
    name: 'Arunachal Pradesh',
    localName: 'ARUNACHAL PRADESH',
    type: 'State',
    census2001Code: '12',
    census2011Code: '12',
  ),
  IndiaState(
    lgdCode: 18,
    name: 'Assam',
    localName: 'ASSAM',
    type: 'State',
    census2001Code: '18',
    census2011Code: '18',
  ),
  IndiaState(
    lgdCode: 10,
    name: 'Bihar',
    localName: 'BIHAR',
    type: 'State',
    census2001Code: '10',
    census2011Code: '10',
  ),
  IndiaState(
    lgdCode: 4,
    name: 'Chandigarh',
    localName: 'CHANDIGARH',
    type: 'UT',
    census2001Code: '04',
    census2011Code: '04',
  ),
  IndiaState(
    lgdCode: 22,
    name: 'Chhattisgarh',
    localName: 'छत्तीसगढ़',
    type: 'State',
    census2001Code: '22',
    census2011Code: '22',
  ),
  IndiaState(
    lgdCode: 7,
    name: 'Delhi',
    localName: 'DELHI',
    type: 'UT',
    census2001Code: '07',
    census2011Code: '07',
  ),
  IndiaState(
    lgdCode: 30,
    name: 'Goa',
    localName: 'GOA',
    type: 'State',
    census2001Code: '30',
    census2011Code: '30',
  ),
  IndiaState(
    lgdCode: 24,
    name: 'Gujarat',
    localName: 'GUJARAT',
    type: 'State',
    census2001Code: '24',
    census2011Code: '24',
  ),
  IndiaState(
    lgdCode: 6,
    name: 'Haryana',
    localName: 'HARYANA',
    type: 'State',
    census2001Code: '06',
    census2011Code: '06',
  ),
  IndiaState(
    lgdCode: 2,
    name: 'Himachal Pradesh',
    localName: 'HIMACHAL PRADESH',
    type: 'State',
    census2001Code: '02',
    census2011Code: '02',
  ),
  IndiaState(
    lgdCode: 1,
    name: 'Jammu And Kashmir',
    localName: 'JAMMU AND KASHMIR',
    type: 'UT',
    census2001Code: '01',
    census2011Code: '01',
  ),
  IndiaState(
    lgdCode: 20,
    name: 'Jharkhand',
    localName: 'झारखंड',
    type: 'State',
    census2001Code: '20',
    census2011Code: '20',
  ),
  IndiaState(
    lgdCode: 29,
    name: 'Karnataka',
    localName: 'ಕರ್ನಾಟಕ',
    type: 'State',
    census2001Code: '29',
    census2011Code: '29',
  ),
  IndiaState(
    lgdCode: 32,
    name: 'Kerala',
    localName: 'KERALA',
    type: 'State',
    census2001Code: '32',
    census2011Code: '32',
  ),
  IndiaState(
    lgdCode: 37,
    name: 'Ladakh',
    localName: 'Ladakh',
    type: 'UT',
    census2001Code: null,
    census2011Code: '00',
  ),
  IndiaState(
    lgdCode: 31,
    name: 'Lakshadweep',
    localName: 'LAKSHADWEEP',
    type: 'UT',
    census2001Code: '31',
    census2011Code: '31',
  ),
  IndiaState(
    lgdCode: 23,
    name: 'Madhya Pradesh',
    localName: 'MADHYA PRADESH',
    type: 'State',
    census2001Code: '23',
    census2011Code: '23',
  ),
  IndiaState(
    lgdCode: 27,
    name: 'Maharashtra',
    localName: 'महाराष्ट्र',
    type: 'State',
    census2001Code: '27',
    census2011Code: '27',
  ),
  IndiaState(
    lgdCode: 14,
    name: 'Manipur',
    localName: 'MANIPUR',
    type: 'State',
    census2001Code: '14',
    census2011Code: '14',
  ),
  IndiaState(
    lgdCode: 17,
    name: 'Meghalaya',
    localName: 'MEGHALAYA',
    type: 'State',
    census2001Code: '17',
    census2011Code: '17',
  ),
  IndiaState(
    lgdCode: 15,
    name: 'Mizoram',
    localName: 'MIZORAM',
    type: 'State',
    census2001Code: '15',
    census2011Code: '15',
  ),
  IndiaState(
    lgdCode: 13,
    name: 'Nagaland',
    localName: 'NAGALAND',
    type: 'State',
    census2001Code: '13',
    census2011Code: '13',
  ),
  IndiaState(
    lgdCode: 21,
    name: 'Odisha',
    localName: 'ଓଡ଼ିଶା',
    type: 'State',
    census2001Code: '21',
    census2011Code: '21',
  ),
  IndiaState(
    lgdCode: 34,
    name: 'Puducherry',
    localName: 'PUDUCHERRY',
    type: 'UT',
    census2001Code: '34',
    census2011Code: '34',
  ),
  IndiaState(
    lgdCode: 3,
    name: 'Punjab',
    localName: 'PUNJAB',
    type: 'State',
    census2001Code: '03',
    census2011Code: '03',
  ),
  IndiaState(
    lgdCode: 8,
    name: 'Rajasthan',
    localName: 'RAJASTHAN',
    type: 'State',
    census2001Code: '08',
    census2011Code: '08',
  ),
  IndiaState(
    lgdCode: 11,
    name: 'Sikkim',
    localName: 'SIKKIM',
    type: 'State',
    census2001Code: '11',
    census2011Code: '11',
  ),
  IndiaState(
    lgdCode: 33,
    name: 'Tamil Nadu',
    localName: 'TAMIL NADU',
    type: 'State',
    census2001Code: '33',
    census2011Code: '33',
  ),
  IndiaState(
    lgdCode: 36,
    name: 'Telangana',
    localName: 'తెలంగాణ',
    type: 'State',
    census2001Code: null,
    census2011Code: '00',
  ),
  IndiaState(
    lgdCode: 38,
    name: 'The Dadra And Nagar Haveli And Daman And Diu',
    localName: 'THE DADRA AND NAGAR HAVELI AND DAMAN AND DIU',
    type: 'UT',
    census2001Code: null,
    census2011Code: null,
  ),
  IndiaState(
    lgdCode: 16,
    name: 'Tripura',
    localName: 'ত্রিপুরা',
    type: 'State',
    census2001Code: '16',
    census2011Code: '16',
  ),
  IndiaState(
    lgdCode: 5,
    name: 'Uttarakhand',
    localName: 'UTTARAKHAND',
    type: 'State',
    census2001Code: '05',
    census2011Code: '05',
  ),
  IndiaState(
    lgdCode: 9,
    name: 'Uttar Pradesh',
    localName: 'UTTAR PRADESH',
    type: 'State',
    census2001Code: '09',
    census2011Code: '09',
  ),
  IndiaState(
    lgdCode: 19,
    name: 'West Bengal',
    localName: 'WEST BENGAL',
    type: 'State',
    census2001Code: '19',
    census2011Code: '19',
  ),
];

/// All State entries.
List<IndiaState> get indiaOnlyStates =>
    indiaStates.where((item) => item.isState).toList(growable: false);

/// All Union Territory entries.
List<IndiaState> get indiaUnionTerritories =>
    indiaStates.where((item) => item.isUnionTerritory).toList(growable: false);

/// Find a state or UT using its LGD code.
IndiaState? findIndiaStateByLgdCode(int code) {
  for (final state in indiaStates) {
    if (state.lgdCode == code) return state;
  }
  return null;
}
