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
