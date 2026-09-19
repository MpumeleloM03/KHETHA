import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khetha_ncap/data/ncap_repository.dart';
import 'package:khetha_ncap/main.dart';
import 'package:khetha_ncap/models/application_models.dart';
import 'package:khetha_ncap/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget tests for navigation and the application flow.
///
/// These exist because driving a simulator by coordinates is not a reliable way
/// to prove the tab bar works — taps and screenshots race. Pumping the real
/// widget tree and tapping by label is deterministic.
void main() {
  setUpAll(() async {
    await Ncap.load(const LocalSeedSource());
  });

  setUp(() {
    // A phone-shaped surface. The default 800x600 test window is wider and
    // shorter than any device this app runs on, which changes what is laid out
    // and what has scrolled off.
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402 * 3, 874 * 3);
    view.devicePixelRatio = 3.0;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  /// Scrolls the visible scroll view until [finder] is on screen.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(CustomScrollView).last,
      const Offset(0, -220),
      maxIteration: 40,
    );
    await tester.pumpAndSettle();
  }

  /// Boots the app with a given set of stored preferences.
  Future<AppState> boot(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      'flutter.hasSeenWelcome': true,
      'flutter.acceptedTerms': true,
      'flutter.consentStoreProfile': true,
      'flutter.consentPersonalisation': true,
      // Blur and ambient layers are pure cost in a test and make the tree
      // deeper than it needs to be.
      'flutter.lowBandwidthMode': true,
      ...prefs,
    });

    final state = AppState(await SharedPreferences.getInstance());
    await tester.pumpWidget(KhethaGo(state: state));
    await tester.pumpAndSettle();
    return state;
  }

  String resultsJson() =>
      '{"kind":"nscFinal","capturedAt":"2026-09-17T20:00:00.000",'
      '"source":"test","subjects":['
      '{"subject":"English Home Language","percentage":68},'
      '{"subject":"Mathematics","percentage":45},'
      '{"subject":"Accounting","percentage":72},'
      '{"subject":"Business Studies","percentage":70},'
      '{"subject":"Economics","percentage":65},'
      '{"subject":"Geography","percentage":60},'
      '{"subject":"Life Orientation","percentage":78}]}';

  group('navigation', () {
    testWidgets('opens on the dashboard', (tester) async {
      await boot(tester);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Explore Services'), findsOneWidget);
    });

    testWidgets('every tab is reachable and shows its own screen',
        (tester) async {
      await boot(tester);

      // Each tab's own title, which only that screen renders.
      const destinations = <String, String>{
        'Explore': 'Explore',
        'Apply': 'Apply',
        'Journey': 'Journey',
        'Support': 'Support',
      };

      for (final entry in destinations.entries) {
        await tester.tap(find.text(entry.key).last);
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsWidgets,
            reason: 'tapping ${entry.key} did not show its screen');
      }

      await tester.tap(find.text('Today').last);
      await tester.pumpAndSettle();
      expect(find.text('Explore Services'), findsOneWidget);
    });

    testWidgets('each tab keeps its own navigation stack', (tester) async {
      await boot(tester);

      // Push a page inside Today.
      await reveal(tester, find.text('Explore Degrees'));
      await tester.tap(find.text('Explore Degrees'));
      await tester.pumpAndSettle();
      // A large-title nav bar renders the title twice: the large one and the
      // collapsed one it fades into.
      expect(find.text('What you can study'), findsWidgets);

      // Switch away and back; the pushed page should still be there.
      await tester.tap(find.text('Explore').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Today').last);
      await tester.pumpAndSettle();

      expect(find.text('What you can study'), findsWidgets,
          reason: 'the Today tab lost its navigation stack');
    });
  });

  group('dashboard reacts to what the learner has done', () {
    testWidgets('with nothing captured it asks for results', (tester) async {
      await boot(tester);
      expect(find.text('Add your results'), findsOneWidget);
    });

    testWidgets('with results it shows the APS and stops asking',
        (tester) async {
      await boot(tester, prefs: {'flutter.results': resultsJson()});

      // APS for those marks: 6+6+5+5+5+3 = 30.
      expect(find.text('30'), findsWidgets);
      expect(find.text('Add your results'), findsNothing);
    });

    testWidgets('a Grade 9 learner is pointed at subject choice',
        (tester) async {
      await boot(tester, prefs: {
        'flutter.profile': '{"grade":"Grade 9"}',
      });
      expect(find.text('Choose your subjects properly'), findsOneWidget);
      await reveal(tester, find.text('Grade 9 subject choice'));
      expect(find.text('Grade 9 subject choice'), findsOneWidget);
    });
  });

  group('application flow', () {
    String applicationsJson(String state) =>
        '[{"providerId":"p_ukzn","qualificationId":"q_bsw",'
        '"state":"$state","updatedAt":"2026-09-17T20:00:00.000"}]';

    String documentsJson() => '['
        '{"kind":"identity","fileName":"id.jpg","capturedAt":"2026-09-17T20:00:00.000"},'
        '{"kind":"results","fileName":"nsc.pdf","capturedAt":"2026-09-17T20:00:00.000"},'
        '{"kind":"proofOfResidence","fileName":"bill.pdf","capturedAt":"2026-09-17T20:00:00.000"}'
        ']';

    testWidgets('without documents the send button is disabled',
        (tester) async {
      await boot(tester, prefs: {
        'flutter.results': resultsJson(),
        'flutter.applications': applicationsJson('draft'),
      });

      await tester.tap(find.text('Apply').last);
      await tester.pumpAndSettle();

      await reveal(tester, find.text('Complete your documents first'));
      expect(find.text('Complete your documents first'), findsOneWidget);
      expect(find.textContaining('Send all'), findsNothing);
    });

    testWidgets('with a complete pack the send button appears',
        (tester) async {
      await boot(tester, prefs: {
        'flutter.results': resultsJson(),
        'flutter.applications': applicationsJson('draft'),
        'flutter.documents': documentsJson(),
        'flutter.idNumber': '0703155234086',
      });

      await tester.tap(find.text('Apply').last);
      await tester.pumpAndSettle();

      await reveal(tester, find.textContaining('Send all 1'));
      expect(find.textContaining('Send all 1'), findsOneWidget);
    });

    testWidgets('sending moves a draft to a decided outcome', (tester) async {
      final state = await boot(tester, prefs: {
        'flutter.results': resultsJson(),
        'flutter.applications': applicationsJson('draft'),
        'flutter.documents': documentsJson(),
        'flutter.idNumber': '0703155234086',
      });

      await tester.tap(find.text('Apply').last);
      await tester.pumpAndSettle();

      await reveal(tester, find.textContaining('Send all 1'));
      await tester.tap(find.textContaining('Send all 1'));
      await tester.pump();

      // The submission is deliberately paced one institution at a time, so the
      // clock has to be advanced rather than settled.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      await tester.pumpAndSettle();

      expect(state.draftApplications, isEmpty,
          reason: 'the draft was never submitted');
      expect(state.applications.single.state.isFinal, isTrue,
          reason: 'no outcome was reached');
      expect(state.applications.single.reference, isNotNull,
          reason: 'no reference number was issued');
    });

    testWidgets('the prototype notice is always on the Apply tab',
        (tester) async {
      await boot(tester);
      await tester.tap(find.text('Apply').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Prototype'));
      expect(find.text('Prototype'), findsOneWidget);
    });
  });

  group('legal', () {
    testWidgets('a first run cannot continue without accepting the terms',
        (tester) async {
      SharedPreferences.setMockInitialValues({'flutter.lowBandwidthMode': true});
      final state = AppState(await SharedPreferences.getInstance());
      await tester.pumpWidget(KhethaGo(state: state));
      await tester.pumpAndSettle();

      // Step 1 and 2 are informational.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Get started'), findsOneWidget);
      expect(state.acceptedTerms, isFalse);

      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      // Still on the consent step, because the terms were never accepted.
      expect(find.text('Get started'), findsOneWidget);
      expect(state.hasSeenWelcome, isFalse);
    });
  });

  group('Explore filters', () {
    testWidgets('picking a field applies the filter and closes the sheet',
        (tester) async {
      await boot(tester);

      await tester.tap(find.text('Explore').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('All fields'));
      await tester.pumpAndSettle();
      expect(find.text('Filter by field'), findsOneWidget);

      await tester.tap(find.text('Health Sciences').last);
      await tester.pumpAndSettle();

      // The sheet must be gone...
      expect(find.text('Filter by field'), findsNothing,
          reason: 'the filter sheet stayed open');
      // ...and the Explore screen must still be there. The bug popped the
      // tab's only route instead of the sheet, leaving a blank tab.
      expect(find.text('Explore'), findsWidgets,
          reason: 'the Explore tab was torn down by the pop');
      expect(find.text('Health Sciences'), findsWidgets);
    });

    testWidgets('switching tabs clears the search box, not just the query',
        (tester) async {
      await boot(tester);
      await tester.tap(find.text('Explore').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CupertinoSearchTextField), 'nurse');
      await tester.pumpAndSettle();
      expect(find.text('nurse'), findsWidgets);

      await tester.tap(find.text('What to Study'));
      await tester.pumpAndSettle();

      expect(find.text('nurse'), findsNothing,
          reason: 'the search box kept stale text after a tab switch');
    });
  });

  group('consent withdrawal', () {
    testWidgets('withdrawing storage consent erases the session data too',
        (tester) async {
      final state = await boot(tester, prefs: {
        'flutter.results': resultsJson(),
        'flutter.profile': '{"displayName":"Thandi","grade":"Grade 12"}',
        'flutter.idNumber': '0703155234086',
      });

      expect(state.results, isNotNull);
      expect(state.profile.displayName, 'Thandi');

      await state.setConsentStoreProfile(false);

      expect(state.results, isNull, reason: 'results survived withdrawal');
      expect(state.idNumber, isNull, reason: 'ID number survived withdrawal');
      expect(state.profile.displayName, isNull,
          reason: 'the profile survived withdrawal');

      // The real defect: turning the switch back on used to re-persist the
      // data the learner had just withdrawn.
      await state.setConsentStoreProfile(true);
      expect(state.results, isNull);
      expect(state.profile.displayName, isNull,
          reason: 'withdrawn data came back when consent was re-granted');
    });
  });
}
