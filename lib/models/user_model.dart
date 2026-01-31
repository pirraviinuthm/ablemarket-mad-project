class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // e.g., 'buyer' or 'seller'

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
  });

  // Convert User Object to JSON (Map) for Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'createdAt': DateTime.now(),
    };
  }
}