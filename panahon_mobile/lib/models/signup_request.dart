// Payload collected by signup_screen. Kept separate from the User model on
// purpose: User is the *session* model (it carries accessToken/refreshToken and
// is what gets written to SharedPreferences), so putting a password on it would
// let toJson() leak the password into local storage.
class SignupRequest {
  final String fName;
  final String lName;
  final int age;
  final String contactNo;
  final String username;
  final String email;
  final String password;

  const SignupRequest({
    required this.fName,
    required this.lName,
    required this.age,
    required this.contactNo,
    required this.username,
    required this.email,
    required this.password,
  });

  /// Matches the body shape documented at https://dummyjson.com/docs/users
  /// (POST /users/add). 'phone' is DummyJSON's name for our contactNo field.
  Map<String, dynamic> toJson() {
    return {
      'firstName': fName,
      'lastName': lName,
      'age': age,
      'phone': contactNo,
      'username': username,
      'email': email,
      'password': password,
    };
  }
}
