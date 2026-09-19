import '../models/funding_models.dart';

const seedBursaries = <Bursary>[
  Bursary(
    id: 'b_funza',
    name: 'Funza Lushaka Bursary',
    provider: 'Department of Basic Education',
    description:
        'Full-cost bursary for students who want to become teachers in priority subjects like Maths, Science and Technology.',
    category: BursaryCategory.government,
    fieldsOfStudy: ['Education'],
    closingDate: '31 January 2027',
    coverageDescription: 'Tuition, accommodation, meals, books and a living allowance.',
    minAps: '26',
    requirements: [
      'South African citizen',
      'Accepted at a public university for a teaching qualification',
      'Financial need',
      'Commitment to teach for the same number of years funded',
    ],
  ),
  Bursary(
    id: 'b_sasol',
    name: 'Sasol Bursary Programme',
    provider: 'Sasol Limited',
    description:
        'Covers full tuition for students in engineering, science and IT at selected universities.',
    category: BursaryCategory.corporate,
    fieldsOfStudy: ['Engineering & Technology', 'Physical Sciences'],
    closingDate: '31 March 2027',
    coverageDescription: 'Tuition, accommodation, textbooks and a stipend.',
    minAps: '32',
    maxHouseholdIncome: 'R600 000 per annum',
    requirements: [
      'South African citizen',
      'Studying or accepted for engineering, science or IT',
      'Strong academic record',
    ],
  ),
  Bursary(
    id: 'b_eskom',
    name: 'Eskom Bursary Scheme',
    provider: 'Eskom Holdings',
    description:
        'Full bursary for students studying towards careers in the energy sector.',
    category: BursaryCategory.corporate,
    fieldsOfStudy: ['Engineering & Technology'],
    closingDate: '30 September 2026',
    coverageDescription: 'Tuition, accommodation, meals, travel and books.',
    minAps: '30',
    requirements: [
      'South African citizen',
      'Registered at a South African university',
      'Studying electrical, mechanical, civil or chemical engineering',
    ],
  ),
  Bursary(
    id: 'b_nrf',
    name: 'NRF Postgraduate Bursary',
    provider: 'National Research Foundation',
    description:
        'Supports honours, masters and doctoral students in all fields of study at South African universities.',
    category: BursaryCategory.government,
    fieldsOfStudy: ['All fields'],
    closingDate: '15 February 2027',
    coverageDescription: 'Living allowance and research costs.',
    requirements: [
      'South African citizen or permanent resident',
      'Registered for postgraduate study',
      'Satisfactory academic record',
    ],
  ),
  Bursary(
    id: 'b_allan_gray',
    name: 'Allan Gray Orbis Foundation Fellowship',
    provider: 'Allan Gray Orbis Foundation',
    description:
        'Full scholarship for high-potential students with entrepreneurial ambition at select universities.',
    category: BursaryCategory.merit,
    fieldsOfStudy: ['Commerce', 'Engineering & Technology', 'Science'],
    closingDate: '1 March 2027',
    coverageDescription: 'Full tuition, accommodation, meals, books and mentorship.',
    minAps: '35',
    requirements: [
      'South African citizen',
      'Top academic achiever',
      'Demonstrated leadership and entrepreneurial potential',
      'Accepted at a partner university',
    ],
  ),
  Bursary(
    id: 'b_dhet',
    name: 'DHET Teacher Bursary',
    provider: 'Department of Higher Education & Training',
    description:
        'For students enrolled in initial teacher education programmes at public universities.',
    category: BursaryCategory.government,
    fieldsOfStudy: ['Education'],
    closingDate: '28 February 2027',
    coverageDescription: 'Tuition, accommodation and living allowance.',
    requirements: [
      'South African citizen',
      'Enrolled in a BEd or PGCE',
      'Financial need',
    ],
  ),
  Bursary(
    id: 'b_absa',
    name: 'Absa Fellowship Programme',
    provider: 'Absa Group',
    description:
        'Comprehensive bursary for students pursuing studies in commerce, finance, IT and actuarial science.',
    category: BursaryCategory.corporate,
    fieldsOfStudy: ['Commerce', 'Information Technology'],
    closingDate: '31 August 2026',
    coverageDescription: 'Tuition, accommodation, books and vacation employment.',
    minAps: '30',
    maxHouseholdIncome: 'R500 000 per annum',
    requirements: [
      'South African citizen',
      'Strong academic results',
      'Studying commerce, finance, IT or actuarial science',
    ],
  ),
  Bursary(
    id: 'b_anglo',
    name: 'Anglo American Bursary',
    provider: 'Anglo American',
    description:
        'Full bursary for mining engineering, geology, metallurgy and related fields.',
    category: BursaryCategory.corporate,
    fieldsOfStudy: ['Engineering & Technology', 'Physical Sciences'],
    closingDate: '31 March 2027',
    coverageDescription: 'Tuition, accommodation, textbooks and a monthly allowance.',
    minAps: '30',
    requirements: [
      'South African citizen',
      'Accepted for mining, geology, metallurgy or related engineering',
      'Academic merit and financial need',
    ],
  ),
  Bursary(
    id: 'b_health_bursary',
    name: 'Provincial Health Bursary',
    provider: 'Provincial Departments of Health',
    description:
        'For students studying medicine, nursing, pharmacy, and other health sciences. Requires community service on completion.',
    category: BursaryCategory.government,
    fieldsOfStudy: ['Health Sciences'],
    closingDate: '30 November 2026',
    coverageDescription: 'Tuition, accommodation, meals and books.',
    requirements: [
      'South African citizen',
      'Accepted for a health sciences programme',
      'Financial need',
      'Commitment to community service in the province',
    ],
  ),
  Bursary(
    id: 'b_investec',
    name: 'Investec Bursary',
    provider: 'Investec',
    description:
        'For students studying actuarial science, data science, finance or CA(SA) programmes.',
    category: BursaryCategory.corporate,
    fieldsOfStudy: ['Commerce', 'Information Technology'],
    closingDate: '30 April 2027',
    coverageDescription: 'Tuition, accommodation and mentorship.',
    minAps: '35',
    requirements: [
      'South African citizen',
      'Studying actuarial science, data science, finance or CA(SA)',
      'Exceptional academic record',
    ],
  ),
];

Bursary? bursaryById(String id) {
  for (final b in seedBursaries) {
    if (b.id == id) return b;
  }
  return null;
}
