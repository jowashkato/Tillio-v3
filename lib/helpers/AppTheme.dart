import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class AppTheme {
  static final int themeLight = 1;
  static final int themeDark = 2;

  AppTheme._();

  /// Uses the bundled Cairo font from assets/fonts — avoids network fetch at
  /// runtime, which causes blank screens in release APKs when offline.
  static TextStyle _cairoStyle(TextStyle style) {
    return style.copyWith(fontFamily: 'Cairo');
  }

  static CustomAppTheme getCustomAppTheme(int themeMode) {
    if (themeMode == themeLight) {
      return lightCustomAppTheme;
    } else if (themeMode == themeDark) {
      return darkCustomAppTheme;
    }
    return darkCustomAppTheme;
  }

  static FontWeight _getFontWeight(int weight) {
    switch (weight) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w300;
      case 500:
        return FontWeight.w400;
      case 600:
        return FontWeight.w500;
      case 700:
        return FontWeight.w600;
      case 800:
        return FontWeight.w700;
      case 900:
        return FontWeight.w900;
    }
    return FontWeight.w400;
  }

  static TextStyle getTextStyle(TextStyle? textStyle,
      {int fontWeight = 500,
      bool muted = false,
      bool xMuted = false,
      double letterSpacing = 0.15,
      Color? color,
      TextDecoration decoration = TextDecoration.none,
      double? height,
      double wordSpacing = 0,
      double fontSize = 16}) {
    double finalFontSize = fontSize;

    Color finalColor;
    if (color == null) {
      finalColor = (xMuted
          ? textStyle!.color!.withAlpha(160)
          : (muted ? textStyle!.color!.withAlpha(200) : textStyle!.color))!;
    } else {
      finalColor = xMuted
          ? color.withAlpha(160)
          : (muted ? color.withAlpha(200) : color);
    }

    return _cairoStyle(TextStyle(
        fontSize: finalFontSize,
        fontWeight: _getFontWeight(fontWeight),
        letterSpacing: letterSpacing,
        color: finalColor,
        decoration: decoration,
        height: height,
        wordSpacing: wordSpacing));
  }

  // Light App Bar Text Theme
  static final TextTheme lightAppBarTextTheme = TextTheme(
    displayLarge: _cairoStyle( const TextStyle(fontSize: 102, color: Color(0xff495057))),
    displayMedium: _cairoStyle( const TextStyle(fontSize: 64, color: Color(0xff495057))),
    displaySmall: _cairoStyle( TextStyle(fontSize: 51, color: Color(0xff495057))),
    headlineLarge: _cairoStyle( TextStyle(fontSize: 36, color: Color(0xff495057))),
    headlineMedium: _cairoStyle( TextStyle(fontSize: 25, color: Color(0xff495057))),
    headlineSmall: _cairoStyle( TextStyle(fontSize: 18, color: Color(0xff495057))),
    titleLarge: _cairoStyle( TextStyle(fontSize: 17, color: Color(0xff495057))),
    titleMedium: _cairoStyle( TextStyle(fontSize: 15, color: Color(0xff495057))),
    bodyLarge: _cairoStyle( TextStyle(fontSize: 16, color: Color(0xff495057))),
    bodyMedium: _cairoStyle( TextStyle(fontSize: 14, color: Color(0xff495057))),
    labelLarge: _cairoStyle( TextStyle(fontSize: 15, color: Color(0xff495057))),
    bodySmall: _cairoStyle( TextStyle(fontSize: 13, color: Color(0xff495057))),
    labelSmall: _cairoStyle( TextStyle(fontSize: 11, color: Color(0xff495057))),
  );

// Dark App Bar Text Theme
  static final TextTheme darkAppBarTextTheme = TextTheme(
    displayLarge: _cairoStyle( TextStyle(fontSize: 102, color: Color(0xffffffff))),
    displayMedium: _cairoStyle( TextStyle(fontSize: 64, color: Color(0xffffffff))),
    displaySmall: _cairoStyle( TextStyle(fontSize: 51, color: Color(0xffffffff))),
    headlineLarge: _cairoStyle( TextStyle(fontSize: 36, color: Color(0xffffffff))),
    headlineMedium: _cairoStyle( TextStyle(fontSize: 25, color: Color(0xffffffff))),
    headlineSmall: _cairoStyle( TextStyle(fontSize: 20, color: Color(0xffffffff))),
    titleLarge: _cairoStyle( TextStyle(fontSize: 17, color: Color(0xffffffff))),
    titleMedium: _cairoStyle( TextStyle(fontSize: 15, color: Color(0xffffffff))),
    bodyLarge: _cairoStyle( TextStyle(fontSize: 16, color: Color(0xffffffff))),
    bodyMedium: _cairoStyle( TextStyle(fontSize: 14, color: Color(0xffffffff))),
    labelLarge: _cairoStyle( TextStyle(fontSize: 15, color: Color(0xffffffff))),
    bodySmall: _cairoStyle( TextStyle(fontSize: 13, color: Color(0xffffffff))),
    labelSmall: _cairoStyle( TextStyle(fontSize: 11, color: Color(0xffffffff))),
  );

  //Text Themes
  static final TextTheme lightTextTheme = TextTheme(
    displayLarge: _cairoStyle( TextStyle(fontSize: 102, color: Color(0xff4a4c4f))),
    displayMedium: _cairoStyle( TextStyle(fontSize: 64, color: Color(0xff4a4c4f))),
    displaySmall: _cairoStyle( TextStyle(fontSize: 51, color: Color(0xff4a4c4f))),
    headlineLarge: _cairoStyle( TextStyle(fontSize: 36, color: Color(0xff4a4c4f))),
    headlineMedium: _cairoStyle( TextStyle(fontSize: 25, color: Color(0xff4a4c4f))),
    headlineSmall: _cairoStyle( TextStyle(fontSize: 18, color: Color(0xff4a4c4f))),
    titleLarge: _cairoStyle( TextStyle(fontSize: 17, color: Color(0xff4a4c4f))),
    titleMedium: _cairoStyle( TextStyle(fontSize: 15, color: Color(0xff4a4c4f))),
    bodyLarge: _cairoStyle( TextStyle(fontSize: 16, color: Color(0xff4a4c4f))),
    bodyMedium: _cairoStyle( TextStyle(fontSize: 14, color: Color(0xff4a4c4f))),
    labelLarge: _cairoStyle( TextStyle(fontSize: 15, color: Color(0xff4a4c4f))),
    bodySmall: _cairoStyle( TextStyle(fontSize: 13, color: Color(0xff4a4c4f))),
    labelSmall: _cairoStyle( TextStyle(fontSize: 11, color: Color(0xff4a4c4f))),
  );

  static final TextTheme darkTextTheme = TextTheme(
    displayLarge: _cairoStyle( TextStyle(fontSize: 102, color: Colors.white)),
    displayMedium: _cairoStyle( TextStyle(fontSize: 64, color: Colors.white)),
    displaySmall: _cairoStyle( TextStyle(fontSize: 51, color: Colors.white)),
    headlineLarge: _cairoStyle( TextStyle(fontSize: 36, color: Colors.white)),
    headlineMedium: _cairoStyle( TextStyle(fontSize: 25, color: Colors.white)),
    headlineSmall: _cairoStyle( TextStyle(fontSize: 18, color: Colors.white)),
    titleLarge: _cairoStyle( TextStyle(fontSize: 17, color: Colors.white)),
    titleMedium: _cairoStyle( TextStyle(fontSize: 15, color: Colors.white)),
    bodyLarge: _cairoStyle( TextStyle(fontSize: 16, color: Colors.white)),
    bodyMedium: _cairoStyle( TextStyle(fontSize: 14, color: Colors.white)),
    labelLarge: _cairoStyle( TextStyle(fontSize: 15, color: Colors.white)),
    bodySmall: _cairoStyle( TextStyle(fontSize: 13, color: Colors.white)),
    labelSmall: _cairoStyle( TextStyle(fontSize: 11, color: Colors.white)),
  );

  static final ThemeData lightTheme = ThemeData(
    fontFamily: 'Cairo',
    brightness: Brightness.light,
    primaryColor: kDefaultColor,
    canvasColor: Colors.transparent,
    scaffoldBackgroundColor: Color(0xffffffff),
    appBarTheme: AppBarTheme(
      actionsIconTheme: IconThemeData(
        color: Color(0xff495057),
      ),
      color: Color(0xffffffff),
      iconTheme: IconThemeData(color: Color(0xff495057), size: 24),
    ),
    navigationRailTheme: NavigationRailThemeData(
        selectedIconTheme:
            IconThemeData(color: kDefaultColor, opacity: 1, size: 24),
        unselectedIconTheme:
            IconThemeData(color: Color(0xff495057), opacity: 1, size: 24),
        backgroundColor: Color(0xffffffff),
        elevation: 3,
        selectedLabelTextStyle: TextStyle(color: kDefaultColor),
        unselectedLabelTextStyle: TextStyle(color: Color(0xff495057))),
    cardTheme: CardThemeData(
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.4),
      elevation: 1,
      margin: EdgeInsets.all(0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(fontSize: 15, color: Color(0xaa495057)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(width: 1, color: kDefaultColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(width: 1, color: Colors.black54),
      ),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: Colors.black54)),
    ),
    splashColor: Colors.white.withAlpha(100),
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
    textTheme: lightTextTheme,
    indicatorColor: Colors.white,
    disabledColor: Color(0xffdcc7ff),
    highlightColor: Colors.white,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: kDefaultColor,
        splashColor: Colors.white.withAlpha(100),
        highlightElevation: 8,
        elevation: 4,
        focusColor: kDefaultColor,
        hoverColor: kDefaultColor,
        foregroundColor: Colors.white),
    dividerColor: Color(0xffd1d1d1),
    // errorColor: Color(0xfff0323c),
    cardColor: Colors.white,
    popupMenuTheme: PopupMenuThemeData(
      color: Color(0xffffffff),
      textStyle:
          lightTextTheme.bodyMedium!.merge(TextStyle(color: Color(0xff495057))),
    ),
    bottomAppBarTheme:
        BottomAppBarThemeData(color: Color(0xffffffff), elevation: 2),
    tabBarTheme: TabBarThemeData(
      unselectedLabelColor: Color(0xff495057),
      labelColor: kDefaultColor,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: kDefaultColor, width: 2.0),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: kDefaultColor,
      inactiveTrackColor: kDefaultColor.withAlpha(140),
      trackShape: RoundedRectSliderTrackShape(),
      trackHeight: 4.0,
      thumbColor: kDefaultColor,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
      tickMarkShape: RoundSliderTickMarkShape(),
      inactiveTickMarkColor: Colors.red[100],
      valueIndicatorShape: PaddleSliderValueIndicatorShape(),
      valueIndicatorTextStyle: TextStyle(
        color: Colors.white,
      ),
    ),
    colorScheme: ColorScheme.light(
            primary: kDefaultColor,
            onPrimary: Colors.white,
            secondary: Color(0xff495057),
            onSecondary: Colors.white,
            surface: Color(0xffe2e7f1),
            background: Color(0xfff3f4f7),
            onBackground: Color(0xff495057))
        .copyWith(secondary: kDefaultColor)
        .copyWith(background: Colors.white),
  );
  static ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      canvasColor: Colors.transparent,
      primaryColor: kDefaultColor,
      scaffoldBackgroundColor: Color(0xff464c52),
      appBarTheme: AppBarTheme(
        actionsIconTheme: IconThemeData(
          color: Color(0xffffffff),
        ),
        color: Color(0xff2e343b),
        iconTheme: IconThemeData(color: Color(0xffffffff), size: 24),
      ),
      cardTheme: CardThemeData(
        color: Color(0xff37404a),
        shadowColor: Color(0xff000000),
        elevation: 1,
        margin: EdgeInsets.all(0),
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
      textTheme: darkTextTheme,
      indicatorColor: Colors.white,
      disabledColor: Color(0xffa3a3a3),
      highlightColor: Colors.white,
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: kDefaultColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: Colors.white70),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(width: 1, color: Colors.white70)),
      ),
      dividerColor: Color(0xffd1d1d1),
      // errorColor: Colors.orange,
      cardColor: Color(0xff282a2b),
      splashColor: Colors.white.withAlpha(100),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: kDefaultColor,
          splashColor: Colors.white.withAlpha(100),
          highlightElevation: 8,
          elevation: 4,
          focusColor: kDefaultColor,
          hoverColor: kDefaultColor,
          foregroundColor: Colors.white),
      popupMenuTheme: PopupMenuThemeData(
        color: Color(0xff37404a),
        textStyle: lightTextTheme.bodyMedium!
            .merge(TextStyle(color: Color(0xffffffff))),
      ),
      bottomAppBarTheme:
          BottomAppBarThemeData(color: Color(0xff464c52), elevation: 2),
      tabBarTheme: TabBarThemeData(
        unselectedLabelColor: Color(0xff495057),
        labelColor: kDefaultColor,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: kDefaultColor, width: 2.0),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: kDefaultColor,
        inactiveTrackColor: kDefaultColor.withAlpha(100),
        trackShape: RoundedRectSliderTrackShape(),
        trackHeight: 4.0,
        thumbColor: kDefaultColor,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
        tickMarkShape: RoundSliderTickMarkShape(),
        inactiveTickMarkColor: Colors.red[100],
        valueIndicatorShape: PaddleSliderValueIndicatorShape(),
        valueIndicatorTextStyle: TextStyle(
          color: Colors.white,
        ),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(),
      colorScheme: ColorScheme.dark(
        primary: kDefaultColor,
        secondary: Color(0xff00cc77),
        background: Color(0xff343a40),
        onPrimary: Colors.white,
        onBackground: Colors.white,
        onSecondary: Colors.white,
        surface: Color(0xff585e63),
      )
          .copyWith(secondary: kDefaultColor)
          .copyWith(background: Color(0xff464c52)));

  static ThemeData getThemeFromThemeMode(int themeMode) {
    if (themeMode == themeLight) {
      return lightTheme;
    } else if (themeMode == themeDark) {
      return darkTheme;
    }
    return lightTheme;
  }

  static final CustomAppTheme lightCustomAppTheme = CustomAppTheme(
    bgLayer1: Color(0xffffffff),
    bgLayer2: Color(0xfff9f9f9),
    bgLayer3: Color(0xffe8ecf4),
    bgLayer4: Color(0xffdcdee3),
    disabledColor: Color(0xff636363),
    onDisabled: Color(0xffffffff),
    colorInfo: Color(0xffff784b),
    colorWarning: Color(0xffffc837),
    colorSuccess: Color(0xff3cd278),
    shadowColor: Color(0xffeaeaea),
    onInfo: Color(0xffffffff),
    onSuccess: Color(0xffffffff),
    onWarning: Color(0xffffffff),
    colorError: Color(0xfff0323c),
    onError: Color(0xffffffff),
  );
  static final CustomAppTheme darkCustomAppTheme = CustomAppTheme(
      bgLayer1: Color(0xff212429),
      bgLayer2: Color(0xff282930),
      bgLayer3: Color(0xff303138),
      bgLayer4: Color(0xff383942),
      disabledColor: Color(0xffbababa),
      onDisabled: Color(0xff000000),
      colorInfo: Color(0xffff784b),
      colorWarning: Color(0xffffc837),
      colorSuccess: Color(0xff3cd278),
      shadowColor: Color(0xff1a1a1a),
      onInfo: Color(0xffffffff),
      onSuccess: Color(0xffffffff),
      onWarning: Color(0xffffffff),
      colorError: Color(0xfff0323c),
      onError: Color(0xffffffff));
}

class CustomAppTheme {
  final Color bgLayer1,
      bgLayer2,
      bgLayer3,
      bgLayer4,
      disabledColor,
      onDisabled,
      colorInfo,
      colorWarning,
      colorSuccess,
      colorError,
      shadowColor,
      onInfo,
      onWarning,
      onSuccess,
      onError;

  CustomAppTheme({
    this.bgLayer1 = const Color(0xffffffff),
    this.bgLayer2 = const Color(0xfff8faff),
    this.bgLayer3 = const Color(0xffeef2fa),
    this.bgLayer4 = const Color(0xffdcdee3),
    this.disabledColor = const Color(0xffdcc7ff),
    this.onDisabled = const Color(0xffffffff),
    this.colorWarning = const Color(0xffffc837),
    this.colorInfo = const Color(0xffff784b),
    this.colorSuccess = const Color(0xff3cd278),
    this.shadowColor = const Color(0xff1f1f1f),
    this.onInfo = const Color(0xffffffff),
    this.onWarning = const Color(0xffffffff),
    this.onSuccess = const Color(0xffffffff),
    this.colorError = const Color(0xfff0323c),
    this.onError = const Color(0xffffffff),
  });
}
