import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../data/intelligence.dart';
import '../data/ncap_repository.dart';
import '../data/remote_images.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'career_choice_screen.dart';
import 'job_fit_quiz_screen.dart';
import 'nsfas_screen.dart';
import 'profile_dashboard_screen.dart';
import 'root_tabs.dart';
import 'subject_chooser_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final s = S.of(context);
    final app = AppScope.of(context);
    final name = app.profile.displayName;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? s.greetingMorning
        : hour < 17
            ? s.greetingAfternoon
            : s.greetingEvening;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _GovHeader(p: p),
            ),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              CupertinoPageRoute<void>(
                                  builder: (_) => const ProfileDashboardScreen()),
                            ),
                            child: Text(
                              '$greeting${name != null ? ', $name' : ''} \u{1F44B}',
                              style: KhethaText.title(p),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'What would you like to do today?',
                            style: KhethaText.secondary(p),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            label: 'Search careers and universities',
                            textField: true,
                            child: CupertinoSearchTextField(
                              placeholder: 'Search careers, universities...',
                              backgroundColor: p.cardSurface,
                              style: KhethaText.body(p),
                              itemColor: p.textTertiary,
                              onSubmitted: (query) {
                                RootTabs.of(context)?.goToTab(1);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          _HeroBanner(p: p),
                          const SizedBox(height: 24),
                          _BuildYourFutureCard(app: app, p: p),
                          const SizedBox(height: 24),
                          Text('Quick Links',
                              style: KhethaText.sectionLabel(p).copyWith(
                                fontSize: 14,
                                letterSpacing: 0.6,
                              )),
                          const SizedBox(height: 12),
                          _QuickLinks(p: p),
                          const SizedBox(height: tabBarInset),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GovHeader extends StatelessWidget {
  final Palette p;
  const _GovHeader({required this.p});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final imgPath = app.profile.profileImagePath;

    return Row(
      children: [
        Image.asset('assets/images/coat_of_arms.png', width: 36, height: 36),
        const SizedBox(width: 8),
        Image.asset('assets/images/khetha_brand.png', width: 36, height: 36, fit: BoxFit.contain),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Open profile',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                  builder: (_) => const ProfileDashboardScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.accent.withValues(alpha: 0.12),
                ),
                child: imgPath != null && File(imgPath).existsSync()
                    ? ClipOval(
                        child: Image.file(File(imgPath),
                            width: 36, height: 36, fit: BoxFit.cover),
                      )
                    : Icon(CupertinoIcons.person_fill,
                        size: 18, color: p.accent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final Palette p;
  const _HeroBanner({required this.p});

  static const _fallbackGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
  );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final heroUrl = app.heroBannerUrl ?? RemoteImages.heroBanner;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(heroUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(gradient: _fallbackGradient),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF1B4332).withValues(alpha: 0.85),
                    const Color(0xFF1B4332).withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore Your Future',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Discover study options, apply to universities, and plan your career path.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: CupertinoColors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  button: true,
                  label: 'Get started exploring careers',
                  child: GestureDetector(
                    onTap: () => RootTabs.of(context)?.goToTab(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Palette.govGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildYourFutureCard extends StatelessWidget {
  final AppState app;
  final Palette p;
  const _BuildYourFutureCard({required this.app, required this.p});

  void _navigateNext(BuildContext context) {
    final steps = CareerIntelligence.nextSteps(app.profile);
    if (steps.isEmpty) {
      RootTabs.of(context)?.goToTab(1);
      return;
    }
    final route = steps.first.route;
    Widget? screen;
    if (route == 'job_fit') {
      screen = const JobFitQuizScreen();
    } else if (route == 'career_choice') {
      screen = const CareerChoiceScreen();
    } else if (route == 'subjects') {
      screen = const SubjectChooserScreen();
    } else if (route == 'explore') {
      RootTabs.of(context)?.goToTab(1);
      return;
    }
    if (screen != null) {
      Navigator.of(context)
          .push(CupertinoPageRoute<void>(builder: (_) => screen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = app.profile;
    final progress = profile.journeyProgress;
    final results = app.results;
    final aps = results?.aps ?? profile.onboardingAps ?? 0;
    final coursesOpen = Ncap.qualifications.length;
    final sent = app.applications.length;

    final steps = CareerIntelligence.nextSteps(profile);
    final nextTitle = steps.isNotEmpty ? steps.first.title : 'Explore careers';
    final nextDetail =
        steps.isNotEmpty ? steps.first.detail : 'Browse and save careers you like.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Top stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _FutureStat(
                icon: CupertinoIcons.arrow_up_right_square,
                value: aps > 0 ? '$aps' : '--',
                label: 'Your APS',
              ),
              _FutureStat(
                icon: CupertinoIcons.checkmark_seal,
                value: '$coursesOpen',
                label: 'Courses open',
              ),
              _FutureStat(
                icon: CupertinoIcons.paperplane,
                value: '$sent',
                label: 'Sent',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress ring
          Semantics(
            label: 'Journey progress ${(progress * 100).round()} percent',
            child: SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _FutureRingPainter(
                progress: progress,
                trackColor: CupertinoColors.white.withValues(alpha: 0.15),
                fillColor: Palette.govGold,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: CupertinoColors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'Do this next',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
          const SizedBox(height: 20),

          // Next step title
          Text(
            nextTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nextDetail,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),

          // Continue button
          Semantics(
            button: true,
            label: 'Continue to next step',
            child: GestureDetector(
              onTap: () => _navigateNext(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B4332),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FutureStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _FutureStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        children: [
          Icon(icon, size: 18, color: CupertinoColors.white.withValues(alpha: 0.6)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: CupertinoColors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _FutureRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;

  _FutureRingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_FutureRingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor;
}

class _QuickLinks extends StatelessWidget {
  final Palette p;
  const _QuickLinks({required this.p});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LinkRow(
          icon: CupertinoIcons.doc_text_fill,
          label: 'NSFAS Application',
          subtitle: 'Apply for financial aid',
          p: p,
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute(builder: (_) => const NsfasScreen()),
          ),
        ),
        const SizedBox(height: 8),
        _LinkRow(
          icon: CupertinoIcons.building_2_fill,
          label: 'Find Universities',
          subtitle: 'Browse all 26 public universities',
          p: p,
          onTap: () => RootTabs.of(context)?.goToTab(1),
        ),
        const SizedBox(height: 8),
        _LinkRow(
          icon: CupertinoIcons.briefcase_fill,
          label: 'Career Explorer',
          subtitle: 'Discover career paths and requirements',
          p: p,
          onTap: () => RootTabs.of(context)?.goToTab(1),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Palette p;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.p,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label. $subtitle',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.separator, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Palette.govGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: p.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: KhethaText.headline(p).copyWith(fontSize: 15)),
                    Text(subtitle, style: KhethaText.caption(p)),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, size: 14, color: p.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
