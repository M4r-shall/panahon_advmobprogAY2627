import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 3: Created own UI for profile_screen to render user data.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUser();
  }

  void _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No user data found.'));
        }

        final user = snapshot.data!;

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
                  decoration: BoxDecoration(
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
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40.r,
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        backgroundImage: user.image.isNotEmpty
                            ? NetworkImage(user.image)
                            : null,
                        child: user.image.isEmpty
                            ? Icon(Icons.person, size: 40.sp, color: Theme.of(context).hintColor)
                            : null,
                      ),
                      SizedBox(height: 16.h),
                      CustomText(
                        text: '${user.firstName} ${user.lastName}',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        text: '@${user.username}',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Info Card
                Container(
                  decoration: BoxDecoration(
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
                  ),
                  child: Column(
                    children: [
                      _buildInfoTile(context, Icons.email_outlined, 'Email', user.email),
                      Divider(height: 1, color: Theme.of(context).scaffoldBackgroundColor),
                      _buildInfoTile(context, Icons.people_alt_outlined, 'Gender', user.gender.toLowerCase()),
                      Divider(height: 1, color: Theme.of(context).scaffoldBackgroundColor),
                      _buildInfoTile(context, Icons.badge_outlined, 'User ID', '#${user.id}'),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                // Log Out Button
                SizedBox(
                  height: 50.h,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String subtitle) {
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
          CustomText(
            text: subtitle,
            fontSize: 14.sp,
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
    );
  }
}
