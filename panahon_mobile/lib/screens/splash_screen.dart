import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';

// Enhancement 1: Created own UI for splash_screen implementing persistent authentication.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      final userData = await _userService.getUserData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: userData,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset(
              'assets/images/nubdexchange_logo.png',
              width: 120.w,
            ),
            SizedBox(height: 16.h),
            Text(
              'NUBD Exchange',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            CustomText(
              text: 'from',
              fontSize: 12.sp,
              color: Theme.of(context).hintColor,
            ),
            CustomText(
              text: 'E-Commerce App',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 40.h),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
