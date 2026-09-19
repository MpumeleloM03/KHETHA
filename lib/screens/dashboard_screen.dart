import 'package:flutter/cupertino.dart';

import '../data/admissions.dart';
import '../data/intelligence.dart';
import '../data/ncap_repository.dart';
import '../l10n/strings.dart';
import '../models/application_models.dart';
import '../models/results_models.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';
import '../widgets/viz.dart';
import 'career_choice_screen.dart';
import 'career_detail_screen.dart';
import 'eligibility_screen.dart';
import 'grade9_screen.dart';
import 'job_fit_quiz_screen.dart';
import 'root_tabs.dart';
import 'scan_results_screen.dart';
import 'settings_screen.dart';
import 'subject_chooser_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final s = S.of(context);
    final profile = app.profile;
    final results = app.results;

    final admissionReady = results != null && results.kind.countsTowardsAdmission;
    final open = admissionReady ? AdmissionsEngine.openTo(results).length : 0;
    final strongest = results == null || results.subjects.isEmpty
        ? null
        : (results.subjects.where((s) => !s.isLifeOrientation).toList()
              ..sort((a, b) => b.percentage.compareTo(a.percentage)))
            .first;
    final matches = CareerIntelligence.rank(profile, limit: 3);
    final offers = app.applications
        .where((a) => a.state == ApplicationState.offered)
        .length;
    final sent = app.applications
        .where((a) => a.state != ApplicationState.draft)
        .length;

    final isGrade9 = profile.grade == 'Grade 9';

    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      child: KhethaGlassLayer(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Custom header instead of nav bar
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(s, profile.displayName),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: p.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'National Higher Education Portal',
                              style: TextStyle(
                                fontSize: 14,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                        onPressed: () => Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                              builder: (_) => const SettingsScreen()),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: p.cardSurface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(CupertinoIcons.person_fill,
                              size: 20, color: p.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Current Status section
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.accent,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            value: admissionReady
                                ? '${results.aps}'
                                : strongest == null
                                    ? '-'
                                    : '${strongest.percentage}%',
                            label: admissionReady ? 'Your APS' : 'Best subject',
                            detail: admissionReady
                                ? '${results.passType} Pass'
                                : strongest == null
                                    ? 'Not added'
                                    : strongest.subject.split(' ').first,
                            icon: CupertinoIcons.chart_bar_alt_fill,
                            onTap: () => Navigator.of(context).push(
                              CupertinoPageRoute<void>(
                                builder: (_) => isGrade9
                                    ? const Grade9Screen()
                                    : const ScanResultsScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            value: admissionReady ? '$open' : '-',
                            label: 'Qualified Courses',
                            detail: admissionReady
                                ? 'View List'
                                : results == null
                                    ? 'Add results'
                                    : 'After matric',
                            icon: CupertinoIcons.checkmark_seal_fill,
                            onTap: () => Navigator.of(context).push(
                              CupertinoPageRoute<void>(
                                  builder: (_) => const EligibilityScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            value: '$sent',
                            label: 'Applications Sent',
                            detail: offers > 0
                                ? '$offers offer${offers == 1 ? "" : "s"}'
                                : 'No updates',
                            icon: CupertinoIcons.paperplane_fill,
                            highlight: offers > 0,
                            onTap: () => RootTabs.of(context)?.goToTab(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Next Steps
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Steps',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _NextAction(isGrade9: isGrade9),
                  ],
                ),
              ),
            ),

            // Explore Services
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Services',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ServiceTile(
                            icon: CupertinoIcons.doc_text_viewfinder,
                            title: 'Scan Results',
                            onTap: () => Navigator.of(context).push(
                              CupertinoPageRoute<void>(
                                  builder: (_) => const ScanResultsScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ServiceTile(
                            icon: CupertinoIcons.book_fill,
                            title: 'Explore Degrees',
                            onTap: () => Navigator.of(context).push(
                              CupertinoPageRoute<void>(
                                  builder: (_) => const EligibilityScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ServiceTile(
                            icon: CupertinoIcons.search,
                            title: 'Search for Bursaries',
                            onTap: () => RootTabs.of(context)?.goToTab(1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ServiceTile(
                            icon: CupertinoIcons.person_fill,
                            title: 'My Profile',
                            onTap: () => RootTabs.of(context)?.goToTab(3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (isGrade9)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(child: _Grade9Card()),
              ),

            // Profile snapshot
            if (profile.riasecScores.isNotEmpty || matches.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Profile',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ProfileSnapshot(matches: matches),
                    ],
                  ),
                ),
              ),

            if (matches.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                    child: _TopMatch(match: matches.first)),
              ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(child: _DemandCard()),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(child: _FooterNote()),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: tabBarInset)),
          ],
        ),
      ),
    );
  }

  String _greeting(S s, String? name) {
    final hour = DateTime.now().hour;
    final base = hour < 12
        ? s.greetingMorning
        : hour < 18
            ? s.greetingAfternoon
            : s.greetingEvening;
    return name == null ? base : '$base, $name';
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final String detail;
  final IconData icon;
  final bool highlight;
  final VoidCallback onTap;

  const _StatTile({
    required this.value,
    required this.label,
    required this.detail,
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      radius: 14,
      onTap: onTap,
      semanticLabel: '$label: $value, $detail',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: highlight ? p.warm : p.accent),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: p.textSecondary,
              )),
          Text(detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: p.textTertiary,
              )),
        ],
      ),
    );
  }
}

class _NextAction extends StatelessWidget {
  final bool isGrade9;
  const _NextAction({required this.isGrade9});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final profile = app.profile;

    final (title, body, label, action) = _decide(context, app);
    final progress = profile.journeyProgress;

    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.checkmark_alt,
                    size: 16, color: p.accent),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: p.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ProgressTrack(value: progress),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: action,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: p.onAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, String, String, VoidCallback) _decide(
      BuildContext context, AppState app) {
    final profile = app.profile;

    if (isGrade9 && !profile.hasSubjects) {
      final hasMarks =
          app.results != null && app.results!.kind == ResultsKind.grade9;
      return (
        'Choose your subjects properly',
        hasMarks
            ? 'Your marks are in. See which Grade 10 subjects fit them, and which keep the career you want reachable.'
            : 'Put in your Grade 9 Term 4 marks and Khetha Go will tell you which Grade 10 subjects keep the most doors open for you.',
        hasMarks ? 'See my subject advice' : 'Start subject choice',
        () => Navigator.of(context).push(
              CupertinoPageRoute<void>(builder: (_) => const Grade9Screen()),
            ),
      );
    }

    if (app.results == null) {
      return (
        'Add your results',
        'One photo of your results statement and the app can tell you your APS, what you qualify for, and where the gaps are.',
        'Scan my results',
        () => Navigator.of(context).push(
              CupertinoPageRoute<void>(builder: (_) => const ScanResultsScreen()),
            ),
      );
    }

    if (!profile.hasJobFit) {
      return (
        'Find out what suits you',
        'You know what you qualify for. Five questions and the app can tell you which of those you would actually enjoy.',
        'Take the Job Fit Quiz',
        () => pushTool(context, const JobFitQuizScreen()),
      );
    }

    if (!profile.hasCareerChoice) {
      return (
        'Sharpen your matches',
        'Six more questions works out your Holland interest code, which is the measure a career practitioner will ask you for.',
        'Take Career Choice',
        () => pushTool(context, const CareerChoiceScreen()),
      );
    }

    if (!profile.hasSubjects) {
      return (
        'Check your subject choices',
        'See which of your matched careers your subjects keep open, and which they close.',
        'Open Subject Chooser',
        () => pushTool(context, const SubjectChooserScreen()),
      );
    }

    if (app.missingRequiredDocuments.isNotEmpty || app.idNumber == null) {
      return (
        'Get your documents ready',
        'Collect your ID and documents once, and every application you send can use them.',
        'Build My Application Pack',
        () => RootTabs.of(context)?.goToTab(2),
      );
    }

    if (app.applications.isEmpty) {
      return (
        'Apply somewhere',
        'Your pack is ready. Pick a programme you qualify for and send it to every institution that offers it.',
        'Find programmes',
        () => Navigator.of(context).push(
              CupertinoPageRoute<void>(builder: (_) => const EligibilityScreen()),
            ),
      );
    }

    if (app.draftApplications.isNotEmpty) {
      return (
        'Send your applications',
        '${app.draftApplications.length} ${app.draftApplications.length == 1 ? "application is" : "applications are"} waiting to go.',
        'Review and send',
        () => RootTabs.of(context)?.goToTab(2),
      );
    }

    return (
      'Talk it through with someone',
      'You have done the work the app can do. A Khetha practitioner can help with the part it cannot.',
      'Talk to a practitioner',
      () => RootTabs.of(context)?.goToTab(4),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 14,
      onTap: onTap,
      semanticLabel: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.isDark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: p.textPrimary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Grade9Card extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      radius: 14,
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(builder: (_) => const Grade9Screen()),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.warmMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(CupertinoIcons.pencil_outline, size: 19, color: p.warm),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grade 9 subject choice', style: KhethaText.headline(p)),
                const SizedBox(height: 3),
                Text(
                  'The decision that quietly sets up the next ten years.',
                  style: KhethaText.caption(p),
                ),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_right, size: 15, color: p.textTertiary),
        ],
      ),
    );
  }
}

class _ProfileSnapshot extends StatelessWidget {
  final List<MatchResult> matches;
  const _ProfileSnapshot({required this.matches});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final profile = app.profile;

    return GlassCard(
      radius: 14,
      onTap: () => RootTabs.of(context)?.goToTab(3),
      child: Row(
        children: [
          if (profile.riasecScores.isNotEmpty)
            RiasecChart(scores: profile.riasecScores, size: 96)
          else
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              child: Icon(CupertinoIcons.chart_pie,
                  size: 34, color: p.textTertiary),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.riasecScores.isEmpty
                      ? 'No interest profile yet'
                      : 'Interest code ${profile.hollandCode}',
                  style: KhethaText.headline(p),
                ),
                const SizedBox(height: 5),
                Text(
                  profile.riasecScores.isEmpty
                      ? 'Take a questionnaire and this fills in.'
                      : matches.isEmpty
                          ? 'Your strongest interest dimensions.'
                          : '${matches.length} careers matched. Top fit: ${matches.first.percent}%.',
                  style: KhethaText.caption(p),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Text('See my journey',
                        style: KhethaText.caption(p).copyWith(
                            color: p.accent, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Icon(CupertinoIcons.chevron_right,
                        size: 11, color: p.accent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMatch extends StatelessWidget {
  final MatchResult match;
  const _TopMatch({required this.match});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(15),
      radius: 14,
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => CareerDetailScreen(careerId: match.career.id),
        ),
      ),
      child: Row(
        children: [
          ScoreRing(
            percent: match.percent,
            label: match.career.title,
            size: 54,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best match', style: KhethaText.sectionLabel(p)),
                const SizedBox(height: 3),
                Text(match.career.title, style: KhethaText.headline(p)),
                const SizedBox(height: 4),
                Text(match.confidenceLabel,
                    style: KhethaText.caption(p).copyWith(color: p.accent)),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_right, size: 15, color: p.textTertiary),
        ],
      ),
    );
  }
}

class _DemandCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final scarce = Ncap.careers.where((c) => c.scarceSkill).toList();

    return GlassCard(
      radius: 14,
      onTap: () => RootTabs.of(context)?.goToTab(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.flame_fill, size: 17, color: p.warm),
              const SizedBox(width: 9),
              Expanded(
                child: Text('${scarce.length} occupations in high demand',
                    style: KhethaText.headline(p)),
              ),
              Icon(CupertinoIcons.chevron_right, size: 15, color: p.textTertiary),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'From the national list of occupations in high demand.',
            style: KhethaText.caption(p),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in scarce.take(5))
                Chip(c.title, color: p.warm),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final s = S.of(context);
    return GlassCard(
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.checkmark_shield_fill,
                  size: 16, color: p.accent),
              const SizedBox(width: 8),
              Expanded(
                child:
                    Text('Built on NCAP content', style: KhethaText.headline(p)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${Ncap.careers.length} occupations, ${Ncap.qualifications.length} qualifications and ${Ncap.providers.length} institutions across all nine provinces.',
            style: KhethaText.caption(p),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Chip(s.offlineReady,
                  color: p.accent, icon: CupertinoIcons.wifi_slash),
              Chip('Nothing uploaded',
                  color: p.textSecondary, icon: CupertinoIcons.lock_fill),
            ],
          ),
        ],
      ),
    );
  }
}
