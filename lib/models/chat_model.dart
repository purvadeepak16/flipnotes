import 'package:cloud_firestore/cloud_firestore.dart';

class ChatGroup {
  final String id;
  final String name;
  final String description;
  final List<String> memberIds;
  final String createdBy;
  final Timestamp createdAt;

  ChatGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.memberIds,
    required this.createdBy,
    required this.createdAt,
  });

  factory ChatGroup.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatGroup(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'memberIds': memberIds,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final Timestamp timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
