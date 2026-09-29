import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message_model.dart';

/// Firestore layer for the one-to-one chat.
///
/// Three collections are involved:
///   Users/{uid}                              — directory of registered accounts
///   chat_rooms/{chatRoomId}                  — one conversation (implicit doc)
///   chat_rooms/{chatRoomId}/messages/{auto}  — the messages themselves
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Both participants must land on the same room no matter who opens the
  /// conversation first, so the two uids are sorted before being joined.
  /// Chatting yourself collapses this to "uid_uid", which is a valid — if
  /// degenerate — room; the chat list hides that case rather than the data
  /// model forbidding it.
  String _chatRoomId(String a, String b) {
    final List<String> ids = [a, b];
    ids.sort();
    return ids.join('_');
  }

  /// Mirror a signed-in account into the Users collection.
  ///
  /// Called from UserService.saveFirebaseUserData(), which runs on both signup
  /// and every sign-in, so accounts created before this collection existed get
  /// backfilled the next time they log in. The document id is the uid and the
  /// uid is also stored as a field, because getUidByEmail() reads the field.
  Future<void> upsertUser({
    required String uid,
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    String image = '',
  }) async {
    if (uid.isEmpty) return;

    final docRef = _firestore.collection('Users').doc(uid);
    final snapshot = await docRef.get();

    await docRef.set({
      'uid': uid,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'image': image,
      // Only stamped on the first write, so a later sign-in does not reset it.
      if (!snapshot.exists) 'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  /// Get all users. The caller filters out the logged-in account and applies
  /// the search term — keeping this stream unfiltered means one Firestore
  /// listener serves both.
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        // Documents written by hand in the console may lack the uid field;
        // the document id is authoritative either way.
        user['uid'] = (user['uid'] ?? doc.id).toString();
        return user;
      }).toList();
    });
  }

  /// Send a message to [receiverId].
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String? currentUserEmail = _firebaseAuth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();

    final MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? '',
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    await _firestore
        .collection('chat_rooms')
        .doc(_chatRoomId(currentUserId, receiverId))
        .collection('messages')
        .add(newMessage.toMap());
  }

  /// Stream the conversation between two users, newest first.
  ///
  /// includeMetadataChanges is what makes the "sending…" state real rather
  /// than a timer: Firestore's latency compensation puts the local write into
  /// the snapshot immediately with metadata.hasPendingWrites == true, then
  /// re-emits it as false once the server has the message.
  Stream<QuerySnapshot> getMessage(String userID, String otherUserID) {
    return _firestore
        .collection('chat_rooms')
        .doc(_chatRoomId(userID, otherUserID))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  /// Flag every message [currentUserId] has received in [docs] as seen.
  ///
  /// The docs come from the stream the detail screen is already listening to,
  /// so this costs no extra reads and needs no composite index — a second
  /// query filtering on receiverId and seen together would require one.
  Future<void> markMessagesAsSeen(
    List<QueryDocumentSnapshot> docs,
    String currentUserId,
  ) async {
    final batch = _firestore.batch();
    var pending = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if ((data['receiverId'] ?? '').toString() != currentUserId) continue;
      if (data['seen'] == true) continue;

      batch.update(doc.reference, {'seen': true});
      pending++;
    }

    if (pending == 0) return;
    await batch.commit();
  }

  /// Look up a uid from an email address, for cases where only the email is
  /// known (the Users doc stores the Firebase Auth uid in a `uid` field).
  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;
    return (q.docs.first.data()['uid'] ?? q.docs.first.id).toString();
  }
}
