import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pioquinto_advmobprog/models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  //   USERS  
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        user['uid'] = doc.id;
        return user;
      }).toList();
    });
  }

  //   MESSAGES  
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String? currentUserEmail = _firebaseAuth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();

    MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? "",
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      status: 'sending…',
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    // Add new message
    final docRef = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .add(newMessage.toMap());

    // Update status to delivered
    await docRef.update({'status': '✓'});
  }

  Stream<QuerySnapshot> getMessage(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(
      String messageId, String currentUserId, String otherUserId) async {
    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'status': '✓✓'});
  }

  //   FIND UID  
  Future<String?> getUidByEmail(String email) async {
    final result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;
    return result.docs.first.data()['uid']?.toString();
  }

  //   TYPING  
  Future<void> updateTypingStatus(
      String currentUserId, String otherUserId, bool isTyping) async {
    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'typingStatus': {currentUserId: isTyping}
    }, SetOptions(merge: true));
  }

  Stream<bool> getTypingStream(String otherUserId, String currentUserId) {
    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore.collection('chat_rooms').doc(chatRoomId).snapshots().map(
      (snapshot) {
        final data = snapshot.data();
        if (data == null) return false;
        final typingMap = data['typingStatus'] as Map<String, dynamic>? ?? {};
        return typingMap[otherUserId] == true;
      },
    );
  }
}
