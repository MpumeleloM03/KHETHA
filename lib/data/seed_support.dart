import '../models/career_models.dart';

/// Khetha's public career-advice channels.
///
/// The brief requires in-app access to a human career practitioner. These are
/// the channels Khetha Career Development Services publishes on NCAP. They are
/// ordered cheapest-first: a learner with R3 of airtime should see the free
/// options before the ones that cost money.
const List<AdviceChannel> adviceChannels = [
  AdviceChannel(
    id: 'ch_phone',
    name: 'Khetha Career Advice Line',
    description:
        'Speak to a qualified career practitioner. Available in all 11 official languages.',
    kind: 'phone',
    value: '0860999123',
    availability: 'Mon–Fri, 08:00–16:30',
    freeToUse: true,
  ),
  AdviceChannel(
    id: 'ch_whatsapp',
    name: 'WhatsApp a practitioner',
    description:
        'Ask a question and get a reply without using airtime. Best option on a limited budget.',
    kind: 'whatsapp',
    value: '0722045056',
    availability: 'Mon–Fri, 08:00–16:30',
    freeToUse: true,
  ),
  AdviceChannel(
    id: 'ch_sms',
    name: 'SMS "Career" for a call back',
    description:
        'Send one SMS and a practitioner calls you back. Works on any phone, no data needed.',
    kind: 'sms',
    value: '0722045056',
    availability: 'Call-back within one working day',
  ),
  AdviceChannel(
    id: 'ch_email',
    name: 'Email the career help desk',
    description:
        'For detailed questions about qualifications, funding or applications.',
    kind: 'email',
    value: 'careerhelp@dhet.gov.za',
    availability: 'Reply within 2–3 working days',
  ),
  AdviceChannel(
    id: 'ch_web',
    name: 'National Career Advice Portal',
    description:
        'The full NCAP website - the source of the career, qualification and provider information in this app.',
    kind: 'web',
    value: 'https://ncap.careerhelp.org.za',
    availability: 'Always open',
  ),
  AdviceChannel(
    id: 'ch_nsfas',
    name: 'NSFAS student funding',
    description:
        'Check whether you qualify for full government funding for university or TVET study.',
    kind: 'web',
    value: 'https://www.nsfas.org.za',
    availability: 'Applications open annually',
  ),
];

/// Career expos and open days. In the production build this list is a feed;
/// for the prototype it demonstrates the surface and the reminder flow.
const List<CareerEvent> careerEvents = [
  CareerEvent(
    id: 'ev1',
    title: 'Khetha Career Exhibition',
    host: 'DHET Khetha Career Development Services',
    location: 'Durban Exhibition Centre',
    province: 'KwaZulu-Natal',
    date: '14 March',
    description:
        'Universities, TVET colleges and SETAs under one roof. Bring your latest report and your ID.',
  ),
  CareerEvent(
    id: 'ev2',
    title: 'TVET Open Day: Artisan Pathways',
    host: 'Coastal KZN TVET College',
    location: 'Umlazi Campus',
    province: 'KwaZulu-Natal',
    date: '22 March',
    description:
        'Walk the workshops, meet qualified artisans and apply for NC(V) programmes on the day.',
  ),
  CareerEvent(
    id: 'ev3',
    title: 'NSFAS Application Clinic',
    host: 'National Student Financial Aid Scheme',
    location: 'Polokwane Community Hall',
    province: 'Limpopo',
    date: '5 April',
    description:
        'Free help completing your NSFAS application. Bring your ID and household income documents.',
  ),
  CareerEvent(
    id: 'ev4',
    title: 'Gauteng Skills & Careers Indaba',
    host: 'Gauteng Department of Education',
    location: 'Nasrec Expo Centre, Johannesburg',
    province: 'Gauteng',
    date: '18 April',
    description:
        'Employers, bursary providers and career practitioners. Free entry for learners in uniform.',
  ),
];
