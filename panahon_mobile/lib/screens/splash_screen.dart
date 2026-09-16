import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../models/login_type.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

//Created own UI for splash_screen implementing persistent authentication.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Shared instance rather than a private one, so every screen sees the same
  // session state.
  final UserService _userService = userService.value;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    bool loggedIn = false;

    try {
      final loginType = await _userService.getLoginType();

      if (loginType == LoginType.firebase && firebaseReady) {
        // Firebase restores the session from disk asynchronously, so reading
        // currentUser straight away races that restore. Wait for the first
        // auth event instead, with a timeout so a stalled SDK cannot wedge
        // the splash screen.
        final firebaseUser = await _userService.authStateChanges.first.timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
        if (firebaseUser != null) {
          // Re-saving refreshes the stored ID token, which Firebase rotates.
          await _userService.saveFirebaseUserData(firebaseUser);
          // Then force a brand-new token so the session starts with a full
          // hour. Best effort: offline, the token saved above is still fine.
          try {
            await _userService.refreshFirebaseToken(force: true);
          } catch (e) {
            debugPrint('Forced token refresh skipped: $e');
          }
          loggedIn = true;
        }
      } else {
        // Covers DummyJSON, and Firebase in a build where it is not configured.
        // For DummyJSON this checks the token against /auth/me and refreshes
        // it via /auth/refresh if it has expired.
        loggedIn = await _userService.isAuthenticated();
      }
    } catch (e) {
      debugPrint('Splash auth check failed, sending user to sign in: $e');
      loggedIn = false;
    }

    if (!mounted) return;

    if (loggedIn) {
      final userData = await _userService.getUserData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home', arguments: userData);
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
            Image.asset('assets/images/nubdexchange_logo.png', width: 120.w),
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
