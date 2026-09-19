import '../models/career_models.dart';

/// Khetha Interest Profiler.
///
/// A 30-item interest inventory built on Holland's RIASEC model: six interest
/// dimensions (Realistic, Investigative, Artistic, Social, Enterprising,
/// Conventional), five items each, answered on a five-point enjoyment scale.
///
/// Items are interleaved R, I, A, S, E, C and repeat, so a learner who stops
/// part-way still has an equal number of items from every dimension and a
/// usable - if rougher - Holland code.
///
/// All items are original, written for this app for a 15–18 year old in South
/// Africa. They are not taken from the Strong Interest Inventory, the
/// Self-Directed Search, or any other copyrighted instrument. The public-domain
/// O*NET Interest Profiler informed the structure only - short activity
/// statements, enjoyment framing, balanced dimensions - never the wording.
///
/// This is NOT a validated psychometric instrument. It has no published norms,
/// no reliability or validity coefficients, and no standardisation sample. It
/// is a structured self-reflection aid to open a conversation about careers,
/// not a test result to decide a future on.
///
/// Takes roughly 4–6 minutes to complete.

/// One profiler item. The question stem ("Would you enjoy…") lives in the UI,
/// so each item carries only the activity itself.
class _Item {
  final String id;
  final String text;
  final Riasec dim;
  final List<String> traits;
  final int section;

  const _Item(this.id, this.text, this.dim, this.traits, this.section);
}

const List<_Item> _items = [
  // Section 0 - items 1-10
  _Item('ip01', 'Fix a tap that keeps leaking at home', Riasec.realistic,
      ['hands-on', 'problem-solver'], 0),
  _Item('ip02', 'Find out why one corner of a garden never grows',
      Riasec.investigative, ['analytical'], 0),
  _Item('ip03', 'Draw the poster for a school event', Riasec.artistic,
      ['creative'], 0),
  _Item('ip04', 'Help a younger learner who is behind in maths', Riasec.social,
      ['caring', 'people-person'], 0),
  _Item('ip05', 'Sell snacks at school and grow the money', Riasec.enterprising,
      ['people-person', 'organised'], 0),
  _Item('ip06', 'Keep a neat record of money a group has collected',
      Riasec.conventional, ['organised'], 0),
  _Item('ip07', 'Change a flat tyre on a bakkie', Riasec.realistic,
      ['hands-on'], 0),
  _Item('ip08', 'Test which cooldrink people actually prefer',
      Riasec.investigative, ['analytical', 'problem-solver'], 0),
  _Item('ip09', 'Write and record a song on your phone', Riasec.artistic,
      ['creative'], 0),
  _Item('ip10', 'Sit with a friend who is upset and listen', Riasec.social,
      ['caring'], 0),

  // Section 1 - items 11-20
  _Item('ip11', 'Convince a shop owner to sponsor your team',
      Riasec.enterprising, ['people-person'], 1),
  _Item('ip12', 'Check a long list of names for spelling mistakes',
      Riasec.conventional, ['organised', 'analytical'], 1),
  _Item('ip13', 'Build a shelf out of wood and screws', Riasec.realistic,
      ['hands-on'], 1),
  _Item('ip14', 'Work out why the wifi keeps dropping', Riasec.investigative,
      ['problem-solver', 'analytical'], 1),
  _Item('ip15', 'Design the layout of a school magazine', Riasec.artistic,
      ['creative'], 1),
  _Item('ip16', 'Teach a small group how to use a new app', Riasec.social,
      ['people-person', 'caring'], 1),
  _Item('ip17', 'Lead a team and set the plan for the week',
      Riasec.enterprising, ['people-person', 'organised'], 1),
  _Item('ip18', 'Sort stock on shelves so nothing runs out',
      Riasec.conventional, ['organised'], 1),
  _Item('ip19', 'Look after animals on a farm for a day', Riasec.realistic,
      ['outdoors', 'hands-on'], 1),
  _Item('ip20', 'Test water at a river to see if it is safe',
      Riasec.investigative, ['analytical', 'outdoors'], 1),

  // Section 2 - items 21-30
  _Item('ip21', 'Edit a video clip until it looks right', Riasec.artistic,
      ['creative'], 2),
  _Item('ip22', 'Help an older person fill in a clinic form', Riasec.social,
      ['caring', 'people-person'], 2),
  _Item('ip23', 'Start a small car wash in your street', Riasec.enterprising,
      ['people-person', 'organised'], 2),
  _Item('ip24', 'Book appointments and keep a diary for a busy office',
      Riasec.conventional, ['organised'], 2),
  _Item('ip25', 'Wire a plug and get the light working again', Riasec.realistic,
      ['hands-on', 'problem-solver'], 2),
  _Item('ip26', 'Work out why a spaza shop is losing money',
      Riasec.investigative, ['analytical', 'problem-solver'], 2),
  _Item('ip27', 'Choose the colours and fonts for a new logo', Riasec.artistic,
      ['creative'], 2),
  _Item('ip28', 'Run a soccer practice for young kids', Riasec.social,
      ['people-person', 'caring'], 2),
  _Item('ip29', 'Speak in front of a crowd to get them to join in',
      Riasec.enterprising, ['people-person'], 2),
  _Item('ip30', 'Add up receipts until the totals balance', Riasec.conventional,
      ['organised', 'analytical'], 2),
];

/// The five enjoyment anchors, shown in this order.
const List<String> likertLabels = [
  'Would hate it',
  'Not really',
  "It's okay",
  'Would like it',
  'Would love it',
];

/// Score contributed by each anchor, index-matched to [likertLabels].
const List<double> likertWeights = [0.0, 0.25, 0.5, 0.75, 1.0];

/// Short names for the three blocks the profiler is broken into.
const List<String> sectionTitles = [
  'Things you do',
  'Ways you work',
  'Work you would choose',
];

/// Items per section.
const int sectionSize = 10;

/// The profiler, as questions the existing quiz engine can run.
///
/// Traits are attached only at the top two anchors: liking an activity says
/// something about you, disliking it says much less.
final List<QuizQuestion> interestProfilerQuestions = _items
    .map(
      (item) => QuizQuestion(
        id: item.id,
        question: item.text,
        dimension: item.dim,
        section: item.section,
        options: [
          for (var i = 0; i < likertLabels.length; i++)
            QuizOption(
              label: likertLabels[i],
              weight: likertWeights[i],
              traits: likertWeights[i] >= 0.75 ? item.traits : const [],
              riasec: {item.dim: likertWeights[i]},
            ),
        ],
      ),
    )
    .toList(growable: false);
