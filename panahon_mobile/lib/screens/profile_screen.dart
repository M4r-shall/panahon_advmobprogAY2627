import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../models/login_type.dart';
import '../providers/user_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = userService.value;

  Future<void> _refresh() => context.read<UserProvider>().load();

  void _logout() async {
    await _userService.logout();
    if (!mounted) return;
    context.read<UserProvider>().clear();
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Current password is incorrect.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again before doing this.';
      case 'weak-password':
        return 'That new password is too weak.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Something went wrong (${e.code}).';
    }
  }

  // --- Account actions ------------------------------------------------------

  Future<void> _updateUsername(
    Map<String, dynamic> data,
    LoginType type,
  ) async {
    final controller = TextEditingController(
      text: data['username'] as String? ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final newUsername = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('Update Username'),
        content: Form(
          key: formKey,
          child: CustomTextField(
            controller: controller,
            label: 'Username',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a username';
              }
              if (value.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newUsername == null) return;

    try {
      if (type == LoginType.firebase) {
        await _userService.updateUsername(username: newUsername);
        _showMessage('Username updated.');
      } else {
        await _userService.updateUsernameDummyJson(
          id: data['id'] as int,
          username: newUsername,
        );
        _showMessage(
          'Updated locally. DummyJSON simulates the request and does not '
          'persist the change.',
        );
      }
      if (!mounted) return;
      await _refresh();
    } on FirebaseAuthException catch (e) {
      _showMessage(_firebaseErrorMessage(e));
    } catch (e) {
      _showMessage('Update failed: $e');
    }
  }

  Future<void> _changePassword(Map<String, dynamic> data) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: currentController,
                  label: 'Current Password',
                  obscureText: true,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter your current password'
                      : null,
                ),
                SizedBox(height: 12.h),
                CustomTextField(
                  controller: newController,
                  label: 'New Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'Needs at least one uppercase letter';
                    }
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return 'Needs at least one lowercase letter';
                    }
                    if (!RegExp(r'\d').hasMatch(value)) {
                      return 'Needs at least one number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                CustomTextField(
                  controller: confirmController,
                  label: 'Confirm New Password',
                  obscureText: true,
                  validator: (value) => (value != newController.text)
                      ? 'Passwords do not match'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (submitted != true) return;

    try {
      await _userService.resetPasswordFromCurrentPassword(
        email: data['email'] as String? ?? '',
        currentPassword: currentController.text,
        newPassword: newController.text,
      );
      _showMessage('Password updated.');
    } on FirebaseAuthException catch (e) {
      _showMessage(_firebaseErrorMessage(e));
    } catch (e) {
      _showMessage('Password change failed: $e');
    }
  }

  Future<void> _deleteAccount(Map<String, dynamic> data, LoginType type) async {
    if (type == LoginType.firebase) {
      await _deleteFirebaseAccount(data);
    } else {
      await _deleteDummyJsonAccount(data);
    }
  }

  Future<void> _deleteFirebaseAccount(Map<String, dynamic> data) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('Delete Account'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This permanently deletes your account. Enter your password to '
                'confirm.',
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                controller: passwordController,
                label: 'Password',
                obscureText: true,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter your password'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _userService.deleteAccount(
        email: data['email'] as String? ?? '',
        password: passwordController.text,
      );
      // Clear the locally stored session too, then leave for the login screen.
      await _userService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } on FirebaseAuthException catch (e) {
      _showMessage(_firebaseErrorMessage(e));
    } catch (e) {
      _showMessage('Delete failed: $e');
    }
  }

  Future<void> _deleteDummyJsonAccount(Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('Delete Account'),
        content: const Text(
          'DummyJSON simulates deletion: it replies with isDeleted: true but '
          'the user stays on the server. Your local session will be cleared '
          'and you will be returned to the sign in screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _userService.deleteAccountDummyJson(
        id: data['id'] as int,
      );
      _showMessage(
        'Server replied isDeleted: ${result['isDeleted']} (simulated).',
      );
      await _userService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (e) {
      _showMessage('Delete failed: $e');
    }
  }

  void _explainUnavailable(String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('Not Available'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Consumer rather than a one-shot Future: an account action anywhere in
    // the app rebuilds this screen as soon as the provider reloads.
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = userProvider.data;
        if (data.isEmpty) {
          return const Center(child: Text('No user data found.'));
        }

        final loginType = userProvider.loginType;
        final isFirebase = userProvider.isFirebase;

        final image = data['image'] as String? ?? '';
        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';
        final username = data['username'] as String? ?? '';
        final gender = data['gender'] as String? ?? '';
        final age = data['age'] as int? ?? 0;
        final contactNo = data['contactNo'] as String? ?? '';
        final uid = data['uid'] as String? ?? '';
        final emailVerified = data['emailVerified'] as bool? ?? false;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16.h),
                // Main Profile Card
                Container(
                  padding: EdgeInsets.symmetric(vertical: 32.h),
                  decoration: _cardDecoration(context),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40.r,
                        backgroundColor: Theme.of(
                          context,
                        ).scaffoldBackgroundColor,
                        backgroundImage: image.isNotEmpty
                            ? NetworkImage(image)
                            : null,
                        child: image.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 40.sp,
                                color: Theme.of(context).hintColor,
                              )
                            : null,
                      ),
                      SizedBox(height: 16.h),
                      _caption(context, 'Name'),
                      SizedBox(height: 2.h),
                      CustomText(
                        text: '$firstName $lastName'.trim().isEmpty
                            ? username
                            : '$firstName $lastName',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      SizedBox(height: 10.h),
                      _caption(context, 'Username'),
                      SizedBox(height: 2.h),
                      CustomText(
                        text: '@$username',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 12.h),
                      _loginTypeBadge(context, loginType),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Info Card, contents depend on the login type
                Container(
                  decoration: _cardDecoration(context),
                  child: Column(
                    children: [
                      _buildInfoTile(
                        context,
                        Icons.email_outlined,
                        'Email',
                        data['email'] as String? ?? '',
                        trailing: isFirebase
                            ? _verifiedChip(context, emailVerified)
                            : null,
                      ),
                      // Gender and the integer user id only exist on DummyJSON.
                      if (!isFirebase) ...[
                        _divider(context),
                        _buildInfoTile(
                          context,
                          Icons.people_alt_outlined,
                          'Gender',
                          gender.toLowerCase(),
                        ),
                        _divider(context),
                        _buildInfoTile(
                          context,
                          Icons.badge_outlined,
                          'User ID',
                          '#${data['id']}',
                        ),
                      ],
                      // Firebase identifies users by a string uid instead.
                      if (isFirebase) ...[
                        _divider(context),
                        _buildInfoTile(
                          context,
                          Icons.fingerprint,
                          'UID',
                          uid.length > 12 ? '${uid.substring(0, 12)}...' : uid,
                        ),
                        _divider(context),
                        _buildInfoTile(
                          context,
                          Icons.shield_outlined,
                          'Provider',
                          'Email / Password',
                        ),
                      ],
                      // Collected at signup; absent for the seeded demo users.
                      if (age > 0) ...[
                        _divider(context),
                        _buildInfoTile(
                          context,
                          Icons.cake_outlined,
                          'Age',
                          '$age',
                        ),
                      ],
                      if (contactNo.isNotEmpty) ...[
                        _divider(context),
                        _buildInfoTile(
                          context,
                          Icons.phone_outlined,
                          'Contact No.',
                          contactNo,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Account actions
                Container(
                  decoration: _cardDecoration(context),
                  child: Column(
                    children: [
                      _buildActionTile(
                        context,
                        icon: Icons.edit_outlined,
                        title: 'Update Username',
                        // Says which of the two fields on the card it edits:
                        // changing the handle leaving the name alone reads as
                        // a failed update otherwise.
                        subtitle: isFirebase
                            ? 'Changes your username'
                            : 'Changes your username',
                        onTap: () => _updateUsername(data, loginType),
                      ),
                      _divider(context),
                      _buildActionTile(
                        context,
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        // DummyJSON has no password endpoint at all.
                        subtitle: isFirebase
                            ? 'Requires your current password'
                            : 'Not available on DummyJSON',
                        enabled: isFirebase,
                        onTap: isFirebase
                            ? () => _changePassword(data)
                            : () => _explainUnavailable(
                                'DummyJSON has no password change endpoint. '
                                'Passwords are fixed for its demo users. Sign '
                                'in with Firebase to change a real password.',
                              ),
                      ),
                      _divider(context),
                      _buildActionTile(
                        context,
                        icon: Icons.delete_outline,
                        title: 'Delete Account',
                        subtitle: isFirebase
                            ? 'Permanent, requires your password'
                            : 'Simulated on DummyJSON',
                        destructive: true,
                        onTap: () => _deleteAccount(data, loginType),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                // Log Out Button
                SizedBox(
                  height: 50.h,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                      foregroundColor: Theme.of(context).hintColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: CustomText(
                      text: 'Log Out',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          spreadRadius: 1,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(height: 1, color: Theme.of(context).scaffoldBackgroundColor);
  }

  /// Small grey label above a value on the profile card.
  ///
  /// The card shows two different fields — the full name from signup and the
  /// username — and without captions they read as one identity, so editing the
  /// username looked like it had failed to change the name above it.
  /// Deliberately styled like the labels `_buildInfoTile` already uses, so the
  /// profile card and the info card below it read the same way.
  Widget _caption(BuildContext context, String text) {
    return CustomText(
      text: text,
      fontSize: 11.sp,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: Theme.of(context).hintColor,
    );
  }

  Widget _loginTypeBadge(BuildContext context, LoginType type) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: CustomText(
        text: 'Signed in with ${type.label}',
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _verifiedChip(BuildContext context, bool verified) {
    return Icon(
      verified ? Icons.verified : Icons.error_outline,
      size: 16.sp,
      color: verified ? Colors.green : Colors.orangeAccent,
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailing,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20.sp),
          SizedBox(width: 12.w),
          CustomText(
            text: title,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).hintColor,
          ),
          const Spacer(),
          Flexible(
            child: CustomText(
              text: subtitle,
              fontSize: 14.sp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              color: Theme.of(context).hintColor,
            ),
          ),
          if (trailing != null) ...[SizedBox(width: 8.w), trailing],
        ],
      ),
    );
  }

  /// Disabled actions stay visible and explain themselves on tap, rather than
  /// silently doing nothing.
  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
    bool destructive = false,
  }) {
    final color = destructive
        ? Colors.redAccent
        : enabled
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).hintColor;

    return ListTile(
      leading: Icon(icon, color: color, size: 20.sp),
      title: CustomText(
        text: title,
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        color: enabled
            ? Theme.of(context).textTheme.bodyMedium?.color
            : Theme.of(context).hintColor,
      ),
      subtitle: CustomText(
        text: subtitle,
        fontSize: 12.sp,
        // 3, not 2: the Update Username subtitle needs the room to say which
        // field it edits. A cap, so the shorter subtitles are unaffected.
        maxLines: 3,
        color: Theme.of(context).hintColor,
      ),
      trailing: Icon(
        enabled ? Icons.chevron_right : Icons.lock_outline,
        size: 18.sp,
        color: Theme.of(context).hintColor,
      ),
      onTap: onTap,
    );
  }
}
