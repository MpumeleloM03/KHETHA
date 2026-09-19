import 'package:flutter/cupertino.dart';

import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/listen_button.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String _query = '';
  int? _expandedIndex;
  static const _faqs = <_Faq>[
    _Faq(
      q: 'What is Khetha Go?',
      a: 'Khetha Go is the Department of Higher Education and Training\'s '
          'career guidance app. It helps you explore careers, find matching '
          'qualifications, and apply to universities, all from your phone.',
      category: 'About',
    ),
    _Faq(
      q: 'How do I calculate my APS score?',
      a: 'Go to your Profile and tap "Add Your Results". You can type in your '
          'marks or scan your results statement. The app converts your '
          'percentages to the APS scale automatically.',
      category: 'Results',
    ),
    _Faq(
      q: 'What careers match my profile?',
      a: 'Take the Job Fit Quiz on the Home tab. It uses the Holland (RIASEC) '
          'model to match your interests and personality to career clusters. '
          'Your top matches appear on your Profile dashboard.',
      category: 'Careers',
    ),
    _Faq(
      q: 'How do I apply to a university?',
      a: 'Go to the Apply tab, search for programmes you qualify for, and tap '
          '"Apply". The app guides you through the required documents and '
          'tracks your application status.',
      category: 'Applications',
    ),
    _Faq(
      q: 'How do I apply for NSFAS funding?',
      a: 'Open the Support tab and tap "NSFAS". You\'ll see eligibility '
          'requirements, application deadlines, and a direct link to the '
          'NSFAS portal. The app also tracks your NSFAS application status.',
      category: 'Funding',
    ),
    _Faq(
      q: 'Does the app work without internet?',
      a: 'Yes. All career data, qualifications, and university information is '
          'stored on your phone. You only need internet to submit applications '
          'or load remote images.',
      category: 'About',
    ),
    _Faq(
      q: 'Is my data private?',
      a: 'Your data stays on your device. There is no account, no server, and '
          'no analytics. You can delete all data from Settings at any time.',
      category: 'Privacy',
    ),
    _Faq(
      q: 'What is a Holland code?',
      a: 'The Holland code (RIASEC) groups interests into six types: '
          'Realistic, Investigative, Artistic, Social, Enterprising, and '
          'Conventional. Your top three types form your code, which helps '
          'match you to careers.',
      category: 'Careers',
    ),
    _Faq(
      q: 'How do I change my PIN?',
      a: 'Go to Settings > Security. You can remove your current PIN and set '
          'a new one. If you have biometric login enabled, you\'ll need to '
          're-enable it after changing your PIN.',
      category: 'Security',
    ),
    _Faq(
      q: 'What documents do I need to apply?',
      a: 'Most universities require your ID, matric results, and proof of '
          'residence. Some programmes need additional documents like a '
          'portfolio or medical certificate. The app tells you exactly what '
          'each programme needs.',
      category: 'Applications',
    ),
    _Faq(
      q: 'Can I use this app if I\'m in Grade 9?',
      a: 'Yes. The app helps Grade 9 learners choose subjects by showing '
          'which careers each subject combination opens up. Go to Explore > '
          'Subject Chooser to start.',
      category: 'About',
    ),
    _Faq(
      q: 'What bursaries are available?',
      a: 'The app lists bursaries from government departments, private '
          'companies, and NGOs. Filter by your field of study and province '
          'on the Support tab.',
      category: 'Funding',
    ),
  ];

  List<_Faq> get _filtered {
    if (_query.isEmpty) return _faqs;
    final q = _query.toLowerCase();
    return _faqs
        .where((f) =>
            f.q.toLowerCase().contains(q) ||
            f.a.toLowerCase().contains(q) ||
            f.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final items = _filtered;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Help & FAQ'),
        backgroundColor: p.surface.withValues(alpha: 0.96),
        border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
      ),
      child: SafeArea(child: _buildFaqList(p, items)),
    );
  }

  Widget _buildFaqList(Palette p, List<_Faq> items) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Semantics(
            label: 'Search frequently asked questions',
            textField: true,
            child: CupertinoSearchTextField(
              placeholder: 'Search FAQ...',
              backgroundColor: p.cardSurface,
              style: TextStyle(fontSize: 16, color: p.textPrimary),
              itemColor: p.textTertiary,
              onChanged: (v) => setState(() {
                _query = v;
                _expandedIndex = null;
              }),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.search, size: 40, color: p.textTertiary),
                        const SizedBox(height: 12),
                        Text('No matching questions',
                            style: TextStyle(fontSize: 16, color: p.textSecondary)),
                        const SizedBox(height: 6),
                        Text(
                          'Try different words, or browse the full list.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: p.textTertiary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final faq = items[i];
                    final expanded = _expandedIndex == i;
                    return Semantics(
                      button: true,
                      label: '${faq.category}: ${faq.q}',
                      hint: expanded ? 'Collapse' : 'Tap to expand',
                      child: GestureDetector(
                        onTap: () => setState(() => _expandedIndex = expanded ? null : i),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: p.accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(faq.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: p.accent,
                                        )),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                                    size: 14,
                                    color: p.textTertiary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(faq.q,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: p.textPrimary,
                                    height: 1.3,
                                  )),
                              if (expanded) ...[
                                const SizedBox(height: 10),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(faq.a,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: p.textSecondary,
                                        height: 1.5,
                                      )),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ListenButton(
                                    id: 'faq-${faq.q}',
                                    text: '${faq.q}. ${faq.a}',
                                    label: 'this answer',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Faq {
  final String q;
  final String a;
  final String category;
  const _Faq({required this.q, required this.a, required this.category});
}
