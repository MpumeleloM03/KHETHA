import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/ncap_repository.dart';
import 'screens/auth_screen.dart';
import 'screens/login_screen.dart';
import 'screens/root_tabs.dart';
import 'screens/welcome_screen.dart';
import 'theme/heritage_bg.dart';
import 'services/notification_service.dart';
import 'services/speech_service.dart';
import 'services/supabase_service.dart';
import 'state/app_state.dart';
import 'theme/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseService.isConfigured) {
    await SupabaseService.init();
    await Ncap.load(const SupabaseDataSource());
  } else {
    await Ncap.load(const LocalSeedSource());
  }

  // Compiles and pre-warms the glass shaders before the first frame. Without
  // this the first screen renders a frame of unblurred placeholder while the
  // fragment programs load off disk.
  await LiquidGlassWidgets.initialize();

  final prefs = await SharedPreferences.getInstance();
  await NotificationService.instance.init();
  await SpeechService.instance.init(prefs);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(KhethaGo(state: AppState(prefs)));
}

class KhethaGo extends StatelessWidget {
  final AppState state;
  const KhethaGo({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) => LiquidGlassWidgets.wrap(
          // Supplies app-wide glass defaults and lets the accessibility scope
          // swap the shader for a solid surface when the OS asks for Reduce
          // Transparency. `brightnessResolver` is a Material bridge and is
          // deliberately omitted - this is a Cupertino app.
          theme: _glassTheme,
          child: const _KhethaAppRoot(),
        ),
      ),
    );
  }
}

/// App-wide glass defaults. Per-screen settings are layered on top of these by
/// [KhethaGlassLayer]; the values here are what a bare glass widget gets.
const _glassTheme = GlassThemeData(
  light: GlassThemeVariant(
    settings: GlassThemeSettings(
      thickness: 12,
      blur: 6,
      glassColor: Color.fromRGBO(255, 255, 255, 0.55),
      lightIntensity: 0.85,
      ambientStrength: 0.15,
      saturation: 1.15,
      edgeAbsorption: 0.08,
    ),
  ),
  dark: GlassThemeVariant(
    settings: GlassThemeSettings(
      thickness: 10,
      blur: 5,
      glassColor: Color.fromRGBO(255, 255, 255, 0.07),
      lightIntensity: 0.7,
      ambientStrength: 0.0,
      saturation: 1.15,
      edgeAbsorption: 0.12,
    ),
  ),
);

class _KhethaAppRoot extends StatelessWidget {
  const _KhethaAppRoot();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final systemBrightness =
        MediaQuery.maybeOf(context)?.platformBrightness ?? Brightness.light;
    final brightness = app.forcedBrightness ?? systemBrightness;
    final palette = Palette.forBrightness(brightness);

    final authKey = '${app.isSupabaseAuthenticated}_${app.hasSeenWelcome}_${app.isAuthenticated}';
    return CupertinoApp(
      key: ValueKey(authKey),
      title: 'Khetha Go',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: palette.accent,
        scaffoldBackgroundColor: palette.isDark ? palette.canvas : const Color(0x00000000),
        barBackgroundColor: palette.glassBar,
        textTheme: CupertinoTextThemeData(
          primaryColor: palette.accent,
          textStyle: KhethaText.body(palette),
          navTitleTextStyle: KhethaText.headline(palette),
          navLargeTitleTextStyle: KhethaText.largeTitle(palette),
        ),
      ),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          // Compose the in-app text-size preference on top of whatever the
          // system Dynamic Type setting already is, rather than replacing it.
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.6,
            ),
          ),
          child: _TextScaleWrapper(scale: app.textScale, child: child!),
        );
      },
      home: HeritageBg(
        child: !app.isSupabaseAuthenticated
            ? const AuthScreen()
            : !app.hasSeenWelcome
                ? const WelcomeScreen()
                : !app.isAuthenticated
                    ? const LoginScreen()
                    : const RootTabs(),
      ),
    );
  }
}

class _TextScaleWrapper extends StatelessWidget {
  final double scale;
  final Widget child;
  const _TextScaleWrapper({required this.scale, required this.child});

  @override
  Widget build(BuildContext context) {
    if (scale == 1.0) return child;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(
          media.textScaler.scale(1.0) * scale,
        ),
      ),
      child: child,
    );
  }
}
