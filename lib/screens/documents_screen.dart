import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../models/application_models.dart';
import '../services/document_verifier.dart';
import '../services/id_validator.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';
import '../widgets/page_shell.dart';

/// The document pack every application draws on.
///
/// Collected once and reused for every institution, which is the whole point:
/// the reason learners apply to one place instead of five is the paperwork, not
/// the ambition.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  DocumentKind? _busyWith;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final missing = app.missingRequiredDocuments;

    return KhethaDetailPage(
      title: 'Your documents',
      slivers: [
        SliverSection(children: [
          GlassCard(
            tint: missing.isEmpty ? p.accent : p.warm,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  missing.isEmpty
                      ? CupertinoIcons.checkmark_seal_fill
                      : CupertinoIcons.doc_on_doc_fill,
                  size: 20,
                  color: missing.isEmpty ? p.accent : p.warm,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        missing.isEmpty
                            ? 'Your pack is complete'
                            : '${missing.length} still needed',
                        style: KhethaText.headline(p),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        missing.isEmpty
                            ? 'Collected once, used for every institution you apply to.'
                            : 'Add these once and every application can use them.',
                        style: KhethaText.caption(p),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text('Your ID number', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 8),
          const _IdNumberCard(),
          const SizedBox(height: 22),

          Text('Documents', style: KhethaText.sectionLabel(p)),
          const SizedBox(height: 8),
          for (final kind in DocumentKind.values) ...[
            _DocumentCard(
              kind: kind,
              document: _documentFor(app, kind),
              busy: _busyWith == kind,
              onAdd: () => _capture(kind),
              onRemove: () => app.removeDocument(kind),
            ),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 12),
          GlassCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.lock_shield_fill, size: 17, color: p.accent),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What checking means here',
                          style: KhethaText.headline(p)),
                      const SizedBox(height: 6),
                      Text(
                        'Khetha Go reads each document on your phone to check it is legible and that the details match what you entered. It cannot confirm a document is genuine - only Home Affairs, Umalusi and the institution can do that. Your documents are never uploaded anywhere by this app.',
                        style: KhethaText.caption(p),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  ApplicationDocument? _documentFor(AppState app, DocumentKind kind) {
    for (final d in app.documents) {
      if (d.kind == kind) return d;
    }
    return null;
  }

  Future<void> _capture(DocumentKind kind) async {
    final app = AppScope.read(context);

    final source = await showKhethaSheet<String>(
      context,
      title: kind.label,
      child: GlassSection(
        footer: kind.why,
        children: [
          GlassRow(
            icon: CupertinoIcons.camera_fill,
            title: 'Take a photo',
            subtitle: 'Lay the page flat in good light.',
            showChevron: true,
            onTap: () => closeSheet(context, 'camera'),
          ),
          GlassRow(
            icon: CupertinoIcons.photo_fill,
            title: 'Choose a photo',
            showChevron: true,
            onTap: () => closeSheet(context, 'gallery'),
          ),
          GlassRow(
            icon: CupertinoIcons.doc_fill,
            title: 'Choose a PDF',
            showChevron: true,
            onTap: () => closeSheet(context, 'pdf'),
          ),
        ],
      ),
    );

    if (source == null || !mounted) return;
    setState(() => _busyWith = kind);

    try {
      String? path;
      if (source == 'pdf') {
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        path = picked?.files.single.path;
      } else {
        final file = await ImagePicker().pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 92,
        );
        path = file?.path;
      }

      if (path == null) {
        if (mounted) setState(() => _busyWith = null);
        return;
      }

      final document = await DocumentVerifier.instance.check(
        kind: kind,
        path: path,
        expectedIdNumber: app.idNumber,
        expectedName: app.profile.displayName,
      );

      await app.addDocument(document);
      if (mounted) setState(() => _busyWith = null);
    } catch (_) {
      if (mounted) setState(() => _busyWith = null);
    }
  }
}

class _IdNumberCard extends StatefulWidget {
  const _IdNumberCard();

  @override
  State<_IdNumberCard> createState() => _IdNumberCardState();
}

class _IdNumberCardState extends State<_IdNumberCard> {
  late final TextEditingController _controller =
      TextEditingController(text: AppScope.read(context).idNumber ?? '');
  SaIdNumber? _parsed;

  @override
  void initState() {
    super.initState();
    if (_controller.text.isNotEmpty) {
      _parsed = SaIdNumber.parse(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final app = AppScope.of(context);
    final parsed = _parsed;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoTextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            placeholder: '13 digits',
            maxLength: 13,
            style: KhethaText.body(p).copyWith(
              fontSize: 19,
              letterSpacing: 1.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: p.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: parsed == null
                    ? p.glassStroke
                    : (parsed.isValid ? p.accent : p.danger),
                width: parsed == null ? 0.6 : 1.2,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _parsed = value.replaceAll(RegExp(r'\D'), '').length >= 6
                    ? SaIdNumber.parse(value)
                    : null;
              });
              if (_parsed?.isValid ?? false) app.setIdNumber(value);
            },
          ),
          const SizedBox(height: 12),

          if (parsed == null)
            Text(
              'Institutions match every document against this number, so a single wrong digit stops an application.',
              style: KhethaText.caption(p),
            )
          else if (parsed.isValid)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.checkmark_seal_fill, size: 16, color: p.accent),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Checks out. Born ${_formatDate(parsed.dateOfBirth)}'
                    '${parsed.age == null ? '' : ', age ${parsed.age}'}.'
                    '${parsed.isCitizen == false ? ' Recorded as a permanent resident.' : ''}',
                    style: KhethaText.caption(p),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final problem in parsed.problems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(CupertinoIcons.exclamationmark_circle_fill,
                            size: 15, color: p.danger),
                        const SizedBox(width: 9),
                        Expanded(
                            child: Text(problem, style: KhethaText.caption(p))),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'unknown';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentKind kind;
  final ApplicationDocument? document;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _DocumentCard({
    required this.kind,
    required this.document,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final doc = document;

    final (icon, color) = doc == null
        ? (
            kind.required
                ? CupertinoIcons.exclamationmark_circle
                : CupertinoIcons.circle,
            kind.required ? p.warm : p.textTertiary,
          )
        : doc.passedChecks
            ? (CupertinoIcons.checkmark_seal_fill, p.accent)
            : (CupertinoIcons.exclamationmark_triangle_fill, p.danger);

    return GlassCard(
      padding: const EdgeInsets.all(15),
      onTap: busy ? null : onAdd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: CupertinoActivityIndicator(radius: 9),
                )
              else
                Icon(icon, size: 19, color: color),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(kind.label,
                              style: KhethaText.headline(p)),
                        ),
                        if (!kind.required) ...[
                          const SizedBox(width: 7),
                          Chip('Optional', color: p.textTertiary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      busy
                          ? 'Checking…'
                          : doc == null
                              ? kind.why
                              : doc.fileName,
                      style: KhethaText.caption(p),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (doc != null && !busy)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  onPressed: onRemove,
                  child: Icon(CupertinoIcons.minus_circle,
                      size: 19, color: p.textTertiary),
                ),
            ],
          ),
          if (doc != null && doc.issues.isNotEmpty) ...[
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: p.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final issue in doc.issues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(issue, style: KhethaText.caption(p)),
                    ),
                  const SizedBox(height: 4),
                  Text('Tap to replace it.',
                      style: KhethaText.caption(p)
                          .copyWith(color: p.danger, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
