import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
// import 'package:simple_app/persons_list.dart';
import 'dart:math';
import 'package:simple_app/pages/persons_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();

  // --- Add this static method ---
  static Future<void> logout(BuildContext context) async {
    await ParseUser.currentUser();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }
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
      if (response.success) {
        _showMessage("Login successful!");

        // Navigate to persons page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PersonsPage()),
        );
      } else {
        _showMessage(response.error!.message);
      }
      _showMessage(response.success ? "Login successful!" : response.error!.message);
    }
  }


  Future<void> resetPassword() async {
    final username = usernameController.text.trim();

    if (username.isEmpty) {
      _showMessage("Please enter your username or email.");
      return;
    }

    final user = ParseUser(null, null, username); // username can be email if your Parse server is configured that way
    final response = await user.requestPasswordReset();

    if (response.success) {
      _showMessage("Password reset link sent to your email.");
    } else {
      _showMessage("Failed to send reset email: ${response.error?.message}");
    }
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
            decoration: const InputDecoration(labelText: "Enter your email"),
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