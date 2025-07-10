import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco, color: theme.primaryColor, size: 64),
                const SizedBox(height: 16),
                Text('İklim Duyarlılığı', style: theme.textTheme.displaySmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Ad'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Şifre'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() { _isLoading = true; });
                        await _authService.signUp(
                          context,
                          name: nameController.text.trim(),
                          mail: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );
                        setState(() { _isLoading = false; });
                      },
                      child: const Text('Kayıt Ol'),
                    ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: const Text('Zaten hesabınız var mı? Giriş yap'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 