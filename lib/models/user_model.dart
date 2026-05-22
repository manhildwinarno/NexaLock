class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' or 'user'
  final String? rfidUid;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.rfidUid,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      rfidUid: json['rfid_uid'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      if (rfidUid != null) 'rfid_uid': rfidUid,
    };
  }

  bool get isAdmin => role == 'admin';
}
