import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/login_type.dart';
import '../models/signup_request.dart';
import '../providers/user_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/custom_text_field.dart';
import 'signin_screen.dart';

// Registration screen for both backends.
//
// Firebase creates a real account that can be signed in with afterwards.
// DummyJSON only *simulates* creation, so that path shows the server response
// together with a note explaining the account was never stored.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  LoginType _loginType = LoginType.dummyJson;

  static final _namePattern = RegExp(r"^[A-Za-z][A-Za-z '\-]+$");
  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9._]+$');
  // Permissive on purpose so international numbers pass. For a PH-only form
  // this would be RegExp(r'^(09\d{9}|\+639\d{9})$').
  static final _phonePattern = RegExp(r'^[0-9+\- ]{7,15}$');

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

  bool get _firebaseBlocked => _isFirebase && !firebaseReady;

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Validation -----------------------------------------------------------

  String? _validateName(String? value, String field) {
    if (value == null || value.trim().isEmpty) return 'Please enter your $field';
    if (!_namePattern.hasMatch(value.trim())) {
      return '${field[0].toUpperCase()}${field.substring(1)} must be at least 2 letters';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your age';
    final age = int.tryParse(value.trim());
    if (age == null) return 'Age must be a number';
    if (age < 13) return 'You must be at least 13 years old';
    if (age > 120) return 'Please enter a valid age';
    return null;
  }

  String? _validateContactNo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your contact number';
    }
    if (!_phonePattern.hasMatch(value.trim())) {
      return 'Enter a valid contact number (7-15 digits)';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username';
    }
    final username = value.trim();
    if (username.length < 3 || username.length > 20) {
      return 'Username must be 3-20 characters';
    }
    if (!_usernamePattern.hasMatch(username)) {
      return 'Only letters, numbers, dot and underscore allowed';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    if (!emailPattern.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Returns the first unmet rule so the user is told exactly what to fix.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password needs at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password needs at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password needs at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // --- Submit ---------------------------------------------------------------

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final service = userService.value;
    final request = SignupRequest(
      fName: _fNameController.text.trim(),
      lName: _lNameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      contactNo: _contactNoController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = true);

    try {
      if (_isFirebase) {
        await service.createAccount(
          email: request.email,
          password: request.password,
        );
        await service.updateUsername(username: request.username);
        // Save the profile fields first: saveFirebaseUserData only derives
        // first/last name from displayName when they are not already set.
        await service.saveSignupProfile(request);
        await service.saveFirebaseUserData(service.currentUser!);

        // createUserWithEmailAndPassword signs the user in automatically.
        if (!mounted) return;
        await context.read<UserProvider>().load();
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final created = await service.createAccountDummyJson(request);
        if (!mounted) return;
        setState(() => _isLoading = false);
        // Deliberately not saved to SharedPreferences and no navigation to
        // /home: the account does not really exist.
        await _showSimulatedResultDialog(created);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(_firebaseErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Sign up failed: ${e.toString()}');
    }
  }

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'That email address is already registered.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'That password is too weak.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'operation-not-allowed':
        return 'Email/Password sign-up is not enabled in the Firebase console.';
      case 'configuration-not-found':
        return 'Firebase project is not wired up yet.';
      default:
        return e.message ?? 'Sign up failed (${e.code}).';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showSimulatedResultDialog(Map<String, dynamic> created) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: CustomText(
          text: 'Account Created (Simulated)',
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(dialogContext).textTheme.bodyMedium?.color,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _resultRow(dialogContext, 'ID', '${created['id'] ?? '-'}'),
              _resultRow(
                dialogContext,
                'Name',
                '${created['firstName'] ?? ''} ${created['lastName'] ?? ''}'
                    .trim(),
              ),
              _resultRow(
                dialogContext,
                'Username',
                '${created['username'] ?? '-'}',
              ),
              _resultRow(dialogContext, 'Email', '${created['email'] ?? '-'}'),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.amber),
                ),
                child: CustomText(
                  text:
                      'DummyJSON simulates account creation. This user is not '
                      'persisted on the server and cannot be used to sign in. '
                      'Use the demo account, or switch to Firebase for a real '
                      'registration.',
                  fontSize: 12.sp,
                  maxLines: 6,
                  color: Theme.of(dialogContext).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: CustomText(
              text: 'Back to Sign In',
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(dialogContext).colorScheme.primary,
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _resultRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: '$label: ',
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).hintColor,
          ),
          Expanded(
            child: CustomText(
              text: value.isEmpty ? '-' : value,
              fontSize: 13.sp,
              maxLines: 2,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  // --- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).hintColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/nubdexchange_logo.png',
                      height: 40.h,
                    ),
                    SizedBox(width: 8.w),
                    CustomText(
                      text: 'Create your account',
                      fontSize: 14.sp,
                      color: Theme.of(context).hintColor,
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                LoginTypeSelector(
                  value: _loginType,
                  onChanged: (type) {
                    setState(() => _loginType = type);
                    userService.value.saveLoginType(type);
                  },
                ),
                SizedBox(height: 12.h),
                if (_firebaseBlocked) ...[
                  const FirebaseUnavailableBanner(),
                  SizedBox(height: 12.h),
                ] else
                  _backendNote(context),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _fNameController,
                  label: 'First Name',
                  hint: 'Juan',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => _validateName(v, 'first name'),
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _lNameController,
                  label: 'Last Name',
                  hint: 'Dela Cruz',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => _validateName(v, 'last name'),
                ),
                SizedBox(height: 16.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _ageController,
                        label: 'Age',
                        hint: '18',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 3,
                        textInputAction: TextInputAction.next,
                        validator: _validateAge,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _contactNoController,
                        label: 'Contact No.',
                        hint: '09171234567',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\- ]'),
                          ),
                        ],
                        maxLength: 15,
                        textInputAction: TextInputAction.next,
                        validator: _validateContactNo,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'juandc',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Theme.of(context).hintColor,
                    size: 20.sp,
                  ),
                  validator: _validateUsername,
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'juan@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icon(
                    Icons.mail_outline,
                    color: Theme.of(context).hintColor,
                    size: 20.sp,
                  ),
                  validator: _validateEmail,
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'At least 8 characters',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
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
                  validator: _validatePassword,
                ),
                SizedBox(height: 8.h),
                CustomText(
                  text:
                      'Must be 8+ characters with an uppercase letter, a '
                      'lowercase letter and a number.',
                  fontSize: 11.sp,
                  maxLines: 2,
                  color: Theme.of(context).hintColor,
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Theme.of(context).hintColor,
                    size: 20.sp,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Theme.of(context).hintColor,
                      size: 20.sp,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  validator: _validateConfirmPassword,
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
                    onPressed: (_isLoading || _firebaseBlocked)
                        ? null
                        : _signUp,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : CustomText(
                            text: 'Sign Up',
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
                      text: 'Already have an account?',
                      fontSize: 14.sp,
                      color: Theme.of(context).hintColor,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: CustomText(
                        text: 'Sign In',
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

  /// Sets expectations before the user fills in eight fields.
  Widget _backendNote(BuildContext context) {
    return CustomText(
      text: _isFirebase
          ? 'Firebase creates a real account you can sign in with.'
          : 'DummyJSON only simulates registration: the account is not saved '
                'and cannot be used to sign in.',
      fontSize: 12.sp,
      maxLines: 3,
      textAlign: TextAlign.center,
      color: Theme.of(context).hintColor,
    );
  }
}
