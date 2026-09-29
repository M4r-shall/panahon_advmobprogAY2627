import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'custom_text.dart';

/// How far a message the receiver has sent is from being read.
enum MessageStatus {
  /// Written locally, not yet acknowledged by the server.
  sending,

  /// Committed to Firestore.
  delivered,

  /// Opened by the receiver.
  seen,
}

/// One message bubble, with a fade + slide entry animation that plays once.
///
/// The animation runs from initState rather than from a builder so a scroll
/// that recycles the widget does not replay it; the detail screen keys each
/// bubble by its document id to keep that pairing stable.
class ChatBubble extends StatefulWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timeLabel,
    required this.status,
  });

  final String message;
  final bool isMe;
  final String timeLabel;
  final MessageStatus status;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    // Each side slides in from its own edge, which reads as the message
    // arriving from that person.
    begin: Offset(widget.isMe ? 0.12 : -0.12, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color background = widget.isMe
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final Color foreground = widget.isMe
        ? scheme.onPrimary
        : scheme.onSurfaceVariant;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: widget.isMe
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 12.w),
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: background,
              // The squared corner points at its author, which is the clearest
              // sender/receiver cue at a glance.
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: widget.isMe ? Radius.zero : const Radius.circular(16),
                bottomLeft: widget.isMe ? const Radius.circular(16) : Radius.zero,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: widget.message.isNotEmpty ? widget.message : '[empty]',
                  fontSize: 15.sp,
                  color: foreground,
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: widget.timeLabel,
                      fontSize: 10.sp,
                      color: foreground.withValues(alpha: 0.7),
                    ),
                    // Receipts only mean something for messages you sent.
                    if (widget.isMe) ...[
                      SizedBox(width: 4.w),
                      _StatusIcon(status: widget.status, fallback: foreground),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.fallback});

  final MessageStatus status;
  final Color fallback;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (status) {
      MessageStatus.sending => (Icons.schedule, fallback.withValues(alpha: 0.7)),
      MessageStatus.delivered => (Icons.done, fallback.withValues(alpha: 0.7)),
      MessageStatus.seen => (Icons.done_all, const Color(0xFF4FC3F7)),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(icon, key: ValueKey(status), size: 13.sp, color: color),
    );
  }
}
