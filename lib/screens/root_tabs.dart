
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../theme/sections.dart';
import 'applications_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';

class RootTabs extends StatefulWidget {
  const RootTabs({super.key});

  static RootTabsState? of(BuildContext context) =>
      context.findAncestorStateOfType<RootTabsState>();

  @override
  State<RootTabs> createState() => RootTabsState();
}

class RootTabsState extends State<RootTabs> {
  int _index = 0;
  final _navKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  void goToTab(int index) {
    if (index == _index) {
      _navKeys[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _index = index);
  }

  void _onTap(int index) {
    if (index == _index) {
      _navKeys[index].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _index = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final tabs = <_TabSpec>[
      _TabSpec(s.tabHome, CupertinoIcons.house_fill,
          const HomeScreen(), KhethaSection.today),
      _TabSpec(s.tabExplore, CupertinoIcons.compass_fill, const ExploreScreen(),
          KhethaSection.explore),
      _TabSpec(s.tabApply, CupertinoIcons.paperplane_fill,
          const ApplicationsScreen(), KhethaSection.apply),
      _TabSpec(s.tabSupport, CupertinoIcons.chat_bubble_2_fill,
          const SupportScreen(), KhethaSection.support),
      _TabSpec(s.tabSettings, CupertinoIcons.gear,
          const SettingsScreen(), KhethaSection.settings),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navKeys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          setState(() => _index = 0);
        }
      },
      child: lg.GlassScaffold(
        backgroundColor: Palette.of(context).canvas,
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < tabs.length; i++)
              KhethaSectionScope(
                section: tabs[i].section,
                child: _TabNavigator(
                    navigatorKey: _navKeys[i], child: tabs[i].screen),
              ),
          ],
        ),
        bottomBar: KhethaSectionScope(
          section: tabs[_index].section,
          child: _GlassTabBar(
            tabs: tabs,
            currentIndex: _index,
            onTap: _onTap,
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final IconData icon;
  final Widget screen;
  final KhethaSection section;
  const _TabSpec(this.label, this.icon, this.screen, this.section);
}

class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const _TabNavigator({required this.navigatorKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => CupertinoPageRoute(
        settings: settings,
        builder: (_) => child,
      ),
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  final List<_TabSpec> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassTabBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  static const _inactive = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final accent = tabs[currentIndex].section.resolve(p.brightness);

    if (!AppScope.of(context).visualEffectsEnabled) {
      return _SolidTabBar(
        tabs: tabs,
        currentIndex: currentIndex,
        onTap: onTap,
        accent: accent,
      );
    }

    return lg.GlassTabBar.bottom(
      selectedIndex: currentIndex,
      onTabSelected: onTap,
      indicatorColor: const Color(0x00000000),
      selectedIconColor: accent,
      selectedLabelColor: accent,
      unselectedIconColor: _inactive,
      unselectedLabelColor: _inactive,
      horizontalPadding: 20,
      verticalPadding: 14,
      tabs: [
        for (var i = 0; i < tabs.length; i++)
          lg.GlassTab(
            icon: Icon(tabs[i].icon),
            label: tabs[i].label,
            semanticLabel: tabs[i].label,
            glowColor: const Color(0x00000000),
          ),
      ],
    );
  }
}

class _SolidTabBar extends StatelessWidget {
  final List<_TabSpec> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color accent;

  const _SolidTabBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: p.glassStroke, width: 0.6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _TabButton(
                    spec: tabs[i],
                    selected: i == currentIndex,
                    accent: accent,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const double tabBarInset = 104;

class _TabButton extends StatelessWidget {
  final _TabSpec spec;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _TabButton({
    required this.spec,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final color = selected ? p.accent : p.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: reduceMotion ? 0 : 220),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0x00000000),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(spec.icon, size: 21, color: color),
              const SizedBox(height: 3),
              Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
