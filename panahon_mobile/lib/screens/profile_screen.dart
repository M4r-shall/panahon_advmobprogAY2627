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
          color: const Color(0xFF1E202C),
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
                    color: const Color(0xFF31323E),
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
                        backgroundColor: const Color(0xFF1E202C),
                        backgroundImage: user.image.isNotEmpty
                            ? NetworkImage(user.image)
                            : null,
                        child: user.image.isEmpty
                            ? Icon(Icons.person, size: 40.sp, color: const Color(0xFFBFC0D1))
                            : null,
                      ),
                      SizedBox(height: 16.h),
                      CustomText(
                        text: '${user.firstName} ${user.lastName}',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        text: '@${user.username}',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF60519B),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Info Card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF31323E),
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
                      _buildInfoTile(Icons.email_outlined, 'Email', user.email),
                      const Divider(height: 1, color: Color(0xFF1E202C)),
                      _buildInfoTile(Icons.people_alt_outlined, 'Gender', user.gender.toLowerCase()),
                      const Divider(height: 1, color: Color(0xFF1E202C)),
                      _buildInfoTile(Icons.badge_outlined, 'User ID', '#${user.id}'),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                // Log Out Button
                SizedBox(
                  height: 50.h,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E202C),
                      side: const BorderSide(color: Color(0xFF60519B), width: 1.5),
                      foregroundColor: const Color(0xFFBFC0D1),
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
                      color: const Color(0xFFBFC0D1),
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

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF60519B), size: 20.sp),
          SizedBox(width: 12.w),
          CustomText(
            text: title,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFBFC0D1),
          ),
          const Spacer(),
          CustomText(
            text: subtitle,
            fontSize: 14.sp,
            color: const Color(0xFFBFC0D1),
          ),
        ],
      ),
    );
  }
}
