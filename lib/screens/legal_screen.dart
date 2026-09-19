import 'package:flutter/cupertino.dart';

import '../data/seed_legal.dart';
import '../theme/palette.dart';
import '../theme/glass.dart';
import '../widgets/page_shell.dart';

/// Privacy notice and terms.
///
/// Both are written in the app's own voice rather than in legal boilerplate,
/// and the privacy notice describes what the code actually does, so a reader
/// can check it against the behaviour of the app in front of them.
class LegalScreen extends StatelessWidget {
  final bool showTerms;
  const LegalScreen({super.key, required this.showTerms});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final sections = showTerms ? termsAndConditions : privacyPolicy;

    return KhethaDetailPage(
      title: showTerms ? 'Terms of use' : 'Privacy',
      slivers: [
        SliverSection(children: [
          Text(privacyUpdated, style: KhethaText.caption(p)),
          const SizedBox(height: 16),
          for (final section in sections) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.heading, style: KhethaText.headline(p)),
                  const SizedBox(height: 8),
                  Text(section.body,
                      style: KhethaText.body(p).copyWith(fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ]),
      ],
    );
  }
}
