import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/models/user.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:nba_fantasy_stats_react_app/widgets/glass_card.dart';

/// Username + password authentication replicating the React app's
/// `Login.tsx` — register mode hashes with bcrypt, login mode verifies
/// against stored hashes (Step 4 of FLUTTER_PLAN.md).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onAuthenticated});

  /// Called with the username after a successful register+login or login.
  final void Function(String username) onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isRegistering = false;
  bool _isSubmitting = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _clearMessages() {
    _error = null;
    _success = null;
  }

  Future<List<User>> _loadUsers() async {
    final raw = await StorageService.readList(StorageService.usersKey);
    return raw.map((j) => User.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> _persistUsers(List<User> users) => StorageService.writeJson(
    StorageService.usersKey,
    users.map((u) => u.toJson()).toList(),
  );

  // Message strings match Login.tsx exactly for behavior parity.
  static const _emptyFieldsError = 'Username and password cannot be empty.';
  static const _usernameTakenError = 'Username already exists.';
  static const _invalidCredentialsError = 'Invalid username or password.';
  static const _registerSuccess =
      'Registration successful! You can now log in.';
  static const _registerFailureError =
      'An error occurred during registration. Please try again.';
  static const _loginFailureError =
      'An error occurred during login. Please try again.';

  Future<void> _register() async {
    try {
      final users = await _loadUsers();

      if (users.any((u) => u.username == _userCtrl.text)) {
        setState(() {
          _error = _usernameTakenError;
          _success = null;
        });
        return;
      }

      final hashedPassword = BCrypt.hashpw(
        _passCtrl.text,
        BCrypt.gensalt(logRounds: 10),
      );
      final newUsers = [
        ...users,
        User(username: _userCtrl.text, hashedPassword: hashedPassword),
      ];
      await _persistUsers(newUsers);

      if (!mounted) return;
      setState(() {
        _success = _registerSuccess;
        _error = null;
        _isRegistering = false;
      });
      _passCtrl.clear();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _registerFailureError;
        _success = null;
      });
    }
  }

  Future<void> _login() async {
    try {
      final users = await _loadUsers();
      final user = users.where((u) => u.username == _userCtrl.text).firstOrNull;
      final isValid =
          user != null && BCrypt.checkpw(_passCtrl.text, user.hashedPassword);

      if (!isValid) {
        if (!mounted) return;
        setState(() {
          _error = _invalidCredentialsError;
          _success = null;
        });
        return;
      }

      widget.onAuthenticated(user.username);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _loginFailureError;
        _success = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() {
        _error = _emptyFieldsError;
        _success = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _clearMessages();
    });
    await (_isRegistering ? _register() : _login());
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isRegistering ? 'Create Account' : 'Player Login',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('username_field'),
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                    ),
                    onChanged: (_) => setState(_clearMessages),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('password_field'),
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                    ),
                    onChanged: (_) => setState(_clearMessages),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (_success != null)
                    Text(
                      _success!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (_error != null || _success != null)
                    const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('submit_button'),
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(_isRegistering ? 'Register' : 'Login'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                            _isRegistering = !_isRegistering;
                            _clearMessages();
                          }),
                    child: Text(
                      _isRegistering
                          ? 'Already have an account? Login'
                          : "Don't have an account? Register",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
