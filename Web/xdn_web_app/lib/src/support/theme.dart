import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF386A20);

// Custom MaterialColor M1/M2 style Color Swatch based on primaryColor.
const MaterialColor mySwatch = MaterialColor(
  0xFF386A20,
  <int, Color>{
    50: Color(0xFFC3D2BB),
    100: Color(0xFFB4C7AA),
    200: Color(0xFF9AB48D),
    400: Color(0xFF598E3F),
    500: Color(0xFF386A20),
    600: Color(0xFF325F1D),
    700: Color(0xFF294D18),
    800: Color(0xFF213E12),
    900: Color(0xFF1A300E),
  },
);

// Light M3 ColorScheme.
const ColorScheme mySchemeLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xff386a20),
  onPrimary: Color(0xffffffff),
  primaryContainer: Color(0xffc0f0a4),
  onPrimaryContainer: Color(0xff042100),
  secondary: Color(0xff55624c),
  onSecondary: Color(0xffffffff),
  secondaryContainer: Color(0xffd9e7cb),
  onSecondaryContainer: Color(0xff131f0d),
  tertiary: Color(0xff386667),
  onTertiary: Color(0xffffffff),
  tertiaryContainer: Color(0xffbbebeb),
  onTertiaryContainer: Color(0xff002021),
  error: Color(0xffba1b1b),
  onError: Color(0xffffffff),
  errorContainer: Color(0xffffdad4),
  onErrorContainer: Color(0xff410001),
  outline: Color(0xff74796e),
  background: Color(0xfffdfdf6),
  onBackground: Color(0xff1a1c18),
  surface: Color(0xfffdfdf6),
  onSurface: Color(0xff1a1c18),
  surfaceVariant: Color(0xffdfe4d6),
  onSurfaceVariant: Color(0xff43493e),
  inverseSurface: Color(0xff2f312c),
  onInverseSurface: Color(0xfff1f1ea),
  inversePrimary: Color(0xff9cd67d),
  shadow: Color(0xff000000),
  surfaceTint: Color(0xff386a20),
);

// Dark M3 ColorScheme.
const ColorScheme mySchemeDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xff9cd67d),
  onPrimary: Color(0xff0c3900),
  primaryContainer: Color(0xff205107),
  onPrimaryContainer: Color(0xffc0f0a4),
  secondary: Color(0xffbdcbb0),
  onSecondary: Color(0xff273420),
  secondaryContainer: Color(0xff3e4a36),
  onSecondaryContainer: Color(0xffd9e7cb),
  tertiary: Color(0xffa0cfcf),
  onTertiary: Color(0xff003738),
  tertiaryContainer: Color(0xff1e4e4e),
  onTertiaryContainer: Color(0xffbbebeb),
  error: Color(0xffffb4a9),
  onError: Color(0xff680003),
  errorContainer: Color(0xff930006),
  onErrorContainer: Color(0xffffb4a9),
  outline: Color(0xff8d9286),
  background: Color(0xff1a1c18),
  onBackground: Color(0xffe3e3dc),
  surface: Color(0xff1a1c18),
  onSurface: Color(0xffe3e3dc),
  surfaceVariant: Color(0xff43493e),
  onSurfaceVariant: Color(0xffc4c8bb),
  inverseSurface: Color(0xffe3e3dc),
  onInverseSurface: Color(0xff2f312c),
  inversePrimary: Color(0xff386a20),
  shadow: Color(0xff000000),
  surfaceTint: Color(0xff9cd67d),
);

enum ThemingWay {
  road1('1: ThemeData.light/dark'),
  road2('2: ThemeData(primarySwatch: swatch)'),
  road3('3: ThemeData(colorScheme: ColorScheme.fromSwatch))'),
  road4('4: ThemeData.from(colorScheme: ColorScheme.fromSwatch))'),
  road5('5: ThemeData(colorScheme: scheme)'),
  road6('6: ThemeData.from(colorScheme: scheme)'),
  road7('7: ThemeData(colorSchemeSeed: color)'),
  road8('8: ThemeData(colorScheme: ColorScheme.fromSeed(color))'),
  road9('9: ThemeData.from(colorScheme: ColorScheme.fromSeed(color))'),
  road10('10: ThemeData(colorScheme: and other props)');

  final String describe;
  const ThemingWay(this.describe);

  ThemeData theme(Brightness mode, bool useMaterial3) {
    switch (this) {
      case ThemingWay.road1:
        return themeOne(mode, useMaterial3);
      case ThemingWay.road2:
        return themeTwo(mode, useMaterial3);
      case ThemingWay.road3:
        return themeThree(mode, useMaterial3);
      case ThemingWay.road4:
        return themeFour(mode, useMaterial3);
      case ThemingWay.road5:
        return themeFive(mode, useMaterial3);
      case ThemingWay.road6:
        return themeSix(mode, useMaterial3);
      case ThemingWay.road7:
        return themeSeven(mode, useMaterial3);
      case ThemingWay.road8:
        return themeEight(mode, useMaterial3);
      case ThemingWay.road9:
        return themeNine(mode, useMaterial3);
      case ThemingWay.road10:
        return themeTen(mode, useMaterial3);
    }
  }
}

// 1) TD.light/dark
//    ThemeData(brightness: Brightness.light)
//    ThemeData(brightness: Brightness.dark)
ThemeData themeOne(Brightness mode, bool useMaterial3) => ThemeData(
  brightness: mode,
  useMaterial3: useMaterial3,
  visualDensity: VisualDensity.standard,
);

// 2) TD primarySwatch
//    ThemeData(brightness: ..., primarySwatch: swatch)
ThemeData themeTwo(Brightness mode, bool useMaterial3) => ThemeData(
  brightness: mode,
  primarySwatch: mySwatch,
  useMaterial3: useMaterial3,
  visualDensity: VisualDensity.standard,
);

// 3) TD scheme.fromSwatch
//    ThemeData(colorScheme: ColorScheme.fromSwatch(swatch))
ThemeData themeThree(Brightness mode, bool useMaterial3) => ThemeData(
  colorScheme: ColorScheme.fromSwatch(
    brightness: mode,
    primarySwatch: mySwatch,
  ),
  useMaterial3: useMaterial3,
  visualDensity: VisualDensity.standard,
);

// 4) TD.from scheme.fromSwatch
//    ThemeData.from(colorScheme: ColorScheme.fromSwatch(swatch))
ThemeData themeFour(Brightness mode, bool useMaterial3) => ThemeData.from(
  colorScheme: ColorScheme.fromSwatch(
    brightness: mode,
    primarySwatch: mySwatch,
  ),
  useMaterial3: useMaterial3,
).copyWith(visualDensity: VisualDensity.standard);

// 5) TD colorScheme
//    ThemeData(colorScheme: ColorScheme(...))
ThemeData themeFive(Brightness mode, bool useMaterial3) => ThemeData(
  colorScheme: mode == Brightness.light ? mySchemeLight : mySchemeDark,
  useMaterial3: useMaterial3,
  visualDensity: VisualDensity.standard,
);

// 6) TD.from colorScheme
//    ThemeData.from(colorScheme: ColorScheme(...))
ThemeData themeSix(Brightness mode, bool useMaterial3) => ThemeData.from(
  colorScheme: mode == Brightness.light ? mySchemeLight : mySchemeDark,
  useMaterial3: useMaterial3,
).copyWith(visualDensity: VisualDensity.standard);

// 7) TD colorSchemeSeed
//    ThemeData(colorSchemeSeed: Color(...))
ThemeData themeSeven(Brightness mode, bool useMaterial3) => ThemeData(
  brightness: mode,
  colorSchemeSeed: primaryColor,
  useMaterial3: useMaterial3,
  visualDensity: VisualDensity.standard,
);

// 8) TD scheme.fromSeed
//    ThemeData(colorScheme: ColorScheme.fromSeed(seedColor))
ThemeData themeEight(Brightness mode, bool useMaterial3) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    brightness: mode,
    seedColor: primaryColor,
  ),
  useMaterial3: useMaterial3,
  visualDensity: VisualDensity.standard,
);

// 9) TD.from scheme.fromSeed
//    ThemeData(colorScheme: ColorScheme.fromSeed(...))
ThemeData themeNine(Brightness mode, bool useMaterial3) => ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    brightness: mode,
    seedColor: primaryColor,
  ),
  useMaterial3: useMaterial3,
).copyWith(visualDensity: VisualDensity.standard);

// 10) Custom ThemeData()
ThemeData themeTen(Brightness mode, bool useMaterial3) =>
    mode == Brightness.light
        ? ThemeData(
      primaryColor: mySchemeLight.primary,
      primaryColorLight: Color.alphaBlend(
          Colors.white.withAlpha(0x66), mySchemeLight.primary),
      primaryColorDark: Color.alphaBlend(
          Colors.black.withAlpha(0x66), mySchemeLight.primary),
      secondaryHeaderColor: Color.alphaBlend(
          Colors.white.withAlpha(0xCC), mySchemeLight.primary),
      scaffoldBackgroundColor: mySchemeLight.background,
      canvasColor: mySchemeLight.background,
      cardColor: mySchemeLight.surface,
      dialogBackgroundColor: mySchemeLight.surface,
      indicatorColor: useMaterial3
          ? mySchemeLight.onSurface
          : mySchemeLight.onPrimary,
      dividerColor: mySchemeLight.onSurface.withOpacity(0.12),
      errorColor: mySchemeLight.error,
      applyElevationOverlayColor: false,
      useMaterial3: useMaterial3,
      visualDensity: VisualDensity.standard,
      tabBarTheme: TabBarTheme(
          labelColor: useMaterial3
              ? mySchemeLight.onSurface
              : mySchemeLight.onPrimary), checkboxTheme: CheckboxThemeData(
 fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
 if (states.contains(MaterialState.disabled)) { return null; }
 if (states.contains(MaterialState.selected)) { return useMaterial3 ? mySchemeLight.primary : mySchemeLight.secondary; }
 return null;
 }),
 ), radioTheme: RadioThemeData(
 fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
 if (states.contains(MaterialState.disabled)) { return null; }
 if (states.contains(MaterialState.selected)) { return useMaterial3 ? mySchemeLight.primary : mySchemeLight.secondary; }
 return null;
 }),
 ), switchTheme: SwitchThemeData(
 thumbColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
 if (states.contains(MaterialState.disabled)) { return null; }
 if (states.contains(MaterialState.selected)) { return useMaterial3 ? mySchemeLight.primary : mySchemeLight.secondary; }
 return null;
 }),
 trackColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
 if (states.contains(MaterialState.disabled)) { return null; }
 if (states.contains(MaterialState.selected)) { return useMaterial3 ? mySchemeLight.primary : mySchemeLight.secondary; }
 return null;
 }),
 ), colorScheme: mySchemeLight.copyWith(background: mySchemeLight.background), bottomAppBarTheme: BottomAppBarTheme(color: mySchemeLight.surface),
    )
        : ThemeData(
      colorScheme: mySchemeDark,
      primaryColor: mySchemeDark.primary,
      primaryColorLight: Color.alphaBlend(
          Colors.white.withAlpha(0x59), mySchemeDark.primary),
      primaryColorDark: Color.alphaBlend(
          Colors.black.withAlpha(0x72), mySchemeDark.primary),
      secondaryHeaderColor: Color.alphaBlend(
          Colors.black.withAlpha(0x99), mySchemeDark.primary),
      toggleableActiveColor:
      useMaterial3 ? mySchemeDark.primary : mySchemeDark.secondary,
      scaffoldBackgroundColor: mySchemeDark.background,
      canvasColor: mySchemeDark.background,
      backgroundColor: mySchemeDark.background,
      cardColor: mySchemeDark.surface,
      bottomAppBarColor: mySchemeDark.surface,
      dialogBackgroundColor: mySchemeDark.surface,
      indicatorColor: mySchemeDark.onSurface,
      dividerColor: mySchemeDark.onSurface.withOpacity(0.12),
      errorColor: mySchemeDark.error,
      applyElevationOverlayColor: true,
      useMaterial3: useMaterial3,
      visualDensity: VisualDensity.standard,
      tabBarTheme: TabBarTheme(labelColor: mySchemeDark.onSurface),
    );
