import 'package:flutter/material.dart';

import '../models/login_type.dart';
import '../services/user_service.dart';

/// The app's single source of truth for the signed-in user.
///
/// Before this existed, HomeScreen read the user from a route-arguments map
/// frozen at login time while ProfileScreen kept its own one-shot Future, so an
/// account change (updating a username, for example) only reached the rest of
/// the UI after signing out and back in.
///
/// This is a thin reactive wrapper over UserService.getUserData(): the
/// normalisation of the two backends into one shape stays in the service, and
/// this class only decides *when* to re-read it and tell the widget tree.
class UserProvider with ChangeNotifier {
  UserService get _service => userService.value;

  Map<String, dynamic> _data = const {};
  bool _isLoading = true;

  /// The normalised map from UserService.getUserData(): id, uid, username,
  /// email, firstName, lastName, gender, image, age, contactNo, emailVerified,
  /// accessToken, refreshToken, token, loginType.
  Map<String, dynamic> get data => _data;

  /// True until the first load() completes, so screens can show a spinner
  /// instead of rendering an empty profile for a frame.
  bool get isLoading => _isLoading;

  // --- Convenience accessors, so screens stop hand-casting the map ----------

  String get username => _data['username'] as String? ?? '';
  String get firstName => _data['firstName'] as String? ?? '';
  String get lastName => _data['lastName'] as String? ?? '';
  String get email => _data['email'] as String? ?? '';
  int get id => _data['id'] as int? ?? 0;

  LoginType get loginType => LoginType.fromKey(_data['loginType'] as String?);
  bool get isFirebase => loginType == LoginType.firebase;

  /// Full name, falling back to the username. A Firebase account may have no
  /// stored first name, and showing an empty title reads as a bug.
  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? username : full;
  }

  /// Re-read the session from storage and rebuild every listening screen.
  /// Call after signing in and after any action that mutates the account.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _data = await _service.getUserData();
    } catch (e) {
      debugPrint('UserProvider.load failed: $e');
      _data = const {};
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Drop the cached session on logout, so the next sign-in cannot render the
  /// previous user for a frame.
  void clear() {
    _data = const {};
    _isLoading = false;
    notifyListeners();
  }
}
