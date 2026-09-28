import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/login_type.dart';
import '../providers/user_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/custom_text_field.dart';

// Created own UI for signin screen implementing user service and authentication logic.
// Now supports two backends: DummyJSON (REST) and Firebase Authentication.
class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  // One controller for both modes; only the label and validator change.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  LoginType _loginType = LoginType.dummyJson;

  @override
  void initState() {
    super.initState();
    _loadLoginType();
  }

  Future<void> _loadLoginType() async {
    final type = await userService.value.getLoginType();
    if (!mounted) return;
    setState(() => _loginType = type);
  }

  bool get _isFirebase => _loginType == LoginType.firebase;

  /// Firebase is implemented but not provisioned in this build.
  bool get _firebaseBlocked => _isFirebase && !firebaseReady;

  void _login() async {
    // Validate first: flipping the spinner on before validating just makes it
    // flash for a frame when the form is invalid.
    if (!_formKey.currentState!.validate()) return;

    final service = userService.value;
    setState(() => _isLoading = true);

    try {
      if (_isFirebase) {
        await service.signIn(
          email: _usernameController.text.trim(),
          password: _passwordController.text,
        );
        await service.saveFirebaseUserData(service.currentUser!);
      } else {
        await service.loginUser(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      }

      if (!mounted) return;
      // Publish the new session before navigating. /home and the profile tab
      // both read the user from this provider, so it has to be populated
      // first, and it stays live for the rest of the session.
      await context.read<UserProvider>().load();

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(_firebaseErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Login failed: ${e.toString()}');
    }
  }

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in the Firebase console.';
      case 'configuration-not-found':
        return 'Firebase project is not wired up yet.';
      default:
        return e.message ?? 'Sign in failed (${e.code}).';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/nubdexchange_logo.png',
                      height: 40.h,
                    ),
                    SizedBox(width: 8.w),
                    CustomText(
                      text: 'Please sign in to your account',
                      fontSize: 14.sp,
                      color: Theme.of(context).hintColor,
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
                LoginTypeSelector(
                  value: _loginType,
                  onChanged: (type) {
                    setState(() => _loginType = type);
                    userService.value.saveLoginType(type);
                  },
                ),
                if (_firebaseBlocked) ...[
                  SizedBox(height: 16.h),
                  const FirebaseUnavailableBanner(),
                ],
                SizedBox(height: 24.h),
                CustomTextField(
                  controller: _usernameController,
                  label: _isFirebase ? 'Email Address' : 'Username',
                  keyboardType: _isFirebase
                      ? TextInputType.emailAddress
                      : TextInputType.text,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icon(
                    _isFirebase ? Icons.mail_outline : Icons.person_outline,
                    color: Theme.of(context).hintColor,
                    size: 20.sp,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return _isFirebase
                          ? 'Please enter your email address'
                          : 'Please enter your username';
                    }
                    if (_isFirebase && !emailPattern.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Theme.of(context).hintColor,
                    size: 20.sp,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Theme.of(context).hintColor,
                      size: 20.sp,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  height: 50.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: (_isLoading || _firebaseBlocked) ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : CustomText(
                            text: 'Sign In',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFBFC0D1),
                          ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      text: "Don't have an account?",
                      fontSize: 14.sp,
                      color: Theme.of(context).hintColor,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: CustomText(
                        text: 'Sign Up',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
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

/// Shared email validation, used by both the sign in and sign up screens.
final RegExp emailPattern = RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w.\-]+$');

/// DummyJSON / Firebase switch, shared by the sign in and sign up screens.
class LoginTypeSelector extends StatelessWidget {
  const LoginTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final LoginType value;
  final ValueChanged<LoginType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<LoginType>(
      segments: const [
        ButtonSegment(
          value: LoginType.dummyJson,
          label: Text('DummyJSON'),
          icon: Icon(Icons.cloud_outlined),
        ),
        ButtonSegment(
          value: LoginType.firebase,
          label: Text('Firebase'),
          icon: Icon(Icons.local_fire_department_outlined),
        ),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

/// Explains why the Firebase option cannot be used in this build.
class FirebaseUnavailableBanner extends StatelessWidget {
  const FirebaseUnavailableBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: CustomText(
              text:
                  'Firebase is not available on this platform or build. It is '
                  'configured for Android and web; run the app there, or run '
                  '`flutterfire configure` to add this platform.',
              fontSize: 12.sp,
              maxLines: 4,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
