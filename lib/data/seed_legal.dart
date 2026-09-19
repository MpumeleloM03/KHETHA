/// Legal text shown in the app.
///
/// Written to be read by a fifteen-year-old and their parent, not by a lawyer.
/// Each section says what actually happens in the code - the privacy notice is
/// checkable against the app's behaviour, which is the point of it.
library;

class LegalSection {
  final String heading;
  final String body;
  const LegalSection(this.heading, this.body);
}

const String privacyUpdated = 'Last updated 17 September 2026';

const List<LegalSection> privacyPolicy = [
  LegalSection(
    'The short version',
    'Khetha Go keeps everything you enter on your own phone. There is no account, no server, and nothing is uploaded. If you delete the app, the data goes with it. You can read or erase everything from Settings at any time.',
  ),
  LegalSection(
    'What we collect',
    'Only what you give us: your first name if you enter it, your grade and province, your questionnaire answers, the subjects you choose, your results if you scan or type them, and any documents you add to an application. We do not collect your location, your contacts, your browsing, or anything about how you use the app.',
  ),
  LegalSection(
    'Where it is stored',
    'In this app’s private storage on this device. Other apps cannot read it. It is not backed up to us, because there is no "us" to back it up to - Khetha Go has no backend.',
  ),
  LegalSection(
    'Your results and documents',
    'When you scan a results statement, the image is read on the device by the operating system’s own text recogniser. The photograph is not uploaded and is not kept after the text has been read. The same applies to the documents you add to an application.',
  ),
  LegalSection(
    'Consent',
    'Three separate permissions, each off until you turn it on: keeping your progress, personalising your guidance, and sending reminders. Turning one off deletes what it was keeping, immediately and on the device. You can use the app with all three off.',
  ),
  LegalSection(
    'How recommendations are made',
    'Career matches are calculated on your phone by a weighted model whose workings are shown in full under Settings, How matching works. No automated decision in this app determines anything about your education. Every recommendation is advisory, and the app points you to a human career practitioner on every screen that gives one.',
  ),
  LegalSection(
    'Applications',
    'When you build an application, the documents and details stay on your device until you choose to submit. In this prototype build, submission is demonstrated rather than transmitted to institutions.',
  ),
  LegalSection(
    'Your rights under POPIA',
    'The Protection of Personal Information Act gives you the right to know what is held about you, to correct it, and to have it deleted. Settings has a screen that shows you the complete record in readable form, and a delete button that erases all of it. Because nothing leaves your device, there is no copy anywhere else to request.',
  ),
  LegalSection(
    'Children',
    'This app is built for learners, including those under 18. It collects the minimum needed to give guidance, asks for consent in plain language before keeping anything, and never shares data with anyone, including schools and the Department.',
  ),
  LegalSection(
    'Contact',
    'Questions about your information can go to the Khetha career advice line or to careerhelp@dhet.gov.za.',
  ),
];

const List<LegalSection> termsAndConditions = [
  LegalSection(
    'What this app is',
    'Khetha Go is a career guidance tool built on content from the National Career Advice Portal. It helps you explore careers, check what you qualify for, and prepare applications. It is a guide, not an authority.',
  ),
  LegalSection(
    'What it is not',
    'Khetha Go does not decide whether you are admitted anywhere, does not speak for any institution, and does not guarantee a place, a bursary or a job. Only an institution can admit you, and only your final NSC results decide what you qualify for.',
  ),
  LegalSection(
    'Accuracy of information',
    'Entry requirements, APS thresholds, salary ranges and course details change every year and differ between institutions. The figures in this app are national estimates for guidance. Always confirm with the institution before you rely on anything here, and verify a qualification against its SAQA ID before paying any fee.',
  ),
  LegalSection(
    'This is a prototype',
    'This build was made for the SITA GovTech Hackathon 2026. The content set is illustrative and is not a live extract from Department systems. Application submission is demonstrated, not transmitted.',
  ),
  LegalSection(
    'Your responsibilities',
    'Give accurate information. Results, ID numbers and documents you enter must be your own and must be true. Submitting false information to an institution is fraud, and the consequences fall on you, not on this app.',
  ),
  LegalSection(
    'Recommendations',
    'Career and course recommendations come from your own answers and results, scored by a model described in full under Settings. They are a starting point for a conversation with a career practitioner. Decisions about your education remain yours.',
  ),
  LegalSection(
    'Third parties',
    'Tutor listings, institutions and events shown in the app are informational. Khetha Go does not employ, vet, endorse or take responsibility for any third party, and any arrangement you make with one is between you and them.',
  ),
  LegalSection(
    'Cost',
    'Khetha Go is free. Institutions may charge their own application fees, and connecting to the internet may cost you data. The app is built to work offline so that it costs you as little as possible.',
  ),
  LegalSection(
    'Changes',
    'These terms may change as the app develops. Material changes will be shown in the app before they take effect.',
  ),
];
