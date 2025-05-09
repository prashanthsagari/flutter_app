import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:simple_app/pages/persons_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();

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
  bool passwordVisible = false;

  // --- Validation Functions ---
  String? validateUsername(String username) {
    if (username.length < 5 || username.length > 12) {
      return 'Username must be between 5 and 12 characters';
    }
    return null;
  }

  String? validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    final alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphanumeric.hasMatch(password)) {
      return 'Password must be alphanumeric';
    }
    return null;
  }

  String? validateEmail(String email) {
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> handleAuth() async {
    final input = usernameOrEmailController.text.trim();
    final password = passwordController.text.trim();
    final email = emailController.text.trim();

    if (isRegistering) {
      final usernameError = validateUsername(input);
      final passwordError = validatePassword(password);
      final emailError = validateEmail(email);

      if (usernameError != null) {
        _showMessage(usernameError);
        return;
      }
      if (passwordError != null) {
        _showMessage(passwordError);
        return;
      }
      if (emailError != null) {
        _showMessage(emailError);
        return;
      }

      final user = ParseUser(input, password, email);
      final response = await user.signUp();
      _showMessage(response.success ? "Registration successful!" : response.error!.message);
    } else {
      String? usernameToLogin = input;
      final user = ParseUser(usernameToLogin, password, null);
      final response = await user.login();
      if (response.success) {
        _showMessage("Login successful!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PersonsPage()),
        );
      } else {
        _showMessage(response.error!.message);
      }
    }
  }

  Future<void> resetPassword() async {
    final username = usernameController.text.trim();

    if (username.isEmpty) {
      _showMessage("Please enter your username");
      return;
    }

    final user = ParseUser(null, null, username);
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceVariant,
      appBar: AppBar(
        title: Text(isRegistering ? "Register" : "Login"),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    isRegistering ? "Create Account" : "Welcome Back",
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: usernameOrEmailController,
                    decoration: InputDecoration(
                      labelText: isRegistering ? "Username" : "Username",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: !passwordVisible,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => passwordVisible = !passwordVisible),
                      ),
                    ),
                  ),
                  if (isRegistering) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(isRegistering ? Icons.person_add : Icons.login),
                      label: Text(isRegistering ? "Register" : "Login"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: handleAuth,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => isRegistering = !isRegistering),
                    child: Text(isRegistering
                        ? "Already have an account? Login"
                        : "No account? Register"),
                  ),
                  if (!isRegistering)
                    TextButton(
                      onPressed: _showPasswordResetDialog,
                      child: const Text("Forgot Password?"),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
