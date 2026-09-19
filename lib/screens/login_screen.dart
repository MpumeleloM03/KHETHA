import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/palette.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focuses = List.generate(4, (_) => FocusNode());
  bool _isSetup = false;
  String? _firstPin;
  String? _error;
  bool _loading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    _isSetup = !app.hasPin;
    if (!_isSetup && app.biometricEnabled) {
      _checkBiometrics(app);
    }
  }

  Future<void> _checkBiometrics(AppState app) async {
    final available = await app.canUseBiometrics;
    if (mounted) setState(() => _biometricAvailable = available);
    if (available && app.biometricEnabled) {
      _tryBiometric(app);
    }
  }

  Future<void> _tryBiometric(AppState app) async {
    final success = await app.authenticateWithBiometrics();
    if (!success && mounted) {
      _focuses[0].requestFocus();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focuses) f.dispose();
    super.dispose();
  }

  String get _pin => _controllers.map((c) => c.text).join();

  void _onDigit(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focuses[index + 1].requestFocus();
    }
    if (_pin.length == 4) _submit();
  }

  Future<void> _submit() async {
    final pin = _pin;
    if (pin.length < 4) return;

    final app = AppScope.of(context);

    if (_isSetup) {
      if (_firstPin == null) {
        setState(() {
          _firstPin = pin;
          _error = null;
        });
        _clear();
        return;
      }
      if (_firstPin != pin) {
        setState(() => _error = 'PINs don\'t match. Try again.');
        _clear();
        setState(() => _firstPin = null);
        return;
      }
      setState(() => _loading = true);
      await app.setPin(pin);
      return;
    }

    if (app.verifyPin(pin)) return;

    setState(() => _error = 'Incorrect PIN');
    _clear();
    HapticFeedback.heavyImpact();
  }

  void _clear() {
    for (final c in _controllers) c.clear();
    _focuses[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);

    String title;
    String subtitle;
    if (_isSetup) {
      if (_firstPin == null) {
        title = 'Create your PIN';
        subtitle = 'Set a 4-digit PIN to secure your profile';
      } else {
        title = 'Confirm PIN';
        subtitle = 'Enter the same PIN again';
      }
    } else {
      title = 'Welcome back${app.profile.displayName != null ? ', ${app.profile.displayName}' : ''}';
      subtitle = 'Enter your 4-digit PIN';
    }

    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
            children: [
              Semantics(
                label: 'Security lock',
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.accent.withValues(alpha: 0.12),
                  ),
                  child: Icon(CupertinoIcons.lock_shield_fill,
                      size: 36, color: p.accent),
                ),
              ),
              const SizedBox(height: 28),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: p.textPrimary,
                  )),
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: p.textSecondary)),
              const SizedBox(height: 36),
              Semantics(
                label: 'PIN entry, 4 digits',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    return Padding(
                      padding: EdgeInsets.only(left: i > 0 ? 16 : 0),
                      child: SizedBox(
                        width: 52,
                        height: 60,
                        child: Semantics(
                          label: 'PIN digit ${i + 1}',
                          child: CupertinoTextField(
                            controller: _controllers[i],
                            focusNode: _focuses[i],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            obscureText: true,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                            decoration: BoxDecoration(
                              color: p.cardSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _error != null
                                    ? CupertinoColors.destructiveRed
                                    : p.separator,
                                width: 1.5,
                              ),
                            ),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (v) => _onDigit(i, v),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(_error!,
                      style: const TextStyle(
                          fontSize: 14, color: CupertinoColors.destructiveRed)),
                ),
              ],
              if (_loading) ...[
                const SizedBox(height: 24),
                const CupertinoActivityIndicator(),
              ],
              if (!_isSetup && _biometricAvailable && app.biometricEnabled) ...[
                const SizedBox(height: 28),
                Semantics(
                  button: true,
                  label: 'Unlock with Face ID or Touch ID',
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _tryBiometric(app),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: p.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.person_crop_circle_badge_checkmark,
                              size: 22, color: p.accent),
                          const SizedBox(width: 10),
                          Text('Use Face ID',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: p.accent)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Text(_isSetup ? 'Skip for now' : 'Skip',
                    style: TextStyle(fontSize: 15, color: p.textTertiary)),
                onPressed: () {
                  app.isAuthenticated = true;
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
