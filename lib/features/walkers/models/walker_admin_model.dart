import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared data model for DOJO WALK Admin Walker Management.
///
/// Converts Firestore walker documents into a consistent model.
class WalkerAdminModel {
  const WalkerAdminModel({
    required this.id,
    required this.name,
    required this.status,
    required this.verificationStatus,
    required this.isActive,
    required this.isApproved,
    this.phone,
    this.email,
    this.photoUrl,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.city,
    this.state,
    this.area,
    this.zone,
    this.createdAt,
    this.updatedAt,
    this.applicationSubmitted = false,
    this.additionalData = const {},
  });

  final String id;
  final String name;
  final String status;
  final String verificationStatus;

  final bool isActive;
  final bool isApproved;
  final bool applicationSubmitted;

  final String? phone;
  final String? email;
  final String? photoUrl;
  final String? gender;
  final String? dateOfBirth;

  final String? address;
  final String? city;
  final String? state;
  final String? area;
  final String? zone;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Preserves other existing Firestore fields.
  final Map<String, dynamic> additionalData;

  /// Creates a model from a Firestore document.
  factory WalkerAdminModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return WalkerAdminModel.fromMap(
      id: document.id,
      data: data,
    );
  }

  /// Creates a model from a document ID and data map.
  factory WalkerAdminModel.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final knownKeys = <String>{
      'walkerId',
      'name',
      'fullName',
      'displayName',
      'phone',
      'phoneNumber',
      'mobile',
      'email',
      'photoUrl',
      'profilePhoto',
      'profileImage',
      'gender',
      'dateOfBirth',
      'dob',
      'status',
      'verificationStatus',
      'isActive',
      'isApproved',
      'applicationSubmitted',
      'address',
      'currentAddress',
      'city',
      'state',
      'area',
      'zone',
      'zoneName',
      'createdAt',
      'updatedAt',
    };

    return WalkerAdminModel(
      id: id,
      name: _firstString(data, [
        'name',
        'fullName',
        'displayName',
      ]) ?? 'Walker',
      status: _stringValue(data['status']) ?? 'pending',
      verificationStatus:
          _stringValue(data['verificationStatus']) ?? 'pending',
      isActive: data['isActive'] == true,
      isApproved: data['isApproved'] == true,
      applicationSubmitted: data['applicationSubmitted'] == true,
      phone: _firstString(data, [
        'phone',
        'phoneNumber',
        'mobile',
      ]),
      email: _stringValue(data['email']),
      photoUrl: _firstString(data, [
        'photoUrl',
        'profilePhoto',
        'profileImage',
      ]),
      gender: _stringValue(data['gender']),
      dateOfBirth: _firstString(data, [
        'dateOfBirth',
        'dob',
      ]),
      address: _firstString(data, [
        'address',
        'currentAddress',
      ]),
      city: _stringValue(data['city']),
      state: _stringValue(data['state']),
      area: _stringValue(data['area']),
      zone: _firstString(data, [
        'zone',
        'zoneName',
      ]),
      createdAt: _dateTimeValue(data['createdAt']),
      updatedAt: _dateTimeValue(data['updatedAt']),
      additionalData: Map<String, dynamic>.fromEntries(
        data.entries.where(
          (entry) => !knownKeys.contains(entry.key),
        ),
      ),
    );
  }

  /// Converts the model to a map.
  ///
  /// By default, this excludes fields that should normally be
  /// controlled by the server or admin decision workflow.
  Map<String, dynamic> toMap() {
    return {
      ...additionalData,
      'walkerId': id,
      'name': name,
      'status': status,
      'verificationStatus': verificationStatus,
      'isActive': isActive,
      'isApproved': isApproved,
      'applicationSubmitted': applicationSubmitted,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (area != null) 'area': area,
      if (zone != null) 'zone': zone,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Returns a new model with selected values changed.
  WalkerAdminModel copyWith({
    String? name,
    String? status,
    String? verificationStatus,
    bool? isActive,
    bool? isApproved,
    bool? applicationSubmitted,
    String? phone,
    String? email,
    String? photoUrl,
    String? gender,
    String? dateOfBirth,
    String? address,
    String? city,
    String? state,
    String? area,
    String? zone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalkerAdminModel(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      verificationStatus:
          verificationStatus ?? this.verificationStatus,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      applicationSubmitted:
          applicationSubmitted ?? this.applicationSubmitted,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      area: area ?? this.area,
      zone: zone ?? this.zone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalData: additionalData,
    );
  }

  static String? _stringValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return null;
  }

  static String? _firstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = _stringValue(data[key]);

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  static DateTime? _dateTimeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }

    return null;
  }
}
