class UserAddress {
  final String id;
  final String? label;
  final String? province;
  final String? city;
  final String? district;
  final String? postalCode;
  final String? street;
  final String? extraDetail;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserAddress({
    required this.id,
    this.label,
    this.province,
    this.city,
    this.district,
    this.postalCode,
    this.street,
    this.extraDetail,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  UserAddress copyWith({
    String? id,
    String? label,
    String? province,
    String? city,
    String? district,
    String? postalCode,
    String? street,
    String? extraDetail,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      province: province ?? this.province,
      city: city ?? this.city,
      district: district ?? this.district,
      postalCode: postalCode ?? this.postalCode,
      street: street ?? this.street,
      extraDetail: extraDetail ?? this.extraDetail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      id: map['id']?.toString() ?? '',
      label: map['label'] as String?,
      province: map['province'] as String?,
      city: map['city'] as String?,
      district: map['district'] as String?,
      postalCode: map['postal_code'] as String?,
      street: map['street'] as String?,
      extraDetail: map['extra_detail'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isDefault: (map['is_default'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap({required String owner}) {
    return {
      'id': id,
      'owner': owner,
      if (label != null && label!.isNotEmpty) 'label': label,
      if (province != null && province!.isNotEmpty) 'province': province,
      if (city != null && city!.isNotEmpty) 'city': city,
      if (district != null && district!.isNotEmpty) 'district': district,
      if (postalCode != null && postalCode!.isNotEmpty)
        'postal_code': postalCode,
      if (street != null && street!.isNotEmpty) 'street': street,
      if (extraDetail != null && extraDetail!.isNotEmpty)
        'extra_detail': extraDetail,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_default': isDefault,
    };
  }
}
