import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final DateTime joinedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    required this.joinedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };

  UserModel copyWith({String? name, String? email, String? avatarUrl}) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedAt: joinedAt,
    );
  }
}
