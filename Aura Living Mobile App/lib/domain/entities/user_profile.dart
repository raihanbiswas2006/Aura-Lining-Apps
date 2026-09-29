import 'address.dart';

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final List<Address> addresses;
  final bool isGuest;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.addresses = const [],
    this.isGuest = false,
  });

  Address? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? avatarUrl,
    List<Address>? addresses,
    bool? isGuest,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      addresses: addresses ?? this.addresses,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'addresses': addresses.map((a) => a.toJson()).toList(),
      'isGuest': isGuest,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? 'Guest User',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      addresses: json['addresses'] != null
          ? (json['addresses'] as List)
              .map((a) => Address.fromJson(a as Map<String, dynamic>))
              .toList()
          : const [],
      isGuest: json['isGuest'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
