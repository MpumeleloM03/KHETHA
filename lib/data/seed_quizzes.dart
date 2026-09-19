import '../models/career_models.dart';

/// Job Fit questionnaire.
///
/// Each answer contributes to a trait vector (how you like to work). Kept
/// short on purpose: a 5-question instrument that gets finished beats a
/// 40-question one that gets abandoned on a slow connection.
const List<QuizQuestion> jobFitQuestions = [
  QuizQuestion(
    id: 'jf1',
    question: 'When something needs solving, what do you reach for first?',
    helper: 'There is no wrong answer - pick what actually sounds like you.',
    options: [
      QuizOption(
        label: 'Break it down logically, step by step',
        traits: ['analytical'],
        riasec: {Riasec.investigative: 1.0, Riasec.conventional: 0.3},
      ),
      QuizOption(
        label: 'Get hands on it and work it out by doing',
        traits: ['hands-on'],
        riasec: {Riasec.realistic: 1.0, Riasec.investigative: 0.2},
      ),
      QuizOption(
        label: 'Talk it through with other people',
        traits: ['people-person'],
        riasec: {Riasec.social: 1.0, Riasec.enterprising: 0.4},
      ),
      QuizOption(
        label: 'Sketch out something new and creative',
        traits: ['creative'],
        riasec: {Riasec.artistic: 1.0, Riasec.enterprising: 0.2},
      ),
    ],
  ),
  QuizQuestion(
    id: 'jf2',
    question: 'Which of these sounds like a genuinely good day at work?',
    options: [
      QuizOption(
        label: 'Working through numbers, data and detail',
        traits: ['analytical', 'organised'],
        riasec: {Riasec.conventional: 1.0, Riasec.investigative: 0.6},
      ),
      QuizOption(
        label: 'Helping and caring for people directly',
        traits: ['caring', 'people-person'],
        riasec: {Riasec.social: 1.0},
      ),
      QuizOption(
        label: 'Designing or making something visual',
        traits: ['creative'],
        riasec: {Riasec.artistic: 1.0, Riasec.realistic: 0.3},
      ),
      QuizOption(
        label: 'Being outdoors, on site or with nature',
        traits: ['outdoors', 'hands-on'],
        riasec: {Riasec.realistic: 1.0, Riasec.investigative: 0.3},
      ),
    ],
  ),
  QuizQuestion(
    id: 'jf3',
    question: 'Your friends would describe you as:',
    options: [
      QuizOption(
        label: 'The organiser who keeps everyone on track',
        traits: ['organised'],
        riasec: {Riasec.conventional: 1.0, Riasec.enterprising: 0.4},
      ),
      QuizOption(
        label: 'The one everybody asks when something breaks',
        traits: ['problem-solver', 'hands-on'],
        riasec: {Riasec.realistic: 0.8, Riasec.investigative: 0.7},
      ),
      QuizOption(
        label: 'The creative one, always with a new idea',
        traits: ['creative'],
        riasec: {Riasec.artistic: 1.0},
      ),
      QuizOption(
        label: 'The one people come to when they need to talk',
        traits: ['caring', 'people-person'],
        riasec: {Riasec.social: 1.0},
      ),
    ],
  ),
  QuizQuestion(
    id: 'jf4',
    question: 'Which subject do you enjoy most - or think you would?',
    helper: 'Go with interest, not with the mark you got.',
    options: [
      QuizOption(
        label: 'Mathematics or Physical Sciences',
        traits: ['analytical', 'problem-solver'],
        riasec: {Riasec.investigative: 1.0, Riasec.realistic: 0.4},
      ),
      QuizOption(
        label: 'Life Sciences or Agricultural Sciences',
        traits: ['outdoors', 'analytical'],
        riasec: {Riasec.investigative: 0.8, Riasec.realistic: 0.7},
      ),
      QuizOption(
        label: 'Visual Arts, Design or Dramatic Arts',
        traits: ['creative', 'hands-on'],
        riasec: {Riasec.artistic: 1.0},
      ),
      QuizOption(
        label: 'Business Studies, Accounting or Economics',
        traits: ['organised', 'analytical'],
        riasec: {Riasec.conventional: 0.9, Riasec.enterprising: 0.7},
      ),
    ],
  ),
  QuizQuestion(
    id: 'jf5',
    question: 'Five years from now, you would love a job that:',
    options: [
      QuizOption(
        label: 'Lets you build and fix real things',
        traits: ['hands-on', 'problem-solver'],
        riasec: {Riasec.realistic: 1.0, Riasec.investigative: 0.4},
      ),
      QuizOption(
        label: 'Makes a direct difference in people’s lives',
        traits: ['caring', 'people-person'],
        riasec: {Riasec.social: 1.0},
      ),
      QuizOption(
        label: 'Gives you creative freedom every day',
        traits: ['creative'],
        riasec: {Riasec.artistic: 1.0, Riasec.enterprising: 0.3},
      ),
      QuizOption(
        label: 'Rewards precision, structure and results',
        traits: ['organised', 'analytical'],
        riasec: {Riasec.conventional: 1.0, Riasec.investigative: 0.4},
      ),
    ],
  ),
];

/// Career Choice questionnaire.
///
/// Where Job Fit asks *how* you like to work, this asks *what environment and
/// values* you want to work in. It scores the six Holland (RIASEC) interest
/// dimensions - a published, widely used instrument, so the resulting code is
/// something a career practitioner can pick up and interpret directly.
const List<QuizQuestion> careerChoiceQuestions = [
  QuizQuestion(
    id: 'cc1',
    question: 'Pick the activity you would choose on a free Saturday:',
    options: [
      QuizOption(
        label: 'Fixing a bike, building something, working on a car',
        riasec: {Riasec.realistic: 1.0},
      ),
      QuizOption(
        label: 'Reading about how something works, or a documentary',
        riasec: {Riasec.investigative: 1.0},
      ),
      QuizOption(
        label: 'Drawing, making music, editing photos or video',
        riasec: {Riasec.artistic: 1.0},
      ),
      QuizOption(
        label: 'Volunteering, coaching or helping at a community event',
        riasec: {Riasec.social: 1.0},
      ),
    ],
  ),
  QuizQuestion(
    id: 'cc2',
    question: 'In a group project, you naturally end up:',
    options: [
      QuizOption(
        label: 'Leading it and pushing everyone to deliver',
        riasec: {Riasec.enterprising: 1.0},
      ),
      QuizOption(
        label: 'Keeping the plan, the notes and the deadlines straight',
        riasec: {Riasec.conventional: 1.0},
      ),
      QuizOption(
        label: 'Doing the research nobody else wants to do',
        riasec: {Riasec.investigative: 1.0},
      ),
      QuizOption(
        label: 'Making sure everyone is heard and the team holds together',
        riasec: {Riasec.social: 1.0},
      ),
    ],
  ),
  QuizQuestion(
    id: 'cc3',
    question: 'Which work environment appeals to you most?',
    options: [
      QuizOption(
        label: 'On site, in a workshop, or outdoors',
        riasec: {Riasec.realistic: 1.0},
      ),
      QuizOption(
        label: 'A studio where the work changes every week',
        riasec: {Riasec.artistic: 1.0},
      ),
      QuizOption(
        label: 'A lab, a research unit or a university',
        riasec: {Riasec.investigative: 1.0},
      ),
      QuizOption(
        label: 'An office with clear systems and a clear structure',
        riasec: {Riasec.conventional: 1.0},
      ),
    ],
  ),
  QuizQuestion(
    id: 'cc4',
    question: 'What matters most to you in a job?',
    helper: 'Be honest rather than impressive - the match depends on it.',
    options: [
      QuizOption(
        label: 'Earning well and moving up quickly',
        riasec: {Riasec.enterprising: 1.0, Riasec.conventional: 0.3},
      ),
      QuizOption(
        label: 'Doing work that helps people who need it',
        riasec: {Riasec.social: 1.0},
      ),
      QuizOption(
        label: 'Being free to do things my own way',
        riasec: {Riasec.artistic: 1.0, Riasec.enterprising: 0.3},
      ),
      QuizOption(
        label: 'Job security and knowing what each day looks like',
        riasec: {Riasec.conventional: 1.0, Riasec.realistic: 0.3},
      ),
    ],
  ),
  QuizQuestion(
    id: 'cc5',
    question: 'Which compliment would mean the most to you?',
    options: [
      QuizOption(
        label: '"You figured out something nobody else could."',
        riasec: {Riasec.investigative: 1.0},
      ),
      QuizOption(
        label: '"You made this, and it works perfectly."',
        riasec: {Riasec.realistic: 1.0},
      ),
      QuizOption(
        label: '"Nobody else would have thought of that."',
        riasec: {Riasec.artistic: 1.0},
      ),
      QuizOption(
        label: '"You changed things for me."',
        riasec: {Riasec.social: 1.0},
      ),
    ],
  ),
  QuizQuestion(
    id: 'cc6',
    question: 'How do you feel about starting your own business one day?',
    options: [
      QuizOption(
        label: 'That is the goal - I want to run my own thing',
        riasec: {Riasec.enterprising: 1.0},
      ),
      QuizOption(
        label: 'Maybe, once I have a trade or skill behind me',
        riasec: {Riasec.realistic: 0.8, Riasec.enterprising: 0.6},
      ),
      QuizOption(
        label: 'I would rather be an expert than a boss',
        riasec: {Riasec.investigative: 0.9, Riasec.artistic: 0.3},
      ),
      QuizOption(
        label: 'I would prefer a stable job with a good employer',
        riasec: {Riasec.conventional: 1.0},
      ),
    ],
  ),
];

/// Plain-language description of each trait, used by the explanation engine.
const Map<String, String> traitPhrases = {
  'analytical': 'you like breaking problems down logically',
  'hands-on': 'you would rather build and fix things yourself',
  'people-person': 'you are drawn to work that puts you around people',
  'creative': 'you think creatively and want room to design',
  'caring': 'you want work that helps and supports other people',
  'organised': 'you value structure, accuracy and a clear plan',
  'outdoors': 'you would rather be outside than behind a desk',
  'problem-solver': 'you get energy from solving difficult problems',
};

const Map<String, String> traitLabels = {
  'analytical': 'Analytical',
  'hands-on': 'Hands-on',
  'people-person': 'People-focused',
  'creative': 'Creative',
  'caring': 'Caring',
  'organised': 'Organised',
  'outdoors': 'Outdoors',
  'problem-solver': 'Problem-solver',
};
