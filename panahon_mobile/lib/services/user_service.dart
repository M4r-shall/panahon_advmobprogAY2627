import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/login_type.dart';
import '../models/signup_request.dart';
// firebase_auth also exports a class named User, so our own model is imported
// under a prefix. Rule for this file: a bare `User` is the Firebase one,
// `models.User` is ours.
import '../models/user.dart' as models;
import 'chat_service.dart';

/// Single shared UserService for the whole app. Screens read `userService.value`
/// instead of constructing their own instance, so there is exactly one seam
/// between the UI and the two auth backends.
///
/// This is a ValueNotifier so the instance can be swapped at runtime (for a fake
/// service in tests, for example). Nothing listens to it today: no screen
/// rebuilds when it fires, because the instance is never replaced. The reactive
/// equivalent for auth state is `authStateChanges` below.
ValueNotifier<UserService> userService = ValueNotifier(UserService());

//Created UserService to handle API calls and SharedPreferences.
class UserService {
  Map<String, dynamic> data = {};

  /// Session keys owned by this service. Used by logout() so it can clear the
  /// session without touching unrelated preferences.
  static const List<String> _sessionKeys = [
    'id',
    'uid',
    'username',
    'email',
    'firstName',
    'lastName',
    'gender',
    'image',
    'accessToken',
    'refreshToken',
    'token',
    'age',
    'contactNo',
    'emailVerified',
  ];

  // ---------------------------------------------------------------------------
  // DummyJSON backend (REST over http)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    // A fresh login must not inherit firstName/age/contactNo left behind by a
    // previous session of either backend.
    await _clearSessionKeys();

    final response = await post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      await saveLoginType(LoginType.dummyJson);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  /// Create a user on DummyJSON.
  ///
  /// NOTE: this endpoint is *simulated*. DummyJSON echoes back a user with a
  /// fresh id but never stores it, so the returned account cannot be signed in
  /// with afterwards. The signup screen shows that caveat to the user.
  Future<Map<String, dynamic>> createAccountDummyJson(
    SignupRequest request,
  ) async {
    final response = await post(
      Uri.parse('$host/users/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    // /users/add answers 201, not 200.
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

  /// Simulated on DummyJSON: the response reflects the change, the server does not.
  Future<Map<String, dynamic>> updateUsernameDummyJson({
    required int id,
    required String username,
  }) async {
    final response = await put(
      Uri.parse('$host/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );

    if (response.statusCode == 200) {
      final updated = jsonDecode(response.body) as Map<String, dynamic>;
      // Mirror the change locally so the profile screen reflects it.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      return updated;
    } else {
      throw Exception(response.body);
    }
  }

  /// Simulated on DummyJSON: responds with isDeleted/deletedOn, deletes nothing.
  Future<Map<String, dynamic>> deleteAccountDummyJson({required int id}) async {
    final response = await delete(Uri.parse('$host/users/$id'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

  /// Exchange the stored refresh token for a new access/refresh pair
  /// (POST /auth/refresh). The DummyJSON access token expires after
  /// `expiresInMins`, so a session restored from disk may need this.
  Future<Map<String, dynamic>> refreshSessionDummyJson() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken') ?? '';
    if (refreshToken.isEmpty) {
      throw Exception('No refresh token stored.');
    }

    final response = await post(
      Uri.parse('$host/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken, 'expiresInMins': 60}),
    );

    if (response.statusCode == 200) {
      final tokens = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = tokens['accessToken'] as String? ?? '';
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('token', accessToken);
      await prefs.setString(
        'refreshToken',
        tokens['refreshToken'] as String? ?? refreshToken,
      );
      return tokens;
    } else {
      throw Exception(response.body);
    }
  }

  /// Ask the server whether the stored access token is still good
  /// (GET /auth/me). On 401/403 fall back to a refresh before giving up.
  ///
  /// A network failure is not treated as "logged out": the user keeps the
  /// cached session and the next online check decides.
  Future<bool> validateDummyJsonSession() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';
    if (accessToken.isEmpty) return false;

    try {
      final response = await get(
        Uri.parse('$host/auth/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) return true;

      if (response.statusCode == 401 || response.statusCode == 403) {
        try {
          await refreshSessionDummyJson();
          return true;
        } catch (_) {
          return false;
        }
      }

      // Any other status (5xx and so on) says nothing about the token.
      return isLoggedIn();
    } catch (_) {
      // ClientException on web, SocketException on mobile: offline either way.
      return isLoggedIn();
    }
  }

  // ---------------------------------------------------------------------------
  // Shared session storage (both backends normalise into the same keys)
  // ---------------------------------------------------------------------------

  /// Save User Data to SharedPreferences
  /// Save user data from API response based on User model
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = models.User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    // Fields the User model does not carry but the profile screen shows.
    if (userData['age'] != null) {
      await prefs.setInt('age', userData['age'] as int);
    }
    if (userData['phone'] != null) {
      await prefs.setString('contactNo', userData['phone'].toString());
    }

    // Support generic token key if present in API response
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  /// Key for a profile field kept outside the session keys, scoped to one
  /// Firebase account. These survive _clearSessionKeys() on purpose: see
  /// saveSignupProfile().
  String _profileKey(String uid, String field) => 'profile_${uid}_$field';

  /// The four fields collected at signup that have no Firebase equivalent.
  static const List<String> _profileFields = [
    'firstName',
    'lastName',
    'age',
    'contactNo',
  ];

  /// Persist the extra profile fields collected at signup. Firebase only stores
  /// displayName/email/photoURL, so age, contact number and the real first/last
  /// name have nowhere else to live.
  ///
  /// They are written twice: into the session keys the profile screen reads,
  /// and into uid-scoped keys that survive logout. Without the second copy,
  /// signIn() clears the session keys and the next sign-in has nothing to
  /// restore, so Age and Contact No. disappear and firstName silently becomes
  /// the username (saveFirebaseUserData falls back to splitting displayName).
  Future<void> saveSignupProfile(SignupRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', request.fName);
    await prefs.setString('lastName', request.lName);
    await prefs.setInt('age', request.age);
    await prefs.setString('contactNo', request.contactNo);

    // createAccount() signs the user in, so by the time signup_screen calls
    // this the uid exists. A DummyJSON signup has no uid and needs no copy:
    // that backend re-sends these fields on every login.
    final uid = firebaseReady ? firebaseAuth.currentUser?.uid : null;
    if (uid == null || uid.isEmpty) return;

    await prefs.setString(_profileKey(uid, 'firstName'), request.fName);
    await prefs.setString(_profileKey(uid, 'lastName'), request.lName);
    await prefs.setInt(_profileKey(uid, 'age'), request.age);
    await prefs.setString(_profileKey(uid, 'contactNo'), request.contactNo);
  }

  /// Copy a Firebase account's stored signup profile back into the session
  /// keys. Returns true when a first name was restored, which tells
  /// saveFirebaseUserData it can skip the displayName fallback.
  Future<bool> _restoreProfileForUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final firstName = prefs.getString(_profileKey(uid, 'firstName')) ?? '';
    if (firstName.isEmpty) return false;

    await prefs.setString('firstName', firstName);
    await prefs.setString(
      'lastName',
      prefs.getString(_profileKey(uid, 'lastName')) ?? '',
    );

    final age = prefs.getInt(_profileKey(uid, 'age'));
    if (age != null) await prefs.setInt('age', age);

    final contactNo = prefs.getString(_profileKey(uid, 'contactNo'));
    if (contactNo != null) await prefs.setString('contactNo', contactNo);

    return true;
  }

  /// Copy the live session's profile fields into the uid-scoped keys, but only
  /// when nothing is stored for that account yet. Never overwrites a stored
  /// profile, so it cannot clobber a real first name with one derived from a
  /// display name.
  Future<void> _seedProfileForUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getString(_profileKey(uid, 'firstName')) ?? '').isNotEmpty) {
      return;
    }

    final firstName = prefs.getString('firstName') ?? '';
    if (firstName.isEmpty) return;

    await prefs.setString(_profileKey(uid, 'firstName'), firstName);
    await prefs.setString(
      _profileKey(uid, 'lastName'),
      prefs.getString('lastName') ?? '',
    );

    final age = prefs.getInt('age');
    if (age != null) await prefs.setInt(_profileKey(uid, 'age'), age);

    final contactNo = prefs.getString('contactNo');
    if (contactNo != null) {
      await prefs.setString(_profileKey(uid, 'contactNo'), contactNo);
    }
  }

  /// Drop the stored profile for one account, so a deleted account leaves
  /// nothing behind on the device.
  Future<void> _clearProfileForUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    for (final field in _profileFields) {
      await prefs.remove(_profileKey(uid, field));
    }
  }

  /// Map a Firebase user onto the same SharedPreferences keys the DummyJSON
  /// path writes, so getUserData() returns one shape for both backends.
  ///
  /// Two fields have no Firebase equivalent: 'gender' stays empty and the
  /// integer 'id' stays 0. The real Firebase identity is the String 'uid',
  /// which gets its own key — writing it to 'id' would break both
  /// prefs.setInt and the `int id` field on the User model.
  Future<void> saveFirebaseUserData(User firebaseUser) async {
    final prefs = await SharedPreferences.getInstance();
    final displayName = firebaseUser.displayName ?? '';
    final email = firebaseUser.email ?? '';
    // Re-reading the ID token here is what refreshes it; Firebase rotates it
    // roughly hourly and the stored copy would otherwise go stale. Use
    // refreshFirebaseToken(force: true) when a brand-new token is required.
    final idToken = await firebaseUser.getIdToken() ?? '';

    await prefs.setInt('id', 0);
    await prefs.setString('uid', firebaseUser.uid);
    await prefs.setString(
      'username',
      displayName.isNotEmpty ? displayName : email.split('@').first,
    );
    await prefs.setString('email', email);

    // Keep the names captured at signup. signIn() has just cleared the session
    // keys, so restore this account's stored profile first and only fall back
    // to splitting the display name when there is nothing to restore (an
    // account created outside this app, for example).
    if ((prefs.getString('firstName') ?? '').isEmpty) {
      final restored = await _restoreProfileForUid(firebaseUser.uid);
      if (!restored) {
        final parts = displayName.trim().split(RegExp(r'\s+'));
        await prefs.setString('firstName', parts.isNotEmpty ? parts.first : '');
        await prefs.setString(
          'lastName',
          parts.length > 1 ? parts.sublist(1).join(' ') : '',
        );
      }
    } else {
      // A live session with no stored copy yet: an account that signed up
      // before the uid-scoped keys existed. Seed them now so this account
      // survives its next sign-in too, instead of having to sign up again.
      await _seedProfileForUid(firebaseUser.uid);
    }

    await prefs.setString('gender', '');
    await prefs.setString('image', firebaseUser.photoURL ?? '');
    await prefs.setString('accessToken', idToken);
    await prefs.setString('refreshToken', firebaseUser.refreshToken ?? '');
    await prefs.setString('token', idToken);
    await prefs.setBool('emailVerified', firebaseUser.emailVerified);

    await saveLoginType(LoginType.firebase);

    // Mirror the account into Firestore so it appears in the chat list. This
    // runs on signup and on every sign-in, which is what backfills accounts
    // created before the Users collection existed. A Firestore failure must
    // never block a login that has otherwise succeeded, so it only logs.
    try {
      await ChatService().upsertUser(
        uid: firebaseUser.uid,
        email: email,
        username: prefs.getString('username') ?? '',
        firstName: prefs.getString('firstName') ?? '',
        lastName: prefs.getString('lastName') ?? '',
        image: firebaseUser.photoURL ?? '',
      );
    } catch (e) {
      debugPrint('Could not sync user to Firestore: $e');
    }
  }

  /// Retrieve user data from SharedPreferences
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'uid': prefs.getString('uid') ?? '',
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'age': prefs.getInt('age') ?? 0,
      'contactNo': prefs.getString('contactNo') ?? '',
      'emailVerified': prefs.getBool('emailVerified') ?? false,
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'loginType': prefs.getString('loginType') ?? LoginType.dummyJson.key,
    };
  }

  /// Retrieve User model from SharedPreferences
  Future<models.User> getUser() async {
    final userData = await getUserData();
    return models.User.fromJson(userData);
  }

  /// Remember which backend the user signed in with.
  Future<void> saveLoginType(LoginType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', type.key);
  }

  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return LoginType.fromKey(prefs.getString('loginType'));
  }

  /// Check if User is Logged In
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  /// Backend-aware session check. Firebase owns its own session, so ask the SDK
  /// rather than trusting the token we cached. DummyJSON has no SDK, so the
  /// cached token is checked against the server (and refreshed if expired).
  Future<bool> isAuthenticated() async {
    final type = await getLoginType();
    if (type == LoginType.firebase) {
      // A Firebase session cannot be used in a build where Firebase failed to
      // initialise (e.g. Windows desktop), so send the user back to sign in.
      return firebaseReady && currentUser != null;
    }
    return validateDummyJsonSession();
  }

  /// Removes only the session keys rather than calling prefs.clear(): clearing
  /// everything would also wipe the remembered login type (and any future
  /// preference such as a persisted theme).
  Future<void> _clearSessionKeys() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _sessionKeys) {
      await prefs.remove(key);
    }
    // 'loginType' is kept so the sign-in toggle remembers the last choice.
  }

  /// Logout and Clear User Data
  Future<void> logout() async {
    // Firebase sign-out is best effort. If Firebase is not configured, a
    // DummyJSON user must still be able to log out.
    try {
      if (firebaseReady && firebaseAuth.currentUser != null) {
        await firebaseAuth.signOut();
      }
    } catch (_) {
      // Ignored on purpose, see above.
    }

    // Otherwise the previous user's raw login response lingers in this
    // process-wide singleton for the life of the app.
    data = {};

    try {
      await _clearSessionKeys();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Firebase Authentication backend
  // ---------------------------------------------------------------------------

  /// Deliberately a getter rather than `final firebaseAuth = FirebaseAuth.instance`.
  ///
  /// Dart initialises top-level variables lazily, so the global `userService`
  /// above is constructed by the first screen that reads it. With an eager
  /// field, that construction would touch FirebaseAuth.instance and throw
  /// "No Firebase App '[DEFAULT]' has been created" on the splash screen while
  /// Firebase is unprovisioned. A getter defers the lookup to the moment a
  /// Firebase method is actually called.
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  User? get currentUser => firebaseReady ? firebaseAuth.currentUser : null;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  /// Also fires when the SDK rotates the ID token (roughly hourly), not only
  /// on sign-in/sign-out. Listen to this to keep the cached token current.
  Stream<User?> get idTokenChanges => firebaseAuth.idTokenChanges();

  /// Guard so an unprovisioned build reports a readable message instead of a
  /// platform exception.
  void _requireFirebase() {
    if (!firebaseReady) {
      throw Exception(
        'Firebase is not available on this platform or build. It is '
        'configured for Android and web only.',
      );
    }
  }

  /// Replaces the `currentUser!` force-unwraps so a signed-out state surfaces
  /// as a message rather than a null-check crash.
  User _requireUser() {
    _requireFirebase();
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No signed-in Firebase user.');
    }
    return user;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    _requireFirebase();
    // See loginUser(): never carry another session's profile fields over.
    await _clearSessionKeys();
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Explicit token refresh. `getIdToken()` returns the cached token while it
  /// is valid and fetches a new one when it has expired; `force: true` always
  /// fetches. The result is mirrored into SharedPreferences so
  /// getUserData()['token'] is never stale.
  Future<String> refreshFirebaseToken({bool force = false}) async {
    final user = _requireUser();
    final idToken = await user.getIdToken(force) ?? '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', idToken);
    await prefs.setString('token', idToken);
    await prefs.setString('refreshToken', user.refreshToken ?? '');
    return idToken;
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    _requireFirebase();
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    _requireFirebase();
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    final user = _requireUser();
    await user.updateDisplayName(username);
    // Without reload() the local User object keeps the old displayName, and
    // without persisting it the profile screen keeps showing the old value.
    await user.reload();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final user = _requireUser();
    final uid = user.uid;
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    // Firebase requires a recent login before destructive operations.
    await user.reauthenticateWithCredential(credential);
    await user.delete();
    // The uid-scoped profile outlives the session keys, so deleting the
    // account has to remove it explicitly.
    await _clearProfileForUid(uid);
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final user = _requireUser();
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}
