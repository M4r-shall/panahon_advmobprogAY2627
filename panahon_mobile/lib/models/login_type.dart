// Identifies which authentication backend the current session belongs to.
// Persisted to SharedPreferences under 'loginType' so signin, signup, splash,
// profile and settings all agree on which backend is in play.
enum LoginType {
  dummyJson('dummyjson', 'DummyJSON'),
  firebase('firebase', 'Firebase');

  const LoginType(this.key, this.label);

  /// Value stored in SharedPreferences.
  final String key;

  /// Human readable name shown in the UI.
  final String label;

  /// Falls back to DummyJSON so an existing session (saved before this key
  /// existed) keeps working instead of being bounced back to sign in.
  static LoginType fromKey(String? key) => LoginType.values.firstWhere(
    (type) => type.key == key,
    orElse: () => LoginType.dummyJson,
  );
}
