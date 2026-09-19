import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    _idNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }

    if (!_isLogin) {
      final fullName = _fullNameCtrl.text.trim();
      final idNumber = _idNumberCtrl.text.trim();
      if (fullName.isEmpty || idNumber.isEmpty) {
        setState(() => _error = 'Full name and ID number are required.');
        return;
      }
      if (idNumber.length != 13 || int.tryParse(idNumber) == null) {
        setState(() => _error = 'Enter a valid 13-digit SA ID number.');
        return;
      }
      if (password.length < 6) {
        setState(() => _error = 'Password must be at least 6 characters.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await SupabaseService.signIn(email: email, password: password);
      } else {
        await SupabaseService.signUp(
          email: email,
          password: password,
          fullName: _fullNameCtrl.text.trim(),
          idNumber: _idNumberCtrl.text.trim(),
        );
      }

      if (!mounted) return;

      final app = AppScope.read(context);
      final user = SupabaseService.currentUser;
      if (user != null) {
        final profile = await SupabaseService.fetchProfile(user.id);
        if (profile != null) {
          app.profile.displayName = profile['full_name'] as String?;
          app.idNumber = profile['id_number'] as String?;
        } else {
          final meta = user.userMetadata;
          app.profile.displayName = meta?['full_name'] as String?;
        }
        app.setSupabaseAuthenticated(true);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first, then tap Forgot password.');
      return;
    }
    try {
      await SupabaseService.resetPassword(email);
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Check your email'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('We sent a password reset link to your email.'),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not send reset email. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildCard(),
                const SizedBox(height: 20),
                Text(
                  'HIGHER EDUCATION. BRIGHTER FUTURES.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: Palette.govGreen.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/dhet_header.png',
          width: 300,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        Image.asset(
          'assets/images/khetha_brand.png',
          width: 220,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isLogin ? 'Welcome Back' : 'Create Account',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isLogin
                ? 'Sign in to your account to continue'
                : 'Register to get started with Khetha',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF1A1A1A).withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 24),

          if (!_isLogin) ...[
            _InputField(
              controller: _fullNameCtrl,
              placeholder: 'Full Government Name',
              icon: CupertinoIcons.person,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            _InputField(
              controller: _idNumberCtrl,
              placeholder: 'SA ID Number (13 digits)',
              icon: CupertinoIcons.creditcard,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
            ),
            const SizedBox(height: 14),
          ],

          _InputField(
            controller: _emailCtrl,
            placeholder: 'Email or ID Number',
            icon: CupertinoIcons.person_circle,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          _InputField(
            controller: _passwordCtrl,
            placeholder: 'Password',
            icon: CupertinoIcons.lock,
            obscure: _obscurePassword,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword
                    ? CupertinoIcons.eye
                    : CupertinoIcons.eye_slash,
                size: 20,
                color: Palette.govGreen,
              ),
            ),
          ),

          if (_isLogin) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: _forgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B4332),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ],

          const SizedBox(height: 22),

          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 16),
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF1B4332),
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? 'Sign On' : 'Register',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.arrow_right,
                          size: 18, color: CupertinoColors.white),
                    ],
                  ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: const Color(0xFFE0E0E0), height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.4),
                  ),
                ),
              ),
              Expanded(child: Divider(color: const Color(0xFFE0E0E0), height: 1)),
            ],
          ),
          const SizedBox(height: 14),

          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              _isLogin = !_isLogin;
              _error = null;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text.rich(
                TextSpan(
                  text: _isLogin
                      ? "Don't have an account? "
                      : 'Already have an account? ',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.55),
                  ),
                  children: [
                    TextSpan(
                      text: _isLogin ? 'Register' : 'Sign In',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? trailing;

  const _InputField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD0D0D0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(icon, size: 20, color: Palette.govGreen),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              obscureText: obscure,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              inputFormatters: inputFormatters,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: const BoxDecoration(),
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
              placeholderStyle: TextStyle(
                fontSize: 15,
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.35),
              ),
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

class Divider extends StatelessWidget {
  final Color? color;
  final double? height;
  const Divider({super.key, this.color, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 1,
      color: color ?? const Color(0xFFE0E0E0),
    );
  }
}
