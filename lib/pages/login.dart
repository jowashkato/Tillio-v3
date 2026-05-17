import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../apis/contact.dart';
import '../helpers/style.dart' as style;
import '../apis/api.dart';
import '../apis/system.dart';
import '../apis/user.dart';
import '../config.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/database.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';
import '../models/variations.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
    'profile',
  ],
  signInOption: SignInOption.standard,
  serverClientId: Config().googleclientId,
);

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);

  final _formKey = GlobalKey<FormState>();
  Timer? timer;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String defaultGoogleImage = 'assets/images/google.png';
  bool isLoading = false;
  bool _passwordVisible = false;
  bool _isGoogleSigningIn = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    if (timer != null) timer!.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      print('Google user changed: ${account?.email}');
    });

    _googleSignIn.signInSilently().then((account) {
      if (account != null) {
        print('Silent sign-in successful: ${account.email}');
      }
    }).catchError((error) {
      print('Silent sign-in error: $error');
    });
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleSigningIn) return;

    setState(() {
      _isGoogleSigningIn = true;
      isLoading = true;
    });

    try {
      // First, sign out to ensure fresh sign-in
      await _googleSignIn.signOut();

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled sign-in
        setState(() {
          _isGoogleSigningIn = false;
          isLoading = false;
        });
        return;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      print('ID Token: $idToken');
      print('Access Token: $accessToken');
      print('User Email: ${googleUser.email}');
      print('User Name: ${googleUser.displayName}');

      if (idToken == null) {
        Fluttertoast.showToast(
          msg: "Failed to get authentication token",
          backgroundColor: Colors.red,
        );
        setState(() {
          _isGoogleSigningIn = false;
          isLoading = false;
        });
        return;
      }

      // Send token to your backend for validation and login
      Map<String, dynamic> loginData = {
        'id_token': idToken,
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'access_token': accessToken,
      };

      // Call your API to verify and login
      Map? loginResponse = await CustomerApi().loginWithGoogle(loginData);

      if (loginResponse != null && loginResponse['success'] == true) {
        // Show loading dialog
        showLoadingDialogue();

        // Load all user data
        await loadAllData(loginResponse, context);

        // Navigate to home
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/layout');
        }

        Fluttertoast.showToast(
          msg: "Google Sign-In Successful!",
          backgroundColor: Colors.green,
        );
      } else {
        String errorMsg = loginResponse?['message'] ?? "Google Sign-In failed";
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.red,
          fontSize: 18,
          gravity: ToastGravity.TOP,
        );
      }
    } catch (error) {
      print('Google Sign-In Error: $error');
      Fluttertoast.showToast(
        msg: "Google Sign-In failed: $error",
        backgroundColor: Colors.red,
        fontSize: 18,
        gravity: ToastGravity.TOP,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSigningIn = false;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xff3d63ff),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  const Icon(
                    Icons.payment,
                    size: 80,
                    color: Colors.white,
                  ),
                  Text(
                    Config().appName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 26.0),
                    height: 550,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50.0),
                      color: Colors.white,
                    ),
                    margin: EdgeInsets.only(
                      left: MySize.size16 ?? 16,
                      right: MySize.size16 ?? 16,
                      top: MySize.size16 ?? 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Login to continue",
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.titleLarge,
                            muted: true,
                            fontWeight: 700,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyLarge,
                            letterSpacing: 0.1,
                            color: themeData.colorScheme.onSurface,
                            fontWeight: 500,
                          ),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)
                                .translate('username'),
                            hintStyle: AppTheme.getTextStyle(
                              themeData.textTheme.titleSmall,
                              letterSpacing: 0.1,
                              color: themeData.colorScheme.onSurface,
                              fontWeight: 500,
                            ),
                            filled: true,
                            fillColor: usernameController.text.isEmpty
                                ? const Color.fromRGBO(248, 247, 251, 1)
                                : Colors.transparent,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: usernameController.text.isEmpty
                                    ? Colors.transparent
                                    : style.StyleColors().mainColor(1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: style.StyleColors().mainColor(1),
                              ),
                            ),
                            suffixIcon: const Icon(MdiIcons.faceMan),
                          ),
                          controller: usernameController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return AppLocalizations.of(context)
                                  .translate('please_enter_username');
                            }
                            return null;
                          },
                          autofocus: true,
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          keyboardType: TextInputType.visiblePassword,
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyLarge,
                            letterSpacing: 0.1,
                            color: themeData.colorScheme.onBackground,
                            fontWeight: 500,
                          ),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)
                                .translate('password'),
                            hintStyle: AppTheme.getTextStyle(
                              themeData.textTheme.titleSmall,
                              letterSpacing: 0.1,
                              color: themeData.colorScheme.onBackground,
                              fontWeight: 500,
                            ),
                            filled: true,
                            fillColor: passwordController.text.isEmpty
                                ? const Color.fromRGBO(248, 247, 251, 1)
                                : Colors.transparent,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: passwordController.text.isEmpty
                                    ? Colors.transparent
                                    : const Color.fromRGBO(44, 185, 176, 1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: style.StyleColors().mainColor(1),
                              ),
                            ),
                            suffixIcon: IconButton(
                              color: passwordController.text.isEmpty
                                  ? style.StyleColors().mainColor(1)
                                  : const Color.fromRGBO(44, 185, 176, 1),
                              icon: Icon(_passwordVisible
                                  ? MdiIcons.eyeOutline
                                  : MdiIcons.eyeOffOutline),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_passwordVisible,
                          controller: passwordController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return AppLocalizations.of(context)
                                  .translate('please_enter_password');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Login Button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.0),
                            color: const Color(0xff3d63ff),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4C2E84).withOpacity(0.2),
                                offset: const Offset(0, 15.0),
                                blurRadius: 60.0,
                              ),
                            ],
                          ),
                          child: TextButton(
                            child: isLoading && !_isGoogleSigningIn
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    AppLocalizations.of(context)
                                        .translate('login'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                            onPressed: () async {
                              if (await Helper().checkConnectivity()) {
                                if (_formKey.currentState!.validate() &&
                                    !isLoading) {
                                  try {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    Map? loginResponse = await Api().login(
                                      usernameController.text,
                                      passwordController.text,
                                    );
                                    if (loginResponse != null &&
                                        loginResponse['success']) {
                                      showLoadingDialogue();
                                      await loadAllData(loginResponse, context);
                                      if (mounted) {
                                        Navigator.of(context)
                                            .pushReplacementNamed('/layout');
                                      }
                                    } else {
                                      Fluttertoast.showToast(
                                        toastLength: Toast.LENGTH_LONG,
                                        fontSize: 18,
                                        gravity: ToastGravity.TOP,
                                        backgroundColor: Colors.red,
                                        msg: AppLocalizations.of(context)
                                            .translate('invalid_credentials'),
                                      );
                                    }
                                  } catch (e) {
                                    print(e);
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                }
                              }
                            },
                          ),
                        ),
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Navigate to Forgot Password
                              // Navigator.of(context).pushNamed('/forgotPassword');
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xff3d63ff),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Register Button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.0),
                            color: Colors.transparent,
                            border: Border.all(
                              color: const Color(0xff3d63ff),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4C2E84).withOpacity(0.2),
                                offset: const Offset(0, 15.0),
                                blurRadius: 60.0,
                              ),
                            ],
                          ),
                          child: TextButton(
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('register'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xff3d63ff),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () async {
                              if (mounted) {
                                Navigator.of(context).pushNamed('/registerNow');
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            "OR",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Google Sign-In Button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xff3d63ff)),
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          child: InkWell(
                            onTap:
                                _isGoogleSigningIn ? null : _handleGoogleSignIn,
                            borderRadius: BorderRadius.circular(50.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isGoogleSigningIn)
                                    const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xff3d63ff),
                                      ),
                                    )
                                  else
                                    Image.asset(
                                      defaultGoogleImage,
                                      height: 24,
                                      width: 24,
                                    ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isGoogleSigningIn
                                        ? "Signing in..."
                                        : "Continue with Google",
                                    style: const TextStyle(
                                      color: Color(0xff3d63ff),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> loadAllData(Map loginResponse, BuildContext context) async {
    // Cancel any existing timer
    if (timer != null) timer!.cancel();

    timer = Timer.periodic(const Duration(minutes: 5), (Timer t) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: AppLocalizations.of(context)
              .translate('It_may_take_some_more_time_to_load'),
        );
      }
      t.cancel();
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map loggedInUser = await User().get(loginResponse['access_token']);

    Config.userId = loggedInUser['id'];
    await prefs.setInt('userId', loggedInUser['id']);
    print("UserID => ${loggedInUser['id']}");

    await DbProvider().initializeDatabase(loggedInUser['id']);

    String? lastSync = await System().getProductLastSync();
    final DateTime date2 = DateTime.now();

    // Delete old data
    await System().empty();
    await Contact().emptyContact();

    // Save user details
    await System().insertUserDetails(loggedInUser);
    await System().insertToken(loginResponse['access_token']);
    await SystemApi().store();
    await System().insertProductLastSyncDateTimeNow();

    // Check previous userId
    if (prefs.getInt('prevUserId') == null ||
        prefs.getInt('prevUserId') != prefs.getInt('userId')) {
      await SellDatabase().deleteSellTables();
      await Variations().refresh();
    } else {
      if (lastSync == null ||
          (date2.difference(DateTime.parse(lastSync)).inHours > 10)) {
        if (await Helper().checkConnectivity()) {
          await Variations().refresh();
          await System().insertProductLastSyncDateTimeNow();
          await SellDatabase().deleteSellTables();
        }
      }
    }

    if (timer != null) timer!.cancel();

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
    }
  }

  Future<void> showLoadingDialogue() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Lottie.asset(
            'assets/lottie/loading.json',
            width: 200,
            height: 200,
          ),
        );
      },
    );
  }
}
