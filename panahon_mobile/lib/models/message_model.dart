import 'package:cloud_firestore/cloud_firestore.dart';

/// One chat message, stored at
/// chat_rooms/{chatRoomId}/messages/{autoId}.
///
/// The sender's email is denormalised onto every message so the UI never has
/// to read back the Users collection just to label a bubble.
class MessageModel {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;

  /// True once the receiver has opened the conversation. Drives the blue
  /// double check in the detail screen.
  final bool seen;

  MessageModel({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.seen = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: (map['senderId'] ?? '').toString(),
      senderEmail: (map['senderEmail'] ?? '').toString(),
      receiverId: (map['receiverId'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      // Messages written before 'seen' existed have no such key, and a message
      // still in flight has no server timestamp yet: both fall back rather
      // than throwing mid-build.
      timestamp: map['timestamp'] is Timestamp
          ? map['timestamp'] as Timestamp
          : Timestamp.now(),
      seen: map['seen'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'seen': seen,
    };
  }
}
