import 'dart:ui';

import 'api_end_points.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';

class Config {
  static final String baseUrl = ApiEndPoints.baseUrl;
  static int? userId;
  String
      // clientId = '11',
      //clientId = '18',
      clientId = '6',
      // clientSecret = 'l5UyKyMgOoki0j8ObHI4jdJa6FKvsuvmrHxzqVfa',
      //clientSecret = 'DbrwennZcuvRbAWHtiixGrNv4Ydtp4vAyFjcZLwW',
      clientSecret = 'ZYZBXtx9EY6c43lzpJa2NK4Wd72RH94etHOmVOVc',
      copyright = '\u00a9',
      appName = 'Tillio',
      version = 'V 3.0',
      splashScreen = '${Config.baseUrl}/uploads/mobile/welcome.jpg',
      loginScreen = '${Config.baseUrl}/uploads/mobile/login.jpg',
      noDataImage = '${Config.baseUrl}/uploads/mobile/no_data.jpg',
      defaultBusinessImage = '${Config.baseUrl}/uploads/business_default.jpg';
  final bool syncCallLog = true,
      showRegister = true,
      showFieldForce = false,
      showCustomerAccounts = true,
      showShipments = false,
      showFollowUps = false,
      showSales = false,
      showReports = true,
      showBusinessName = true,
      showProfile = true;

  //quantity precision       //currency precision   //call_log sync duration
  static int quantityPrecision = 0,
      currencyPrecision = 0,
      callLogSyncDuration = 30;

  //List of locale language code
  List locale = [
    'en',
    'ar',
    'de',
    'fr',
    'es',
    'tr',
    'id',
    'my',
    'be',
    'ch',
    'it'
  ];
  String defaultLanguage = 'en';

  //List of locales included
  List<Locale> supportedLocales = [
    const Locale('en', 'US'),
    const Locale('ar', ''),
    const Locale('de', ''),
    const Locale('fr', ''),
    const Locale('es', ''),
    const Locale('tr', ''),
    const Locale('id', ''),
    const Locale('my', '')
  ];

  //dropdown items for changing language
  List<Map<String, dynamic>> lang = [
    {'languageCode': 'en', 'countryCode': 'US', 'name': 'English'},
    {'languageCode': 'ar', 'countryCode': '', 'name': 'العربي'},
    {'languageCode': 'de', 'countryCode': '', 'name': 'Deutsche'},
    {'languageCode': 'fr', 'countryCode': '', 'name': 'Français'},
    {'languageCode': 'es', 'countryCode': '', 'name': 'Española'},
    {'languageCode': 'tr', 'countryCode': '', 'name': 'Türkçe'},
    {'languageCode': 'id', 'countryCode': '', 'name': 'Indonesian'},
    {'languageCode': 'be', 'countryCode': '', 'name': 'Bengali'},
    {'languageCode': 'ch', 'countryCode': '', 'name': 'chinese'},
    {'languageCode': 'it', 'countryCode': '', 'name': 'italian'},
    {'languageCode': 'my', 'countryCode': '', 'name': 'မြန်မာ'}
  ];

  //final initialPosition = LatLng(20.46752985010792, 82.92005813910752);
  final String googleAPIKey =
      'AIzaSyA_E-RmRh_uWNVriwEX1QUKGunwljD4wxo'; //'AIzaSyDtorf5cQD5g7V4K2R0JVl8DcnnqiZS5Qw';
  final String googleclientId =
      '546155288702-rqia0b04ndpr6i7asjst890refb8dv60.apps.googleusercontent.com';
  final String digifarmerUrl =
      'https://digifarmer.digifrica.com/api/login/qrcode?code=';
  final String posAPIKey = '6H7g9f2Kd8P4s1V3xZ9r5Q0mL8Y2W7aB';
}
