class Address {
  final String id;
  final String fullName;
  final String addressLine1; // House/Street/Road/Area
  final String? addressLine2; // Floor, Apt, Suite, Landmark
  final String city; // City or Upazila
  final String division; // Bangladesh Division (Dhaka, Chattogram, etc.)
  final String district; // Bangladesh District (Dhaka, Gazipur, etc.)
  final String thana; // Upazila or Thana (Gulshan, Banani, etc.)
  final String postalCode; // 4-digit BD Postal Code
  final String country; // "Bangladesh"
  final String phone; // BD Mobile Phone (+8801XXXXXXXXX)
  final bool isDefault;

  const Address({
    required this.id,
    required this.fullName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.division = 'Dhaka',
    this.district = 'Dhaka',
    this.thana = 'Gulshan',
    required this.postalCode,
    this.country = 'Bangladesh',
    required this.phone,
    this.isDefault = false,
  });

  /// Formatted localized address line
  String get formattedAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2!,
      if (thana.isNotEmpty && thana != city) thana,
      if (district.isNotEmpty && district != city) district else city,
      if (division.isNotEmpty && division != district) division,
      if (postalCode.isNotEmpty) postalCode,
      country,
    ];
    return parts.join(', ');
  }

  Address copyWith({
    String? id,
    String? fullName,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? division,
    String? district,
    String? thana,
    String? postalCode,
    String? country,
    String? phone,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      division: division ?? this.division,
      district: district ?? this.district,
      thana: thana ?? this.thana,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'division': division,
      'district': district,
      'thana': thana,
      'postalCode': postalCode,
      'country': country,
      'phone': phone,
      'isDefault': isDefault,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    final cityVal = json['city'] as String? ?? 'Dhaka';
    return Address(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      addressLine1: json['addressLine1'] as String? ?? '',
      addressLine2: json['addressLine2'] as String?,
      city: cityVal,
      division: json['division'] as String? ?? 'Dhaka',
      district: json['district'] as String? ?? cityVal,
      thana: json['thana'] as String? ?? 'Gulshan',
      postalCode: json['postalCode'] as String? ?? '1212',
      country: json['country'] as String? ?? 'Bangladesh',
      phone: json['phone'] as String? ?? '+8801700000000',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
