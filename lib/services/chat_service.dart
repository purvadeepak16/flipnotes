import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Get stream of all groups
  Stream<List<ChatGroup>> getGroupsStream() {
    return _db.collection('groups').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ChatGroup.fromFirestore(doc)).toList();
    });
  }

  // Create a new group
  Future<void> createGroup(String name, String description, String userId) async {
    try {
      final groupId = _uuid.v4();
      final group = ChatGroup(
        id: groupId,
        name: name,
        description: description,
        memberIds: [userId], // Creator is the first member
        createdBy: userId,
        createdAt: Timestamp.now(),
      );

      await _db.collection('groups').doc(groupId).set(group.toMap());
    } catch (e) {
      print('Error creating group: $e');
      rethrow;
    }
  }

  // Join a group
  Future<void> joinGroup(String groupId, String userId) async {
    try {
      await _db.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print('Error joining group: $e');
      rethrow;
    }
  }

  // Get stream of messages for a specific group
  Stream<List<ChatMessage>> getGroupMessagesStream(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  // Send a message
  Future<void> sendMessage(String groupId, String userId, String userName, String text) async {
    try {
      final messageId = _uuid.v4();
      final message = ChatMessage(
        id: messageId,
        senderId: userId,
        senderName: userName,
        text: text,
        timestamp: Timestamp.now(),
      );

      await _db
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}
