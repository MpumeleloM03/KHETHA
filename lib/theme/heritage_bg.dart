import 'package:flutter/cupertino.dart';

import 'palette.dart';

class HeritageBg extends StatelessWidget {
  final Widget child;
  const HeritageBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    if (p.isDark) {
      return ColoredBox(color: p.canvas, child: child);
    }
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/sa_heritage_bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
