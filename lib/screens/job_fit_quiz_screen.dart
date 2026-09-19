import 'package:flutter/cupertino.dart';

import '../data/ncap_repository.dart';
import '../models/career_models.dart';
import '../state/app_state.dart';
import 'quiz_runner.dart';
import 'results_screen.dart';

/// NCAP's Job Fit questionnaire, rebuilt for mobile.
///
/// Answers accumulate a work-style trait vector and also feed the interest
/// profile, so a learner who only ever completes this one still gets a usable
/// result instead of being told to come back after another questionnaire.
class JobFitQuizScreen extends StatelessWidget {
  const JobFitQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return QuizRunner(
      title: 'Job Fit',
      intro:
          'Five questions about how you like to work, not what you know. Answer with what actually sounds like you, and Khetha Go will match careers to it and show you why.',
      questions: Ncap.jobFit,
      onComplete: (answers) async {
        final traits = <String, int>{};
        final riasec = <Riasec, double>{};

        for (final a in answers) {
          for (final t in a.traits) {
            traits[t] = (traits[t] ?? 0) + 1;
          }
          for (final entry in a.riasec.entries) {
            riasec[entry.key] = (riasec[entry.key] ?? 0) + entry.value;
          }
        }

        final app = AppScope.read(context);
        await app.applyJobFitResult(traits, riasec);

        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (_) => const ResultsScreen(source: 'Job Fit Quiz'),
          ),
        );
      },
    );
  }
}
