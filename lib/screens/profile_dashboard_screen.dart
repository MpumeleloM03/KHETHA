import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../data/intelligence.dart';
import '../data/ncap_repository.dart';
import '../models/application_models.dart';
import '../models/career_models.dart';
import '../models/funding_models.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';
import '../widgets/viz.dart';
import 'career_detail_screen.dart';
import 'documents_screen.dart';
import 'eligibility_screen.dart';
import 'job_fit_quiz_screen.dart';
import 'nsfas_screen.dart';
import 'root_tabs.dart';
import 'scan_results_screen.dart';
import 'faq_screen.dart';
import 'settings_screen.dart';

class ProfileDashboardScreen extends StatelessWidget {
  const ProfileDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final profile = app.profile;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      child: KhethaGlassLayer(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    children: [
                      // Top bar
                      Row(
                        children: [
                          const Spacer(),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(36, 36),
                            onPressed: () => Navigator.of(context).push(
                              CupertinoPageRoute<void>(
                                  builder: (_) => const SettingsScreen()),
                            ),
                            child: Icon(CupertinoIcons.gear_solid,
                                size: 22, color: p.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Hero profile card
                      _HeroCard(app: app, profile: profile),
                    ],
                  ),
                ),
              ),
            ),

            // Grid section
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Row 1: Next Step + Help & FAQ
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _NextStepCard(app: app)),
                        const SizedBox(width: 10),
                        Expanded(child: const _HelpCard()),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 2: Interests + Qualifications
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _InterestsCard(app: app, profile: profile)),
                        const SizedBox(width: 10),
                        Expanded(child: _QualificationsCard(profile: profile)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 3: Recommended + Target Careers
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _RecommendedCard(app: app)),
                        const SizedBox(width: 10),
                        Expanded(child: _TargetCareersCard(profile: profile)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 4: Docs & Apps + Funding
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _DocsAppsCard(app: app)),
                        const SizedBox(width: 10),
                        Expanded(child: _FundingCard(app: app)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: tabBarInset)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero card
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  final AppState app;
  final UserProfile profile;
  const _HeroCard({required this.app, required this.profile});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final progress = profile.journeyProgress;
    final results = app.results;
    final aps = results?.aps ?? profile.onboardingAps ?? 0;

    return GlassCard(
      useGlass: true,
      tint: p.accent,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          // Tappable avatar
          GestureDetector(
            onTap: () => _pickProfileImage(context, app),
            child: Stack(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: p.accent.withValues(alpha: 0.5),
                      width: 2.5,
                    ),
                    color: p.cardSurface,
                    image: profile.profileImagePath != null
                        ? DecorationImage(
                            image: FileImage(File(profile.profileImagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profile.profileImagePath == null
                      ? Icon(CupertinoIcons.person_fill,
                          size: 32, color: p.textTertiary)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.accent,
                      border: Border.all(color: p.cardSurface, width: 2),
                    ),
                    child: const Icon(CupertinoIcons.camera_fill,
                        size: 12, color: CupertinoColors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tappable name
          GestureDetector(
            onTap: () => _editName(context, app, profile),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.displayName ?? 'Your Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(CupertinoIcons.pencil, size: 16, color: p.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle: interests or grade
          Text(
            profile.favouriteSubjectType ?? profile.grade ?? 'Set up your profile',
            style: TextStyle(fontSize: 14, color: p.textSecondary),
          ),
          const SizedBox(height: 20),

          // Three stat rings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatRing(
                value: '$aps',
                label: 'APS Score',
                progress: aps > 0 ? (aps / 42).clamp(0.0, 1.0) : 0,
                color: p.accent,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                      builder: (_) => const ScanResultsScreen()),
                ),
              ),
              _StatRing(
                value: '${(progress * 100).round()}%',
                label: 'Progress',
                progress: progress,
                color: p.accent,
                large: true,
              ),
              _StatRing(
                value: profile.riasecScores.isNotEmpty
                    ? profile.hollandCode
                    : '-',
                label: 'Holland',
                progress: profile.riasecScores.isNotEmpty ? 1.0 : 0,
                color: p.accent,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Continue button
          _ContinueButton(app: app),
        ],
      ),
    );
  }
}

Future<void> _pickProfileImage(BuildContext context, AppState app) async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
  if (image == null) return;
  await app.setProfileImage(image.path);
}

void _editName(BuildContext context, AppState app, UserProfile profile) {
  final controller = TextEditingController(text: profile.displayName ?? '');
  showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('Edit Name'),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: controller,
          placeholder: 'Your name',
          autofocus: true,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: () {
            app.setIdentity(name: controller.text);
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class _StatRing extends StatelessWidget {
  final String value;
  final String label;
  final double progress;
  final Color color;
  final bool large;
  final VoidCallback? onTap;

  const _StatRing({
    required this.value,
    required this.label,
    required this.progress,
    required this.color,
    this.large = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final size = large ? 80.0 : 64.0;
    final stroke = large ? 5.0 : 4.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                color: color,
                trackColor: p.separator,
                strokeWidth: stroke,
              ),
              child: Center(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: large ? 18 : 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: p.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: p.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _ContinueButton extends StatelessWidget {
  final AppState app;
  const _ContinueButton({required this.app});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final (label, action) = _decide(context);

    return GestureDetector(
      onTap: action,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: p.onAccent,
          ),
        ),
      ),
    );
  }

  (String, VoidCallback) _decide(BuildContext context) {
    if (app.results == null) {
      return ('Add Your Results', () => Navigator.of(context).push(
            CupertinoPageRoute<void>(
                builder: (_) => const ScanResultsScreen()),
          ));
    }
    if (!app.profile.hasJobFit) {
      return ('Take Job Fit Quiz', () => pushTool(context, const JobFitQuizScreen()));
    }
    if (app.applications.isEmpty) {
      return ('Explore Programmes', () => Navigator.of(context).push(
            CupertinoPageRoute<void>(
                builder: (_) => const EligibilityScreen()),
          ));
    }
    return ('View Applications', () => RootTabs.of(context)?.goToTab(2));
  }
}

// ---------------------------------------------------------------------------
// Grid cards (compact, for two-column layout)
// ---------------------------------------------------------------------------

class _GridCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  const _GridCardHeader({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: p.accent),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.accent,
            ),
          ),
      ],
    );
  }
}

class _NextStepCard extends StatelessWidget {
  final AppState app;
  const _NextStepCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final progress = app.profile.journeyProgress;
    final (title, body) = _nextStep();

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GridCardHeader(
            icon: CupertinoIcons.checkmark_circle_fill,
            title: 'Next Step',
            trailing: '${(progress * 100).round()}%',
          ),
          const SizedBox(height: 10),
          ProgressTrack(value: progress),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              )),
          const SizedBox(height: 4),
          Text(body,
              style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.3)),
        ],
      ),
    );
  }

  (String, String) _nextStep() {
    if (app.results == null) {
      return ('Add your results', 'Scan or enter your marks to calculate your APS and see what you qualify for.');
    }
    if (!app.profile.hasJobFit) {
      return ('Take the Job Fit Quiz', 'Five quick questions to find careers that match your personality.');
    }
    if (!app.profile.hasCareerChoice) {
      return ('Complete Career Choice', 'Build your Holland interest code.');
    }
    if (!app.profile.hasSubjects) {
      return ('Choose your subjects', 'Check which subjects keep your matched careers open.');
    }
    if (app.missingRequiredDocuments.isNotEmpty) {
      return ('Prepare your documents', 'Collect your ID, results and proof of residence.');
    }
    if (app.applications.isEmpty) {
      return ('Apply to a programme', 'Your profile is ready. Find programmes and start applying.');
    }
    return ('You\'re on track', 'Keep checking for updates on your applications.');
  }
}

class _TargetCareersCard extends StatelessWidget {
  final UserProfile profile;
  const _TargetCareersCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final matches = CareerIntelligence.rank(profile, limit: 3);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GridCardHeader(
            icon: CupertinoIcons.briefcase_fill,
            title: 'Target Careers',
          ),
          const SizedBox(height: 10),
          if (matches.isEmpty)
            Text('Take the Job Fit Quiz to match careers.',
                style: TextStyle(fontSize: 12, color: p.textSecondary))
          else
            for (final m in matches)
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => CareerDetailScreen(careerId: m.career.id),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ScoreRing(
                          percent: m.percent,
                          label: m.career.title,
                          size: 34),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.career.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p.textPrimary,
                                )),
                            Text('${m.percent}% match',
                                style: TextStyle(
                                    fontSize: 11, color: p.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_right,
                          size: 11, color: p.textTertiary),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

const _availableInterests = [
  'Science & Technology', 'Arts & Design', 'Business & Finance',
  'Health & Medicine', 'Law & Justice', 'Education & Teaching',
  'Engineering', 'Media & Communication', 'Agriculture & Environment',
  'Sports & Recreation', 'Social Work', 'Tourism & Hospitality',
];

class _InterestsCard extends StatelessWidget {
  final AppState app;
  final UserProfile profile;
  const _InterestsCard({required this.app, required this.profile});

  void _showInterestsPicker(BuildContext context) {
    final selected = List<String>.from(profile.interests);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final p = Palette.of(ctx);
          return Container(
            height: 420,
            decoration: BoxDecoration(
              color: p.cardSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Choose your interests',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary)),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text('Done',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: p.accent)),
                        onPressed: () {
                          app.setInterests(selected);
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _availableInterests.map((interest) {
                      final isSelected = selected.contains(interest);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              selected.remove(interest);
                            } else {
                              selected.add(interest);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? p.accent.withValues(alpha: 0.12)
                                : p.canvas,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? p.accent
                                  : p.separator,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(interest,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: p.textPrimary)),
                              ),
                              if (isSelected)
                                Icon(CupertinoIcons.checkmark_circle_fill,
                                    size: 20, color: p.accent),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final has = profile.favouriteSubjectType != null ||
        profile.careerGoals.isNotEmpty ||
        profile.riasecScores.isNotEmpty ||
        profile.interests.isNotEmpty;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _GridCardHeader(
                  icon: CupertinoIcons.sparkles,
                  title: 'Interests',
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
                onPressed: () => _showInterestsPicker(context),
                child: Icon(CupertinoIcons.add_circled,
                    size: 20, color: p.accent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (profile.interests.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.interests
                  .map((i) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(i,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: p.accent)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (!has)
            Text('Complete a quiz or add interests.',
                style: TextStyle(fontSize: 12, color: p.textSecondary))
          else ...[
            if (profile.favouriteSubjectType != null) ...[
              _MiniLabel(label: 'Favourite area'),
              Text(profile.favouriteSubjectType!,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
              const SizedBox(height: 6),
            ],
            if (profile.careerGoals.isNotEmpty) ...[
              _MiniLabel(label: 'Career goals'),
              Text(profile.careerGoals.join(', '),
                  style: TextStyle(fontSize: 13, color: p.textPrimary)),
              const SizedBox(height: 6),
            ],
            if (profile.riasecScores.isNotEmpty) ...[
              _MiniLabel(label: 'Holland code'),
              Row(
                children: [
                  Expanded(
                    child: Text(profile.hollandCode,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary)),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: RiasecChart(scores: profile.riasecScores, size: 48),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _QualificationsCard extends StatelessWidget {
  final UserProfile profile;
  const _QualificationsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final matches = CareerIntelligence.rank(profile, limit: 1);
    final qualifications = <Qualification>[];
    if (matches.isNotEmpty) {
      final career = matches.first.career;
      for (final q in Ncap.qualifications) {
        if (q.leadsToCareerIds.contains(career.id)) {
          qualifications.add(q);
          if (qualifications.length >= 2) break;
        }
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(builder: (_) => const EligibilityScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GridCardHeader(
            icon: CupertinoIcons.book_fill,
            title: 'Qualifications',
          ),
          const SizedBox(height: 10),
          if (qualifications.isEmpty)
            Text('Match careers to see qualifications.',
                style: TextStyle(fontSize: 12, color: p.textSecondary))
          else
            for (final q in qualifications)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(CupertinoIcons.checkmark_circle_fill,
                        size: 14, color: p.accent),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: p.textPrimary)),
                          Text('${q.nqfLevel} • ${q.duration}',
                              style: TextStyle(
                                  fontSize: 11, color: p.textSecondary)),
                        ],
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

class _RecommendedCard extends StatelessWidget {
  final AppState app;
  const _RecommendedCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final steps = <(String, IconData, VoidCallback)>[];

    if (app.results == null) {
      steps.add(('Scan results', CupertinoIcons.doc_text_viewfinder, () {
        Navigator.of(context).push(
          CupertinoPageRoute<void>(builder: (_) => const ScanResultsScreen()),
        );
      }));
    }
    if (!app.profile.hasJobFit) {
      steps.add(('Job Fit Quiz', CupertinoIcons.sparkles, () {
        pushTool(context, const JobFitQuizScreen());
      }));
    }
    if (app.missingRequiredDocuments.isNotEmpty) {
      steps.add(('Upload documents', CupertinoIcons.doc_fill, () {
        Navigator.of(context).push(
          CupertinoPageRoute<void>(builder: (_) => const DocumentsScreen()),
        );
      }));
    }
    if (app.nsfasApplication == null) {
      steps.add(('Apply to NSFAS', CupertinoIcons.creditcard_fill, () {
        Navigator.of(context).push(
          CupertinoPageRoute<void>(builder: (_) => const NsfasScreen()),
        );
      }));
    }
    if (app.applications.isEmpty) {
      steps.add(('Explore programmes', CupertinoIcons.search, () {
        Navigator.of(context).push(
          CupertinoPageRoute<void>(builder: (_) => const EligibilityScreen()),
        );
      }));
    }
    if (steps.isEmpty) {
      steps.add(('Check updates', CupertinoIcons.bell_fill, () {
        RootTabs.of(context)?.goToTab(2);
      }));
    }

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GridCardHeader(
            icon: CupertinoIcons.lightbulb_fill,
            title: 'Recommended',
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: steps[i].$3,
              child: Padding(
                padding: EdgeInsets.only(bottom: i < steps.length - 1 ? 8 : 0),
                child: Row(
                  children: [
                    Icon(steps[i].$2, size: 13, color: p.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(steps[i].$1,
                          style: TextStyle(
                              fontSize: 13, color: p.textPrimary)),
                    ),
                    Icon(CupertinoIcons.chevron_right,
                        size: 11, color: p.textTertiary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocsAppsCard extends StatelessWidget {
  final AppState app;
  const _DocsAppsCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final docs = app.documents;
    final missing = app.missingRequiredDocuments;
    final apps = app.applications;
    final sent = apps.where((a) => a.state != ApplicationState.draft).length;
    final offers =
        apps.where((a) => a.state == ApplicationState.offered).length;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GridCardHeader(
            icon: CupertinoIcons.folder_fill,
            title: 'Docs & Apps',
          ),
          const SizedBox(height: 10),
          // Documents row
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(builder: (_) => const DocumentsScreen()),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.doc_fill, size: 13, color: p.accent),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    docs.isEmpty
                        ? 'No documents yet.'
                        : '${docs.length} uploaded${missing.isNotEmpty ? ', ${missing.length} needed' : ''}',
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Applications row
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => RootTabs.of(context)?.goToTab(2),
            child: Row(
              children: [
                Icon(CupertinoIcons.paperplane_fill,
                    size: 13, color: p.accent),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    apps.isEmpty
                        ? 'No applications yet.'
                        : '$sent sent${offers > 0 ? ', $offers offer${offers == 1 ? "" : "s"}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: offers > 0 ? p.accent : p.textSecondary,
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

class _FundingCard extends StatelessWidget {
  final AppState app;
  const _FundingCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final nsfas = app.nsfasApplication;
    final bursaries = app.bursaryApplications;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GridCardHeader(
            icon: CupertinoIcons.money_dollar_circle_fill,
            title: 'Funding',
          ),
          const SizedBox(height: 10),
          // NSFAS
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(builder: (_) => const NsfasScreen()),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.creditcard_fill,
                    size: 13, color: p.accent),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'NSFAS: ${nsfas?.status.label ?? 'Not applied'}',
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Bursaries
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => RootTabs.of(context)?.goToTab(2),
            child: Row(
              children: [
                Icon(CupertinoIcons.bookmark_fill,
                    size: 13, color: p.accent),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    bursaries.isEmpty
                        ? 'Bursaries: None yet'
                        : 'Bursaries: ${bursaries.length} applied',
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
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

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(builder: (_) => const FaqScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GridCardHeader(
            icon: CupertinoIcons.chat_bubble_2_fill,
            title: 'Help & FAQ',
          ),
          const SizedBox(height: 10),
          Text('Ask the AI assistant or browse common questions.',
              style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.3)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(CupertinoIcons.arrow_right_circle_fill, size: 14, color: p.accent),
              const SizedBox(width: 6),
              Text('Ask a question',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.accent)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _MiniLabel extends StatelessWidget {
  final String label;
  const _MiniLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: p.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
