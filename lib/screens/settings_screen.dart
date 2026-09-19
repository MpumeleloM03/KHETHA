import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'legal_screen.dart';
import 'login_screen.dart';

import '../data/intelligence.dart';
import '../data/ncap_repository.dart';
import '../l10n/strings.dart';
import '../services/notification_service.dart';
import '../services/speech_service.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = Palette.of(context);
    final s = S.of(context);

    return KhethaDetailPage(
      title: s.tabSettings,
      slivers: [
        SliverSection(children: [
          GlassSection(
            header: 'Appearance',
            footer:
                'Following the system setting means Khetha Go switches to dark automatically when your phone does.',
            children: [
              for (final mode in AppearanceMode.values)
                GlassRow(
                  icon: switch (mode) {
                    AppearanceMode.system => CupertinoIcons.circle_lefthalf_fill,
                    AppearanceMode.light => CupertinoIcons.sun_max_fill,
                    AppearanceMode.dark => CupertinoIcons.moon_fill,
                  },
                  title: switch (mode) {
                    AppearanceMode.system => 'Match my phone',
                    AppearanceMode.light => 'Always light',
                    AppearanceMode.dark => 'Always dark',
                  },
                  trailing: app.appearance == mode
                      ? Icon(CupertinoIcons.checkmark_circle_fill,
                          color: p.accent, size: 21)
                      : null,
                  onTap: () => app.setAppearance(mode),
                ),
            ],
          ),
          const SizedBox(height: 24),

          GlassSection(
            header: 'Language',
            footer:
                'The interface and all instructions are translated. Career and qualification records stay in English - they come from NCAP and are translated at source rather than guessed at here.',
            children: [
              for (final lang in AppLanguage.values)
                GlassRow(
                  title: lang.nativeName,
                  trailing: app.language == lang
                      ? Icon(CupertinoIcons.checkmark_circle_fill,
                          color: p.accent, size: 21)
                      : null,
                  onTap: () => app.setLanguage(lang),
                ),
            ],
          ),
          const SizedBox(height: 24),

          GlassSection(
            header: 'Accessibility',
            footer:
                'Khetha Go also follows your phone’s Dynamic Type, Reduce Motion, Increase Contrast and VoiceOver settings. This slider adds to them.',
            children: [
              GlassRow(
                icon: CupertinoIcons.textformat_size,
                title: 'Text size',
                subtitle: 'Currently ${(app.textScale * 100).round()}% of normal',
                onTap: () => _textSizeSheet(context),
                showChevron: true,
              ),
              GlassRow(
                icon: CupertinoIcons.speedometer,
                title: 'Low-bandwidth mode',
                subtitle:
                    'Turns off blur and gradients. Lighter on an older phone and easier on the battery.',
                trailing: CupertinoSwitch(
                  value: app.lowBandwidthMode,
                  activeTrackColor: p.accent,
                  onChanged: app.setLowBandwidth,
                ),
              ),
              ListenableBuilder(
                listenable: SpeechService.instance,
                builder: (context, _) {
                  final speech = SpeechService.instance;
                  return Column(
                    children: [
                      GlassRow(
                        icon: CupertinoIcons.speaker_2_fill,
                        title: 'Read aloud',
                        subtitle:
                            'Shows a Listen button on careers, results, quiz questions and help answers. Uses your phone’s own voice, with no internet.',
                        trailing: CupertinoSwitch(
                          value: speech.enabled,
                          activeTrackColor: p.accent,
                          onChanged: speech.setEnabled,
                        ),
                      ),
                      if (speech.enabled)
                        GlassRow(
                          icon: CupertinoIcons.gauge,
                          title: 'Reading speed',
                          subtitle: 'Tap to hear a sample.',
                          onTap: speech.sample,
                          trailing: SizedBox(
                            width: 150,
                            child: CupertinoSlider(
                              value: speech.rate,
                              min: SpeechService.minRate,
                              max: SpeechService.maxRate,
                              activeColor: p.accent,
                              onChanged: speech.setRate,
                              onChangeEnd: (_) => speech.sample(),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          GlassSection(
            header: 'Reminders',
            footer: app.consentReminders
                ? 'Reminders are scheduled on this phone. Nothing is sent from a server, so no one outside your device knows you use this app.'
                : 'Turn on reminder consent below to enable this.',
            children: [
              GlassRow(
                icon: CupertinoIcons.bell_fill,
                title: 'Remind me about my next step',
                subtitle: app.consentReminders
                    ? 'A daily nudge about whatever you have not finished yet.'
                    : 'Requires reminder consent.',
                trailing: CupertinoSwitch(
                  value: app.remindersEnabled,
                  activeTrackColor: p.accent,
                  onChanged: app.consentReminders
                      ? (v) async {
                          final ok = await app.setRemindersEnabled(v);
                          if (!ok && context.mounted) {
                            _permissionDenied(context);
                          }
                        }
                      : null,
                ),
              ),
              GlassRow(
                icon: CupertinoIcons.eye_fill,
                title: 'Show me what a reminder looks like',
                subtitle: 'Sends one right now, so you can decide first.',
                showChevron: true,
                onTap: () => NotificationService.instance.showPreview(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          GlassSection(
            header: 'Privacy and your data',
            footer:
                'Khetha Go has no account, no backend and no analytics. Everything below lives in this app’s private storage on this phone.',
            children: [
              GlassRow(
                icon: CupertinoIcons.floppy_disk,
                title: 'Remember my progress',
                subtitle: 'Turning this off deletes what was saved.',
                trailing: CupertinoSwitch(
                  value: app.consentStoreProfile,
                  activeTrackColor: p.accent,
                  onChanged: app.setConsentStoreProfile,
                ),
              ),
              GlassRow(
                icon: CupertinoIcons.sparkles,
                title: 'Personalise my guidance',
                subtitle: 'Rank careers against my answers.',
                trailing: CupertinoSwitch(
                  value: app.consentPersonalisation,
                  activeTrackColor: p.accent,
                  onChanged: app.setConsentPersonalisation,
                ),
              ),
              GlassRow(
                icon: CupertinoIcons.bell,
                title: 'Allow reminders',
                trailing: CupertinoSwitch(
                  value: app.consentReminders,
                  activeTrackColor: p.accent,
                  onChanged: app.setConsentReminders,
                ),
              ),
              GlassRow(
                icon: CupertinoIcons.square_arrow_down,
                title: 'See everything stored about me',
                subtitle: 'Your full record, in readable form.',
                showChevron: true,
                onTap: () => _exportSheet(context),
              ),
              GlassRow(
                icon: CupertinoIcons.trash_fill,
                iconColor: p.danger,
                title: 'Delete all my data',
                subtitle: 'Permanent, and takes effect immediately.',
                showChevron: true,
                onTap: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          GlassSection(
            header: 'How this app works',
            children: [
              GlassRow(
                icon: CupertinoIcons.function,
                title: 'How matching works',
                subtitle: 'The model, its weights and its limits.',
                showChevron: true,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) => const MethodologyScreen())),
              ),
              GlassRow(
                icon: CupertinoIcons.square_stack_3d_down_right_fill,
                title: 'Data and sources',
                subtitle: 'Where the content comes from.',
                showChevron: true,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) => const DataSourcesScreen())),
              ),
              GlassRow(
                icon: CupertinoIcons.building_2_fill,
                title: 'Architecture and roadmap',
                subtitle: 'How this scales past the prototype.',
                showChevron: true,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) => const ArchitectureScreen())),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _SecuritySection(app: app),
          const SizedBox(height: 24),

          GlassSection(
            header: 'Legal',
            footer:
                'Both are written to be read rather than skipped. The privacy notice describes what the code actually does, so you can check it against the app in front of you.',
            children: [
              GlassRow(
                icon: CupertinoIcons.lock_fill,
                title: 'Privacy',
                subtitle:
                    'What is collected, where it lives, and your POPIA rights.',
                showChevron: true,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute<void>(
                    builder: (_) => const LegalScreen(showTerms: false))),
              ),
              GlassRow(
                icon: CupertinoIcons.doc_text_fill,
                title: 'Terms of use',
                subtitle: 'What this app is, and what it is not.',
                showChevron: true,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute<void>(
                    builder: (_) => const LegalScreen(showTerms: true))),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const GlassSection(
            header: 'About',
            footer:
                'Khetha Go · Version 1.0.0 · Built for the SITA GovTech Hackathon 2026, DHET challenge track.',
            children: [
              GlassRow(
                icon: CupertinoIcons.info_circle_fill,
                title: 'Khetha Go',
                subtitle:
                    'A mobile companion to the National Career Advice Portal, built by Nolifa Technologies.',
              ),
            ],
          ),
          const SizedBox(height: 10),
        ]),
      ],
    );
  }

  void _permissionDenied(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: const Text('Notifications are off'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
              'iOS is blocking notifications for Khetha Go. Turn them on in the Settings app under Notifications, then try again.'),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _textSizeSheet(BuildContext context) {
    showKhethaSheet(
      context,
      title: 'Text size',
      child: const _TextSizeControl(),
    );
  }

  void _exportSheet(BuildContext context) {
    final app = AppScope.read(context);
    final p = Palette.of(context);
    final json = app.exportProfileJson();

    showKhethaSheet(
      context,
      title: 'Everything stored about you',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This is the complete record Khetha Go holds. There is no other copy anywhere.',
            style: KhethaText.secondary(p),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.isDark
                  ? const Color(0xFF0A120D)
                  : const Color(0xFFF2F5F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.glassStroke, width: 0.6),
            ),
            child: Text(
              json,
              style: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 11.5,
                height: 1.45,
                color: p.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          KhethaButton(
            label: 'Copy to clipboard',
            icon: CupertinoIcons.doc_on_clipboard,
            onTap: () {
              Clipboard.setData(ClipboardData(text: json));
              closeSheet(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final app = AppScope.read(context);
    showCupertinoDialog<void>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: const Text('Delete everything?'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
              'Your answers, matches, saved careers and subject choices will be erased from this phone. This cannot be undone.'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              app.deleteAllData();
              Navigator.of(c).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SecuritySection extends StatefulWidget {
  final AppState app;
  const _SecuritySection({required this.app});

  @override
  State<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<_SecuritySection> {
  bool _canBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final can = await widget.app.canUseBiometrics;
    if (mounted) setState(() => _canBiometric = can);
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return GlassSection(
      header: 'Security',
      footer: 'A PIN locks the app when you reopen it. Face ID lets you unlock without typing. Your data stays on-device.',
      children: [
        GlassRow(
          icon: CupertinoIcons.lock_shield_fill,
          title: app.hasPin ? 'Remove PIN' : 'Set PIN',
          subtitle: app.hasPin
              ? 'Your profile is PIN-protected.'
              : 'Add a 4-digit PIN to protect your profile.',
          showChevron: !app.hasPin,
          trailing: app.hasPin
              ? CupertinoSwitch(
                  value: true,
                  activeTrackColor: Palette.govGreen,
                  onChanged: (_) async {
                    await app.removePin();
                  },
                )
              : null,
          onTap: app.hasPin
              ? null
              : () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                        builder: (_) => const LoginScreen()),
                  ),
        ),
        if (app.hasPin && _canBiometric)
          GlassRow(
            icon: CupertinoIcons.person_crop_circle_badge_checkmark,
            title: 'Face ID / Touch ID',
            subtitle: app.biometricEnabled
                ? 'Unlock with biometrics instead of PIN.'
                : 'Use biometrics to unlock faster.',
            trailing: CupertinoSwitch(
              value: app.biometricEnabled,
              activeTrackColor: Palette.govGreen,
              onChanged: (v) => app.setBiometricEnabled(v),
            ),
          ),
      ],
    );
  }
}

class _TextSizeControl extends StatefulWidget {
  const _TextSizeControl();

  @override
  State<_TextSizeControl> createState() => _TextSizeControlState();
}

class _TextSizeControlState extends State<_TextSizeControl> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = AppScope.read(context).textScale;
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Text(
            'Khetha Go helps you choose the subjects and career that fit you.',
            style: KhethaText.body(p).copyWith(fontSize: 16 * _value),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('A', style: TextStyle(fontSize: 14, color: p.textSecondary)),
            Expanded(
              child: CupertinoSlider(
                value: _value,
                min: 0.85,
                max: 1.45,
                divisions: 4,
                activeColor: p.accent,
                onChanged: (v) => setState(() => _value = v),
                onChangeEnd: app.setTextScale,
              ),
            ),
            Text('A', style: TextStyle(fontSize: 24, color: p.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'This is applied on top of your phone’s own text-size setting, so it works even if you have already made text larger system-wide.',
          style: KhethaText.caption(p),
        ),
      ],
    );
  }
}

/// Responsible-AI disclosure. Spells out the model, the weights, what it was
/// built from and - most importantly - what it cannot see.
class MethodologyScreen extends StatelessWidget {
  const MethodologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    return KhethaDetailPage(
      title: 'How matching works',
      slivers: [
        SliverSection(children: [
          const _Prose(
            title: 'A transparent model, on purpose',
            body:
                'Khetha Go scores careers with a weighted model that runs on your phone. It is not a neural network and it is not a chatbot. That is a deliberate choice: this app influences what a young person studies, and a recommendation nobody can inspect is not one a learner, a parent or a career practitioner should be asked to trust.',
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The three signals', style: KhethaText.headline(p)),
                const SizedBox(height: 12),
                const _Weight(
                  label: 'Interest match',
                  weight: CareerIntelligence.wInterest,
                  detail:
                      'Cosine similarity between your Holland (RIASEC) interest profile and the occupation’s. Shape matters, not how strongly you answered.',
                ),
                const _Weight(
                  label: 'Work style',
                  weight: CareerIntelligence.wWorkStyle,
                  detail:
                      'Overlap between the work-style traits your Job Fit answers produced and the traits the occupation calls for.',
                ),
                const _Weight(
                  label: 'Subject alignment',
                  weight: CareerIntelligence.wSubjects,
                  detail:
                      'How many of the occupation’s required subjects your choices satisfy. Scored as neutral, not zero, if you have not used the Subject Chooser.',
                ),
                const SizedBox(height: 6),
                Text(
                  'A further 4 points is added for occupations on the national list of occupations in high demand, and 6 for the field you told us you are interested in. Both are capped so labour-market data can never outweigh what you actually said.',
                  style: KhethaText.caption(p),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _Prose(
            title: 'Why Holland codes',
            body:
                'The interest questionnaire scores the six RIASEC dimensions - a published instrument used by career practitioners worldwide. Using it rather than an invented scale means your result is interpretable by the practitioner you speak to next, and comparable with any other assessment you take.',
          ),
          const SizedBox(height: 14),
          GlassCard(
            tint: p.warm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_circle_fill,
                        size: 18, color: p.warm),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text('What it cannot see',
                          style: KhethaText.headline(p)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final limit in const [
                  'Your marks. A 40% in Mathematics and an 80% are the same to this model.',
                  'Your finances, and whether you can afford to study away from home.',
                  'Transport, family responsibility and everything else that decides what is realistic.',
                  'What you are actually good at, as opposed to what interests you.',
                  'How the job market will look in five years when you finish studying.',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('· ', style: KhethaText.body(p)),
                        Expanded(
                            child: Text(limit, style: KhethaText.caption(p))),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'This is why every result in the app ends with the same suggestion: speak to a career practitioner. The model narrows the field. A person makes the call.',
                  style: KhethaText.caption(p).copyWith(
                      fontWeight: FontWeight.w600, color: p.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _Prose(
            title: 'Human oversight',
            body:
                'No result in Khetha Go is final or binding. Nothing is reported to a school, a department or an institution. The learner can retake any questionnaire, change any answer, see the full reasoning behind every score, and reach a human being from any screen in the app.',
          ),
        ]),
      ],
    );
  }
}

class _Weight extends StatelessWidget {
  final String label;
  final double weight;
  final String detail;

  const _Weight({
    required this.label,
    required this.weight,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.accentMuted,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text('${(weight * 100).round()}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.accent)),
              ),
              const SizedBox(width: 9),
              Expanded(child: Text(label, style: KhethaText.headline(p))),
            ],
          ),
          const SizedBox(height: 5),
          Text(detail, style: KhethaText.caption(p)),
        ],
      ),
    );
  }
}

class DataSourcesScreen extends StatelessWidget {
  const DataSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    return KhethaDetailPage(
      title: 'Data and sources',
      slivers: [
        SliverSection(children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Currently loaded', style: KhethaText.sectionLabel(p)),
                const SizedBox(height: 6),
                Text(Ncap.source.sourceName, style: KhethaText.headline(p)),
                const SizedBox(height: 6),
                Text(Ncap.source.sourceDescription,
                    style: KhethaText.caption(p)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                          value: '${Ncap.careers.length}',
                          label: 'Occupations'),
                    ),
                    Expanded(
                      child: _Stat(
                          value: '${Ncap.qualifications.length}',
                          label: 'Qualifications'),
                    ),
                    Expanded(
                      child: _Stat(
                          value: '${Ncap.providers.length}',
                          label: 'Institutions'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _Prose(
            title: 'Where it comes from',
            body:
                'Content is structured to mirror the National Career Advice Portal - the same careers, qualifications and learning providers, carrying the national identifiers those records already use: OFO codes for occupations, NQF levels and SAQA IDs for qualifications.',
          ),
          const SizedBox(height: 14),
          GlassCard(
            tint: p.warm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.info_circle_fill,
                        size: 17, color: p.warm),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text('This is a prototype dataset',
                          style: KhethaText.headline(p)),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  'The records bundled with this build are an illustrative subset prepared for the hackathon, not a live extract from DHET systems. Salary ranges are indicative. Verify any qualification against its SAQA ID before you act on it.',
                  style: KhethaText.caption(p),
                ),
                const SizedBox(height: 9),
                Text(
                  'In production the app reads DHET’s live NCAP feed through the same interface, and every screen stays exactly as it is.',
                  style: KhethaText.caption(p),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _Prose(
            title: 'Why it ships inside the app',
            body:
                'Bundling the content is what lets every feature work in aeroplane mode. A learner in a village with intermittent coverage gets the same questionnaires, the same matching and the same directories as a learner in Sandton, and pays nothing in data to get them.',
          ),
        ]),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: KhethaText.title(p).copyWith(color: p.accent)),
        Text(label, style: KhethaText.caption(p)),
      ],
    );
  }
}

class ArchitectureScreen extends StatelessWidget {
  const ArchitectureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    return KhethaDetailPage(
      title: 'Architecture',
      slivers: [
        SliverSection(children: [
          const _Prose(
            title: 'One codebase, both platforms',
            body:
                'Khetha Go is a single Flutter codebase that builds native iOS and Android apps. For a department maintaining a public service, that halves the surface to patch, test and fund - and it is the reason this prototype covers both platforms rather than one.',
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Swapping in live NCAP data',
                    style: KhethaText.headline(p)),
                const SizedBox(height: 9),
                Text(
                  'Every screen reads content through one interface, NcapDataSource. The prototype supplies LocalSeedSource. Connecting DHET’s live feed means writing a second implementation of that interface and changing one line in main().',
                  style: KhethaText.caption(p),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: p.isDark
                        ? const Color(0xFF0A120D)
                        : const Color(0xFFF2F5F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.glassStroke, width: 0.6),
                  ),
                  child: Text(
                    'await Ncap.load(\n  const LocalSeedSource(),\n);\n\n// becomes\n\nawait Ncap.load(\n  NcapApiSource(baseUrl),\n);',
                    style: TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 12,
                      height: 1.5,
                      color: p.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Methods on that interface are already asynchronous, so adding a network round trip does not force a rewrite of any caller.',
                  style: KhethaText.caption(p),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _Prose(
            title: 'Built on national standards',
            body:
                'Occupations carry OFO codes, qualifications carry NQF levels and SAQA IDs, and the interest instrument is the published Holland framework. Nothing in the data model is proprietary to this app, so records reconcile against DHET, QCTO and SAQA systems rather than becoming another island of data.',
          ),
          const SizedBox(height: 14),
          const _Prose(
            title: 'Dependency discipline',
            body:
                'The app uses four third-party packages: local storage, local notifications, URL launching and Cupertino icons. State management, theming, charts and the matching engine are all written against Flutter’s own primitives. Every dependency is a package a future maintainer has to keep patched, and a government codebase should carry as few as it can.',
          ),
          const SizedBox(height: 14),
          const _Prose(
            title: 'No backend to run',
            body:
                'The prototype has no server, which means no hosting bill, no database to secure, no personal data in a breach and nothing to scale when a million learners open it in January. Adding a live content feed later changes that only for content - the personal profile stays on the device by design.',
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What comes after the hackathon',
                    style: KhethaText.headline(p)),
                const SizedBox(height: 11),
                for (final item in const [
                  ('Live NCAP integration', 'Read occupations, qualifications and providers from DHET’s feed, with the bundled set as an offline cache.'),
                  ('Full content translation', 'Extend the five interface languages to all eleven, and translate occupation records at source with DHET.'),
                  ('Secure digital identity', 'Optional sign-in so a learner keeps their journey across a lost or shared phone, consent-gated and interoperable with government identity services.'),
                  ('Practitioner hand-off', 'Let a learner send their profile to a Khetha practitioner before a call, so the conversation starts from something real.'),
                  ('Bursary and application deadlines', 'NSFAS and institution dates surfaced as reminders, which is the single thing learners most often miss.'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(CupertinoIcons.circle_grid_hex_fill,
                              size: 13, color: p.accent),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$1, style: KhethaText.body(p).copyWith(
                                  fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(item.$2, style: KhethaText.caption(p)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}

class _Prose extends StatelessWidget {
  final String title;
  final String body;
  const _Prose({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KhethaText.headline(p)),
          const SizedBox(height: 8),
          Text(body, style: KhethaText.body(p).copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}
