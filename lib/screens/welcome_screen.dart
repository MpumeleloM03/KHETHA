import 'package:flutter/cupertino.dart';

import '../data/remote_images.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import 'legal_screen.dart';
import 'onboarding/academic_profile_screen.dart';
import 'onboarding/discover_path_screen.dart';
import 'root_tabs.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
                          decoration: BoxDecoration(
                            color: i <= _step ? p.accent : p.separator,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 26),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: switch (_step) {
                      0 => const _IntroStep(key: ValueKey(0)),
                      1 => const _LanguageStep(key: ValueKey(1)),
                      2 => const _ConsentStep(key: ValueKey(2)),
                      3 => DiscoverPathScreen(
                          key: const ValueKey(3),
                          onComplete: () => setState(() => _step = 4),
                        ),
                      _ => AcademicProfileScreen(
                          key: const ValueKey(4),
                          onComplete: () {
                            final app = AppScope.read(context);
                            app.completeWelcome();
                            app.completeOnboarding();
                            Navigator.of(context).pushReplacement(
                              CupertinoPageRoute<void>(
                                  builder: (_) => const RootTabs()),
                            );
                          },
                        ),
                    },
                  ),
                ),
                if (_step <= 2) ...[
                  const SizedBox(height: 16),
                  _Actions(
                    step: _step,
                    enabled: _step < 2 || AppScope.of(context).acceptedTerms,
                    onBack: _step == 0 ? null : () => setState(() => _step--),
                    onNext: () {
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        setState(() => _step = 3);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
    );
  }
}


class _Actions extends StatelessWidget {
  final int step;
  final bool enabled;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const _Actions({
    required this.step,
    required this.enabled,
    this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Row(
      children: [
        if (onBack != null) ...[
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            onPressed: onBack,
            child: Text('Back',
                style: KhethaText.body(p).copyWith(color: p.textSecondary)),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: KhethaButton(
            label: step == 2 ? 'Get started' : 'Continue',
            icon: step == 2 ? CupertinoIcons.arrow_right_circle_fill : null,
            onTap: enabled ? onNext : null,
          ),
        ),
      ],
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/coat_of_arms.png',
                  width: 28, height: 28),
              const SizedBox(width: 8),
              Text(
                'Higher Education & Training\nRepublic of South Africa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.brand,
                  letterSpacing: 0.3,
                  height: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Khetha Go', style: KhethaText.largeTitle(p)),
          const SizedBox(height: 6),
          Text(
            'Your career guidance companion, on the go.',
            style: KhethaText.secondary(p).copyWith(fontSize: 17),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Point(
                    icon: CupertinoIcons.building_2_fill,
                    title: 'Official DHET Data',
                    body:
                        'Careers, qualifications and institutions from the National Career Advice Portal.',
                  ),
                  _Point(
                    icon: CupertinoIcons.sparkles,
                    title: 'Smart Matching',
                    body:
                        'Every career suggestion comes with a clear reason, traced to your answers.',
                  ),
                  _Point(
                    icon: CupertinoIcons.wifi_slash,
                    title: 'Works Offline',
                    body:
                        'Everything runs on your phone. No data connection needed.',
                  ),
                  _Point(
                    icon: CupertinoIcons.lock_shield_fill,
                    title: 'Private & Secure',
                    body:
                        'No account, no server. Your information stays on this device.',
                    last: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool last;

  const _Point({
    required this.icon,
    required this.title,
    required this.body,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Palette.govGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: p.brand),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KhethaText.headline(p)),
                const SizedBox(height: 3),
                Text(body, style: KhethaText.caption(p)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose your language', style: KhethaText.largeTitle(p)),
          const SizedBox(height: 6),
          Text(
            'The interface and every instruction are translated. Career and qualification records stay in English for now.',
            style: KhethaText.secondary(p),
          ),
          const SizedBox(height: 22),
          GlassSection(
            children: [
              for (final lang in AppLanguage.values)
                GlassRow(
                  title: lang.nativeName,
                  trailing: app.language == lang
                      ? Icon(CupertinoIcons.checkmark_circle_fill,
                          color: p.accent, size: 22)
                      : Icon(CupertinoIcons.circle,
                          color: p.textTertiary, size: 22),
                  onTap: () => app.setLanguage(lang),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsentStep extends StatelessWidget {
  const _ConsentStep({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your data, your choice', style: KhethaText.largeTitle(p)),
          const SizedBox(height: 6),
          Text(
            'Each of these is separate and off by default. You can change any of them later in Settings.',
            style: KhethaText.secondary(p),
          ),
          const SizedBox(height: 20),
          GlassSection(
            footer:
                'Khetha Go has no account and no backend. Your profile stays on this device and is never transmitted.',
            children: [
              GlassRow(
                icon: CupertinoIcons.floppy_disk,
                title: 'Remember my progress',
                subtitle:
                    'Keeps your answers and saved careers on this phone.',
                trailing: CupertinoSwitch(
                  value: app.consentStoreProfile,
                  activeTrackColor: p.accent,
                  onChanged: app.setConsentStoreProfile,
                ),
              ),
              GlassRow(
                icon: CupertinoIcons.sparkles,
                title: 'Personalise my guidance',
                subtitle:
                    'Ranks careers against your answers instead of a generic list.',
                trailing: CupertinoSwitch(
                  value: app.consentPersonalisation,
                  activeTrackColor: p.accent,
                  onChanged: app.setConsentPersonalisation,
                ),
              ),
              GlassRow(
                icon: CupertinoIcons.bell,
                title: 'Send me reminders',
                subtitle:
                    'Occasional nudges about your next step. Local, not from a server.',
                trailing: CupertinoSwitch(
                  value: app.consentReminders,
                  activeTrackColor: p.accent,
                  onChanged: app.setConsentReminders,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _TermsGate(),
        ],
      ),
    );
  }
}

class _TermsGate extends StatelessWidget {
  const _TermsGate();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);

    return GlassCard(
      tint: app.acceptedTerms ? p.accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: app.acceptedTerms ? null : app.acceptTerms,
            child: Semantics(
              button: true,
              checked: app.acceptedTerms,
              label: 'I agree to the terms of use and the privacy notice',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    app.acceptedTerms
                        ? CupertinoIcons.checkmark_square_fill
                        : CupertinoIcons.square,
                    size: 24,
                    color: app.acceptedTerms ? p.accent : p.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I agree to the terms of use and I have read the privacy notice.',
                      style: KhethaText.body(p),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: KhethaButton(
                  label: 'Privacy',
                  secondary: true,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                        builder: (_) => const LegalScreen(showTerms: false)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: KhethaButton(
                  label: 'Terms',
                  secondary: true,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                        builder: (_) => const LegalScreen(showTerms: true)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
