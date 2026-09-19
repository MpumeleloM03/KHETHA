import 'package:flutter/cupertino.dart';

enum KhethaSection { today, explore, apply, support, settings }

extension KhethaSectionColors on KhethaSection {
  Color get light => switch (this) {
        KhethaSection.today => const Color(0xFF1B4332),
        KhethaSection.explore => const Color(0xFFC49A1A),
        KhethaSection.apply => const Color(0xFF1967D2),
        KhethaSection.support => const Color(0xFF40916C),
        KhethaSection.settings => const Color(0xFF1A1A1A),
      };

  Color get dark => switch (this) {
        KhethaSection.today => const Color(0xFF52B788),
        KhethaSection.explore => const Color(0xFFE8C86A),
        KhethaSection.apply => const Color(0xFF6BA6FF),
        KhethaSection.support => const Color(0xFF95D5B2),
        KhethaSection.settings => const Color(0xFFE8E8E8),
      };

  Color resolve(Brightness b) => b == Brightness.dark ? dark : light;

  Color onCanvas(Brightness b) => resolve(b);
}

class KhethaSectionScope extends InheritedWidget {
  final KhethaSection section;

  const KhethaSectionScope({
    super.key,
    required this.section,
    required super.child,
  });

  static KhethaSection of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<KhethaSectionScope>()
          ?.section ??
      KhethaSection.today;

  static KhethaSection read(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<KhethaSectionScope>()
          ?.section ??
      KhethaSection.today;

  @override
  bool updateShouldNotify(KhethaSectionScope old) => old.section != section;
}
