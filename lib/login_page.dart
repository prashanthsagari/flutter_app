import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'dart:math';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameOrEmailController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  bool isRegistering = false;

  Future<void> handleAuth() async {
    final input = usernameOrEmailController.text.trim(); // Can be username or email
    final password = passwordController.text.trim();
    final email = emailController.text.trim();

    if (isRegistering) {
      final user = ParseUser(input, password, email);
      final response = await user.signUp();
      _showMessage(response.success ? "Registration successful!" : response.error!.message);
    } else {
      String? usernameToLogin = input;

      if (input.contains('@')) {
        // Call cloud function to get username from email
        final result = await ParseCloudFunction('getUsernameByEmail')
            .execute(parameters: {'email': input});

        if (result.success && result.result != null) {
          usernameToLogin = result.result;
        } else {
          _showMessage("No user found with this email.");
          return;
        }
      }

      final user = ParseUser(usernameToLogin, password, null);
      final response = await user.login();
      _showMessage(response.success ? "Login successful!" : response.error!.message);
    }
  }


  Future<void> resetPassword() async {
    final username = usernameController.text.trim();

    if (username.isEmpty) {
      _showMessage("Please enter your username.");
      return;
    }

    // Step 1: Query user by username
    final query = QueryBuilder(ParseUser.forQuery())
      ..whereEqualTo('username', username);

    final response = await query.query();

    if (response.success && response.results != null && response.results!.isNotEmpty) {
      final user = response.results!.first as ParseUser;

      // Step 2: Generate new password and update
      final newPassword = _generateRandomPassword();
      user.set('password', newPassword);
      final saveResponse = await user.save();

      if (saveResponse.success) {
        // Step 3: Logout current user to avoid InvalidSessionToken
        final currentUser = await ParseUser.currentUser();
        if (currentUser != null) {
          await currentUser.logout();
        }

        _showMessage("Password reset successful.\nNew Password: $newPassword");
      } else {
        _showMessage("Failed to update password: ${saveResponse.error!.message}");
      }
    } else {
      _showMessage("User not found with that username.");
    }
  }


  String _generateRandomPassword({int length = 8}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }


  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isRegistering ? "Register" : "Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameOrEmailController,
              decoration: InputDecoration(
                labelText: isRegistering ? "Username" : "Username or Email",
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            if (isRegistering)
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleAuth,
              child: Text(isRegistering ? "Register" : "Login"),
            ),
            TextButton(
              onPressed: () => setState(() => isRegistering = !isRegistering),
              child: Text(isRegistering ? "Already have an account? Login" : "No account? Register"),
            ),
            // Forgot password section
            if (!isRegistering)
              TextButton(
                onPressed: () {
                  _showPasswordResetDialog();
                },
                child: const Text("Forgot Password?"),
              ),
          ],
        ),
      ),
    );
  }

  // Dialog for password reset
  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reset Password"),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(labelText: "Enter your username"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                resetPassword();
                Navigator.pop(context);
              },
              child: const Text("Submit"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}