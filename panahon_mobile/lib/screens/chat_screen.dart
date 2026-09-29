import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

/// Chat list: every registered user except the logged-in one, filterable by
/// name or email.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  /// Lazy on purpose: ChatService touches FirebaseFirestore.instance, which
  /// throws when Firebase never initialised. Only the guarded path below
  /// reaches it, so a DummyJSON session sees the notice instead of a crash.
  late final ChatService _chatService = ChatService();

  /// The Firebase uid. Empty for a DummyJSON session, which has no Firebase
  /// identity and therefore cannot chat.
  String? _currentUserId;
  bool _loadingUser = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userData = await userService.value.getUserData();
    if (!mounted) return;
    setState(() {
      _currentUserId = (userData['uid'] ?? '').toString();
      _loadingUser = false;
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  /// Match the term against every name-ish field, so "pan", "marius" and
  /// "@gmail" all find the same person.
  bool _matchesSearch(Map<String, dynamic> user) {
    if (_searchText.trim().isEmpty) return true;
    final term = _searchText.trim().toLowerCase();

    return [
      user['firstName'],
      user['lastName'],
      user['username'],
      user['email'],
    ].any((value) => (value ?? '').toString().toLowerCase().contains(term));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: CustomText(
          text: 'Chat',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).appBarTheme.foregroundColor,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingUser) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    // A DummyJSON login carries no uid, so there is no identity to send
    // messages as. Say so instead of streaming a list that could never work.
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return _placeholder(
        icon: Icons.lock_outline,
        title: 'Chat needs a Firebase account',
        subtitle: 'Sign in with a Firebase account to message other users.',
      );
    }

    return Column(
      children: [
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 23.w),
          child: TextField(
            controller: _searchChatController,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _searchText = value),
            decoration: InputDecoration(
              hintText: 'Search chat...',
              hintStyle: const TextStyle(fontFamily: 'Poppins'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchChatController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.cancel),
                      onPressed: () {
                        setState(() {
                          _searchChatController.clear();
                          _searchText = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
          ),
        ),
        SizedBox(height: 10.h),

        // Users Stream
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }

              if (snapshot.hasError) {
                return _placeholder(
                  icon: Icons.error_outline,
                  title: 'Error loading users',
                  subtitle: '${snapshot.error}',
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _placeholder(
                  icon: Icons.person_off_outlined,
                  title: 'No users found',
                  subtitle: 'Other accounts appear here once they sign in.',
                );
              }

              // Enhancement 1: never list the logged-in user, so the
              // self-chat room is unreachable from the UI.
              final others = snapshot.data!
                  .where((user) => user['uid'] != _currentUserId)
                  .toList();

              if (others.isEmpty) {
                return _placeholder(
                  icon: Icons.person_off_outlined,
                  title: 'No one else yet',
                  subtitle: 'You are the only registered user so far.',
                );
              }

              // Enhancement 2: filter by name or email.
              final users = others.where(_matchesSearch).toList();

              if (users.isEmpty) {
                return _placeholder(
                  icon: Icons.search_off,
                  title: 'No users match "${_searchText.trim()}"',
                  subtitle: 'Try a different name or email.',
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserTile(
                    key: ValueKey(user['uid']),
                    user: user,
                    index: index,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          currentUserId: _currentUserId!,
                          tappedUser: user,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _placeholder({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: 12.h),
            CustomText(
              text: title,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            CustomText(
              text: subtitle,
              fontSize: 12.sp,
              textAlign: TextAlign.center,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in the chat list. Staggered by [index] so the list assembles itself
/// rather than snapping in all at once.
class _UserTile extends StatefulWidget {
  const _UserTile({
    super.key,
    required this.user,
    required this.index,
    required this.onTap,
  });

  final Map<String, dynamic> user;
  final int index;
  final VoidCallback onTap;

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void initState() {
    super.initState();
    // Cap the stagger so a long list does not leave the last rows blank for
    // seconds.
    final delay = Duration(milliseconds: (widget.index * 40).clamp(0, 400));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _displayName {
    final first = (widget.user['firstName'] ?? '').toString().trim();
    final last = (widget.user['lastName'] ?? '').toString().trim();
    final full = [first, last].where((p) => p.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;

    final username = (widget.user['username'] ?? '').toString().trim();
    return username.isNotEmpty ? username : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final name = _displayName;
    final initial = name != 'Unknown' ? name[0].toUpperCase() : '?';

    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 4.h),
          child: ListTile(
            onTap: widget.onTap,
            leading: Hero(
              // Shared with the detail screen's app bar avatar.
              tag: 'chat-avatar-${widget.user['uid']}',
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: CustomText(
                  text: initial,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            title: CustomText(
              text: name,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: CustomText(
              text: (widget.user['email'] ?? 'No email').toString(),
              fontSize: 12.sp,
              fontWeight: FontWeight.w300,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(Icons.chevron_right, size: 20.sp),
          ),
        ),
      ),
    );
  }
}
