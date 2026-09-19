import 'package:flutter/cupertino.dart';

import '../data/ncap_repository.dart';
import '../models/career_models.dart';
import '../state/app_state.dart';
import 'quiz_runner.dart';
import 'results_screen.dart';

/// NCAP's Career Choice questionnaire.
///
/// Scores the six Holland (RIASEC) interest dimensions. Where Job Fit asks how
/// you like to work, this asks what you want to work on - and because it uses
/// a published instrument, the resulting code means something to a career
/// practitioner the learner later speaks to.
class CareerChoiceScreen extends StatelessWidget {
  const CareerChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return QuizRunner(
      title: 'Career Choice',
      intro:
          'Six questions about what you want out of work - the environment, the values, the kind of day. This works out your interest code, which is the same measure a career practitioner uses.',
      questions: Ncap.careerChoice,
      onComplete: (answers) async {
        final riasec = <Riasec, double>{};
        for (final a in answers) {
          for (final entry in a.riasec.entries) {
            riasec[entry.key] = (riasec[entry.key] ?? 0) + entry.value;
          }
        }

        final app = AppScope.read(context);
        await app.applyCareerChoiceResult(riasec);

        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (_) =>
                const ResultsScreen(source: 'Career Choice questionnaire'),
          ),
        );
      },
    );
  }
}
