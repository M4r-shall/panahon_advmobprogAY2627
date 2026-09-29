import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/custom_text.dart';

/// The conversation between the logged-in user and one other user.
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.currentUserId,
    required this.tappedUser,
  });

  final String currentUserId;
  final Map<String, dynamic> tappedUser;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  bool _isSending = false;

  String get _tappedUserId => (widget.tappedUser['uid'] ?? '').toString();

  String get _tappedUserName {
    final first = (widget.tappedUser['firstName'] ?? '').toString().trim();
    final last = (widget.tappedUser['lastName'] ?? '').toString().trim();
    final full = [first, last].where((p) => p.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;

    final username = (widget.tappedUser['username'] ?? '').toString().trim();
    return username.isNotEmpty ? username : 'Unknown';
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      // Clear straight away: latency compensation puts the message in the
      // stream immediately, so the composer emptying and the bubble appearing
      // happen in the same frame.
      _msgCtrl.clear();
      await _chatService.sendMessage(_tappedUserId, text);
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0, // reverse: true, so offset 0 is the newest message
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Put the text back so a failed send does not lose what was typed.
      _msgCtrl.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Mark everything the peer has sent as read, once this frame is done —
  /// a write during build would throw.
  void _scheduleSeenUpdate(List<QueryDocumentSnapshot> docs) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await _chatService.markMessagesAsSeen(docs, widget.currentUserId);
      } catch (e) {
        debugPrint('Could not mark messages as seen: $e');
      }
    });
  }

  String _timeLabel(Timestamp timestamp) {
    final dt = timestamp.toDate();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = _tappedUserName != 'Unknown'
        ? _tappedUserName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        titleSpacing: 0,
        title: Row(
          children: [
            Hero(
              tag: 'chat-avatar-$_tappedUserId',
              child: CircleAvatar(
                radius: 18.sp,
                backgroundColor: scheme.primaryContainer,
                child: CustomText(
                  text: initial,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: _tappedUserName,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  CustomText(
                    text: (widget.tappedUser['email'] ?? '').toString(),
                    fontSize: 11.sp,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    color: Theme.of(
                      context,
                    ).appBarTheme.foregroundColor?.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(child: _buildMessageList()),

          // Composer
          SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 8.h),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant, width: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      focusNode: _msgFocus,
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(fontFamily: 'Poppins'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isSending
                        ? SizedBox(
                            key: const ValueKey('sending'),
                            height: 24.sp,
                            width: 24.sp,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            key: const ValueKey('send'),
                            style: IconButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                            ),
                            icon: const Icon(Icons.send),
                            onPressed: _send,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessage(widget.currentUserId, _tappedUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (snapshot.hasError) {
          return Center(
            child: CustomText(
              text: 'Error loading messages: ${snapshot.error}',
              fontSize: 14.sp,
              textAlign: TextAlign.center,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: CustomText(
              text: 'No messages yet.\nSay hello 👋',
              fontSize: 14.sp,
              textAlign: TextAlign.center,
              color: Theme.of(context).colorScheme.outline,
            ),
          );
        }

        _scheduleSeenUpdate(docs);

        return ListView.builder(
          controller: _scrollCtrl,
          reverse: true,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final senderId = (data['senderId'] ?? '').toString();
            final isMe = senderId == widget.currentUserId;

            return ChatBubble(
              // Keyed by document id so recycling a row does not replay its
              // entry animation.
              key: ValueKey(doc.id),
              message: (data['message'] ?? '').toString(),
              isMe: isMe,
              timeLabel: data['timestamp'] is Timestamp
                  ? _timeLabel(data['timestamp'] as Timestamp)
                  : '',
              status: _statusFor(doc, data),
            );
          },
        );
      },
    );
  }

  /// hasPendingWrites is true while the local write is still unacknowledged,
  /// which is a real "sending…" signal rather than a timer.
  MessageStatus _statusFor(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    if (doc.metadata.hasPendingWrites) return MessageStatus.sending;
    if (data['seen'] == true) return MessageStatus.seen;
    return MessageStatus.delivered;
  }
}
