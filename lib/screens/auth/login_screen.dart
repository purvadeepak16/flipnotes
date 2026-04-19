import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../theme/app_theme.dart';
import 'sign_up_screen.dart';
import 'forgot_password_screen.dart';
import '../../widgets/app_input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<app_auth.AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );
    if (!success && mounted) {
      _showError(authProvider.errorMessage ?? 'Login failed');
      authProvider.clearError();
    }
  }

  Future<void> _googleSignIn() async {
    final authProvider = context.read<app_auth.AuthProvider>();
    final success = await authProvider.googleSignIn();
    if (!success && mounted && authProvider.errorMessage != null) {
      _showError(authProvider.errorMessage!);
      authProvider.clearError();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.nunito()),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();
    final isLoading = authProvider.status == app_auth.AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 8),
                _buildForgotPassword(),
                const SizedBox(height: 28),
                _buildSignInButton(isLoading),
                const SizedBox(height: 20),
                _buildDivider(),
                const SizedBox(height: 20),
                _buildGoogleButton(isLoading),
                const SizedBox(height: 32),
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flip, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'FlipNotes',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Welcome back! 👋',
          style: GoogleFonts.nunito(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to continue studying',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return AppInputField(
      controller: _emailCtrl,
      label: 'Email',
      hint: 'you@example.com',
      icon: Icons.mail_outline_rounded,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return AppInputField(
      controller: _passwordCtrl,
      label: 'Password',
      hint: '••••••••',
      icon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.mutedText,
          size: 20,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (v.length < 6) return 'At least 6 characters';
        return null;
      },
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
        ),
        child: Text(
          'Forgot Password?',
          style: GoogleFonts.nunito(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                'Sign In',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFD0D8D8))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.mutedText,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD0D8D8))),
      ],
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : _googleSignIn,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFD0D8D8), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.g_mobiledata_rounded,
                  size: 20, color: Color(0xFFEA4335)),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: GoogleFonts.nunito(
                fontSize: 14, color: AppColors.mutedText),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignUpScreen()),
            ),
            child: Text(
              'Sign Up',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── End of LoginScreen ────────────────────────────────────────────────
