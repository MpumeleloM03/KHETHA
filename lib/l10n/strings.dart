import 'package:flutter/cupertino.dart';

import '../state/app_state.dart';

/// Interface strings in five of South Africa's official languages.
///
/// Scope is stated honestly in Settings: the interface, navigation and every
/// instruction a learner needs to operate the app are translated. The
/// occupation and qualification records are not - those come from NCAP and
/// would be translated at source, by DHET, rather than by this app guessing.
/// Claiming otherwise would be worse than the gap itself.
class S {
  final AppLanguage lang;
  const S(this.lang);

  static S of(BuildContext context) => S(AppScope.of(context).language);

  String _t(Map<AppLanguage, String> m) => m[lang] ?? m[AppLanguage.en]!;

  // ---- Navigation ------------------------------------------------------
  String get tabHome => _t({
        AppLanguage.en: 'Home',
        AppLanguage.zu: 'Ikhaya',
        AppLanguage.xh: 'Ikhaya',
        AppLanguage.st: 'Lehae',
        AppLanguage.af: 'Tuis',
      });

  String get tabExplore => _t({
        AppLanguage.en: 'Explore',
        AppLanguage.zu: 'Hlola',
        AppLanguage.xh: 'Phonononga',
        AppLanguage.st: 'Batlisisa',
        AppLanguage.af: 'Verken',
      });

  String get tabApply => _t({
        AppLanguage.en: 'Apply',
        AppLanguage.zu: 'Faka isicelo',
        AppLanguage.xh: 'Faka isicelo',
        AppLanguage.st: 'Etsa kopo',
        AppLanguage.af: 'Aansoek',
      });

  String get tabJourney => _t({
        AppLanguage.en: 'Journey',
        AppLanguage.zu: 'Uhambo',
        AppLanguage.xh: 'Uhambo',
        AppLanguage.st: 'Leeto',
        AppLanguage.af: 'Reis',
      });

  String get tabSupport => _t({
        AppLanguage.en: 'Support',
        AppLanguage.zu: 'Usizo',
        AppLanguage.xh: 'Inkxaso',
        AppLanguage.st: 'Thuso',
        AppLanguage.af: 'Hulp',
      });

  String get tabSettings => _t({
        AppLanguage.en: 'Settings',
        AppLanguage.zu: 'Izilungiselelo',
        AppLanguage.xh: 'Iisetingi',
        AppLanguage.st: 'Litlhophiso',
        AppLanguage.af: 'Instellings',
      });

  // ---- Home ------------------------------------------------------------
  String get greetingMorning => _t({
        AppLanguage.en: 'Good morning',
        AppLanguage.zu: 'Sawubona ekuseni',
        AppLanguage.xh: 'Molo kusasa',
        AppLanguage.st: 'Dumela hoseng',
        AppLanguage.af: 'Goeiemôre',
      });

  String get greetingAfternoon => _t({
        AppLanguage.en: 'Good afternoon',
        AppLanguage.zu: 'Sawubona ntambama',
        AppLanguage.xh: 'Molo emva kwemini',
        AppLanguage.st: 'Dumela mantsiboya',
        AppLanguage.af: 'Goeiemiddag',
      });

  String get greetingEvening => _t({
        AppLanguage.en: 'Good evening',
        AppLanguage.zu: 'Sawubona kusihlwa',
        AppLanguage.xh: 'Molo ngokuhlwa',
        AppLanguage.st: 'Dumela mantsiboea',
        AppLanguage.af: 'Goeienaand',
      });

  String get tagline => _t({
        AppLanguage.en: 'Your career guidance companion, on the go.',
        AppLanguage.zu: 'Umngane wakho oqondisa umsebenzi, noma ngabe ukuphi.',
        AppLanguage.xh: 'Umkhaphi wakho wesikhokelo somsebenzi, naphi na.',
        AppLanguage.st: 'Motsamaisi wa hao wa mesebetsi, kae kapa kae.',
        AppLanguage.af: 'Jou loopbaangids, oral saam met jou.',
      });

  String get startHere => _t({
        AppLanguage.en: 'Start here',
        AppLanguage.zu: 'Qala lapha',
        AppLanguage.xh: 'Qala apha',
        AppLanguage.st: 'Qala mona',
        AppLanguage.af: 'Begin hier',
      });

  String get yourNextStep => _t({
        AppLanguage.en: 'Your next step',
        AppLanguage.zu: 'Isinyathelo sakho esilandelayo',
        AppLanguage.xh: 'Inyathelo lakho elilandelayo',
        AppLanguage.st: 'Mohato wa hao o latelang',
        AppLanguage.af: 'Jou volgende stap',
      });

  String get tools => _t({
        AppLanguage.en: 'Career tools',
        AppLanguage.zu: 'Amathuluzi emisebenzi',
        AppLanguage.xh: 'Izixhobo zomsebenzi',
        AppLanguage.st: 'Lisebelisoa tsa mesebetsi',
        AppLanguage.af: 'Loopbaan-gereedskap',
      });

  // ---- Tools ------------------------------------------------------------
  String get subjectChooser => _t({
        AppLanguage.en: 'Subject Chooser',
        AppLanguage.zu: 'Ukukhetha Izifundo',
        AppLanguage.xh: 'Ukhetho Lwezifundo',
        AppLanguage.st: 'Khetha Lithuto',
        AppLanguage.af: 'Vakkeuse',
      });

  String get subjectChooserSub => _t({
        AppLanguage.en: 'Find the subjects that keep your career open',
        AppLanguage.zu: 'Thola izifundo ezivula umsebenzi owufunayo',
        AppLanguage.xh: 'Fumana izifundo ezivula umsebenzi owufunayo',
        AppLanguage.st: 'Fumana lithuto tse bulang mosebetsi oo o o batlang',
        AppLanguage.af: 'Vind die vakke wat jou loopbaan oophou',
      });

  String get jobFit => _t({
        AppLanguage.en: 'Job Fit Quiz',
        AppLanguage.zu: 'Uhlolo Lomsebenzi Okufanele',
        AppLanguage.xh: 'Uvavanyo Lomsebenzi Okufaneleyo',
        AppLanguage.st: 'Tlhahlobo ya Mosebetsi o o Loketseng',
        AppLanguage.af: 'Werkpas-vasvra',
      });

  String get jobFitSub => _t({
        AppLanguage.en: 'Five questions. Careers that match how you work.',
        AppLanguage.zu: 'Imibuzo emihlanu. Imisebenzi ehambisana nawe.',
        AppLanguage.xh: 'Imibuzo emihlanu. Imisebenzi ehambelana nawe.',
        AppLanguage.st: 'Lipotso tse hlano. Mesebetsi e lumellanang le uena.',
        AppLanguage.af: 'Vyf vrae. Loopbane wat by jou pas.',
      });

  String get careerChoice => _t({
        AppLanguage.en: 'Career Choice',
        AppLanguage.zu: 'Ukukhetha Umsebenzi',
        AppLanguage.xh: 'Ukhetho Lomsebenzi',
        AppLanguage.st: 'Khetho ya Mosebetsi',
        AppLanguage.af: 'Loopbaankeuse',
      });

  String get careerChoiceSub => _t({
        AppLanguage.en: 'Six questions. Works out your interest code.',
        AppLanguage.zu: 'Imibuzo eyisithupha. Ithola ikhodi yezintshisekelo zakho.',
        AppLanguage.xh: 'Imibuzo emithandathu. Ifumana ikhowudi yomdla wakho.',
        AppLanguage.st: 'Lipotso tse tšeletseng. E fumana khoutu ea thahasello.',
        AppLanguage.af: 'Ses vrae. Bepaal jou belangstellingskode.',
      });

  // ---- Common actions ----------------------------------------------------
  String get continueLabel => _t({
        AppLanguage.en: 'Continue',
        AppLanguage.zu: 'Qhubeka',
        AppLanguage.xh: 'Qhubeka',
        AppLanguage.st: 'Tswela pele',
        AppLanguage.af: 'Gaan voort',
      });

  String get done => _t({
        AppLanguage.en: 'Done',
        AppLanguage.zu: 'Kwenziwe',
        AppLanguage.xh: 'Kwenziwe',
        AppLanguage.st: 'E entswe',
        AppLanguage.af: 'Klaar',
      });

  String get search => _t({
        AppLanguage.en: 'Search',
        AppLanguage.zu: 'Sesha',
        AppLanguage.xh: 'Khangela',
        AppLanguage.st: 'Batla',
        AppLanguage.af: 'Soek',
      });

  String get careers => _t({
        AppLanguage.en: 'Careers',
        AppLanguage.zu: 'Imisebenzi',
        AppLanguage.xh: 'Imisebenzi',
        AppLanguage.st: 'Mesebetsi',
        AppLanguage.af: 'Loopbane',
      });

  String get whatToStudy => _t({
        AppLanguage.en: 'What to Study',
        AppLanguage.zu: 'Okufanele Ukufunde',
        AppLanguage.xh: 'Into Oyifundayo',
        AppLanguage.st: 'Seo o ka se Ithutang',
        AppLanguage.af: 'Wat om te Studeer',
      });

  String get whereToStudy => _t({
        AppLanguage.en: 'Where to Study',
        AppLanguage.zu: 'Lapho Ungafunda Khona',
        AppLanguage.xh: 'Apho Ungafunda Khona',
        AppLanguage.st: 'Moo o ka Ithutang Teng',
        AppLanguage.af: 'Waar om te Studeer',
      });

  String get talkToSomeone => _t({
        AppLanguage.en: 'Talk to a person',
        AppLanguage.zu: 'Khuluma nomuntu',
        AppLanguage.xh: 'Thetha nomntu',
        AppLanguage.st: 'Bua le motho',
        AppLanguage.af: 'Praat met iemand',
      });

  String get freeToUse => _t({
        AppLanguage.en: 'Free',
        AppLanguage.zu: 'Mahhala',
        AppLanguage.xh: 'Simahla',
        AppLanguage.st: 'Mahala',
        AppLanguage.af: 'Gratis',
      });

  String get offlineReady => _t({
        AppLanguage.en: 'Works offline',
        AppLanguage.zu: 'Isebenza ngaphandle kwe-inthanethi',
        AppLanguage.xh: 'Isebenza ngaphandle kwe-intanethi',
        AppLanguage.st: 'E sebetsa ntle le inthanete',
        AppLanguage.af: 'Werk sonder internet',
      });

  String get whyThisMatch => _t({
        AppLanguage.en: 'Why this match?',
        AppLanguage.zu: 'Kungani lokhu kufanele?',
        AppLanguage.xh: 'Kutheni kufanelekile?',
        AppLanguage.st: 'Hobaneng ho lumellana?',
        AppLanguage.af: 'Hoekom pas dit?',
      });
}
