/// App user with bcrypt-hashed password — mirrors `User` in `src/interfaces/index.ts`.
class User {
  final String username;
  final String hashedPassword;

  const User({required this.username, required this.hashedPassword});

  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json['username'] as String,
    hashedPassword: json['hashedPassword'] as String,
  );

  Map<String, dynamic> toJson() => {
    'username': username,
    'hashedPassword': hashedPassword,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          username == other.username &&
          hashedPassword == other.hashedPassword;

  @override
  int get hashCode => Object.hash(username, hashedPassword);
}
