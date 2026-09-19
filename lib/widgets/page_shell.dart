import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../screens/root_tabs.dart';
import '../state/app_state.dart';
import '../theme/glass.dart';
import '../theme/palette.dart';

/// Standard page frame: a large iOS title that collapses into a frosted bar as
/// you scroll, over the app's ambient background. Content is bottom-padded
/// clear of the floating tab bar.
class KhethaPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> slivers;
  final Widget? trailing;

  /// Set on pushed pages so they paint their own background - the tab roots
  /// sit on the scaffold's own neutral backdrop and must stay transparent.
  final bool opaqueBackground;

  const KhethaPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.slivers,
    this.trailing,
    this.opaqueBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final effects = AppScope.of(context).visualEffectsEnabled;

    final content = CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: Text(title),
          backgroundColor:
              effects ? p.glassBar : p.surface.withValues(alpha: 0.98),
          border: Border(
            bottom: BorderSide(color: p.separator, width: 0.5),
          ),
          trailing: trailing,
          transitionBetweenRoutes: false,
        ),
        if (subtitle != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
              child: Text(subtitle!, style: KhethaText.secondary(p)),
            ),
          ),
        ...slivers,
        const SliverToBoxAdapter(child: SizedBox(height: tabBarInset)),
      ],
    );

    return CupertinoPageScaffold(
      backgroundColor: opaqueBackground ? p.canvas : const Color(0x00000000),
      child: KhethaGlassLayer(child: content),
    );
  }
}

/// Frame for a pushed detail page: back button, frosted bar, own background.
class KhethaDetailPage extends StatelessWidget {
  final String title;
  final List<Widget> slivers;
  final Widget? trailing;

  const KhethaDetailPage({
    super.key,
    required this.title,
    required this.slivers,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final effects = AppScope.of(context).visualEffectsEnabled;

    return CupertinoPageScaffold(
      backgroundColor: p.canvas,
      child: KhethaGlassLayer(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(title),
              backgroundColor:
                  effects ? p.glassBar : p.surface.withValues(alpha: 0.98),
              border: Border(
                bottom: BorderSide(color: p.separator, width: 0.5),
              ),
              trailing: trailing,
              previousPageTitle: 'Back',
            ),
            ...slivers,
            const SliverToBoxAdapter(child: SizedBox(height: tabBarInset)),
          ],
        ),
      ),
    );
  }
}


/// Presents a full-screen tool (a questionnaire, the Subject Chooser) over the
/// tab bar rather than inside a tab.
///
/// These are self-contained tasks with their own primary action at the bottom
/// of the screen, so they need the whole screen - leaving them inside the tab
/// stack puts the floating tab bar on top of their action button.
Future<T?> pushTool<T>(BuildContext context, Widget screen) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    CupertinoPageRoute(builder: (_) => screen, fullscreenDialog: true),
  );
}

/// Convenience: wraps a list of widgets in horizontal page padding as a sliver.
class SliverSection extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const SliverSection({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 0),
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildListDelegate(children),
      ),
    );
  }
}

/// A sheet presented from the bottom, frosted to match the rest of the app.
/// Closes the sheet opened by [showKhethaSheet], returning [result].
///
/// Sheets are presented on the ROOT navigator so they cover the floating tab
/// bar. Code inside a sheet almost always closes over the screen's context
/// rather than the sheet's, and a plain `Navigator.of(context).pop()` from
/// there targets the tab's navigator instead - popping the tab's only route and
/// crashing on `_history.isNotEmpty`. Going through this function makes the
/// right navigator the default rather than something each call site has to
/// remember.
void closeSheet<T>(BuildContext context, [T? result]) {
  Navigator.of(context, rootNavigator: true).pop<T?>(result);
}

Future<T?> showKhethaSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  final p = Palette.of(context);
  final effects = AppScope.read(context).visualEffectsEnabled;

  return showCupertinoModalPopup<T>(
    context: context,
    useRootNavigator: true,
    builder: (context) {
      Widget panel = Container(
        decoration: BoxDecoration(
          color: effects ? p.glassBar : p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: p.glassStroke, width: 0.6),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: p.textTertiary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: KhethaText.title(p)),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      onPressed: () => closeSheet(context),
                      child: Icon(CupertinoIcons.xmark_circle_fill,
                          size: 26, color: p.textTertiary),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );

      if (effects) {
        panel = ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: panel,
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.12,
        ),
        child: Align(alignment: Alignment.bottomCenter, child: panel),
      );
    },
  );
}
