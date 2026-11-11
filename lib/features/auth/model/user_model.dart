class UserModel {
  final String email;
  final String password;
  final String name;
  final String uid;
  final String? imageUrl; 

  UserModel({
    required this.email,
    required this.password,
    required this.name,
    required this.uid,
    this.imageUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      name: map['name'] ?? '',
      uid: map['uid'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'uid': uid,
      'imageUrl': imageUrl,
    };
  }
}