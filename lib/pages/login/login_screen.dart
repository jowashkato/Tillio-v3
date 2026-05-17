// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:lottie/lottie.dart';
// import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
//
// import '../../config.dart';
// import '../../constants.dart';
// import '../../helpers/AppTheme.dart';
// import '../../helpers/SizeConfig.dart';
// import '../../locale/MyLocalizations.dart';
// import 'view_model_manger/login_cubit.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   static int themeType = 1;
//   ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
//
//   @override
//   Widget build(BuildContext context) {
//     final Size size = MediaQuery.of(context).size;
//     return BlocProvider(
//       create: (context) => LoginCubit(),
//       child: BlocConsumer<LoginCubit, LoginState>(
//         listener: (context, state) {
//           if (state is LoginFailed) {
//             LoginCubit.get(context).isLoading = false;
//             Fluttertoast.showToast(
//                 fontSize: 18,
//                 backgroundColor: Colors.red,
//                 msg: AppLocalizations.of(context)
//                     .translate('invalid_credentials'));
//           } else if (state is LoginSuccessfully) {
//             LoginCubit.get(context).navigateToHome(context);
//           }
//         },
//         builder: (context, state) {
//           var cubit = LoginCubit.get(context);
//           themeData = Theme.of(context);
//           return Scaffold(
//               body: SingleChildScrollView(
//             child: SafeArea(
//               child: Center(
//                 child: Form(
//                   key: cubit.formKey,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.max,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Lottie.asset('assets/lottie/welcome.json',
//                           height: size.height * .1),
//                       Container(
//                         alignment: Alignment.center,
//                         height: 400,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(50.0),
//                           color: Colors.white,
//                         ),
//                         margin: EdgeInsets.only(
//                             left: MySize.size16!,
//                             right: MySize.size16!,
//                             top: MySize.size16!),
//                         child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                                 child: TextFormField(
//                                   style: AppTheme.getTextStyle(
//                                       themeData.textTheme.bodyLarge,
//                                       letterSpacing: 0.1,
//                                       color: themeData.colorScheme.onSurface,
//                                       fontWeight: 500),
//                                   decoration: InputDecoration(
//                                     hintText: AppLocalizations.of(context)
//                                         .translate('username'),
//                                     hintStyle: AppTheme.getTextStyle(
//                                         themeData.textTheme.titleSmall,
//                                         letterSpacing: 0.1,
//                                         color: themeData.colorScheme.onBackground,
//                                         fontWeight: 500),
//                                     filled: true,
//                                     fillColor: cubit.usernameController.text.isEmpty
//                                         ? const Color.fromRGBO(248, 247, 251, 1)
//                                         : Colors.transparent,
//                                     enabledBorder: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(40),
//                                         borderSide: BorderSide(
//                                           color: cubit.usernameController.text.isEmpty
//                                               ? Colors.transparent
//                                               : const Color(0xff3d63ff),
//                                         )),
//                                     focusedBorder: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(40),
//                                         borderSide: const BorderSide(
//                                           color: Color(0xff3d63ff),
//                                         )),
//                                     suffixIcon: Icon(MdiIcons.faceMan),
//                                   ),
//                                   controller: cubit.usernameController,
//                                   validator: (value) {
//                                     if (value!.isEmpty) {
//                                       return AppLocalizations.of(context)
//                                           .translate('please_enter_username');
//                                     }
//                                     return null;
//                                   },
//                                   autofocus: true,
//                                 ),
//                               ),
//                               SizedBox(height: 15,),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//
//                                 child: TextFormField(
//                                   keyboardType: TextInputType.visiblePassword,
//                                   style: AppTheme.getTextStyle(
//                                       themeData.textTheme.bodyLarge,
//                                       letterSpacing: 0.1,
//                                       color: themeData.colorScheme.onBackground,
//                                       fontWeight: 500),
//                                   decoration: InputDecoration(
//                                     hintText: AppLocalizations.of(context)
//                                         .translate('password'),
//                                     hintStyle: AppTheme.getTextStyle(
//                                         themeData.textTheme.titleSmall,
//                                         letterSpacing: 0.1,
//                                         color: themeData.colorScheme.onBackground,
//                                         fontWeight: 500),
//                                     filled: true,
//                                     fillColor: cubit.passwordController.text.isEmpty
//                                         ? const Color.fromRGBO(248, 247, 251, 1)
//                                         : Colors.transparent,
//                                     enabledBorder: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(40),
//                                         borderSide: BorderSide(
//                                           color: cubit.passwordController.text.isEmpty
//                                               ? Colors.transparent
//                                               : const Color.fromRGBO(44, 185, 176, 1),
//                                         )),
//                                     focusedBorder: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(40),
//                                         borderSide: const BorderSide(
//                                           color: Color(0xff3d63ff),
//                                         )),
//                                     suffixIcon: IconButton(
//                                       color: cubit.passwordController.text.isEmpty
//                                           ? const Color(0xff3d63ff)
//                                           : const Color.fromRGBO(44, 185, 176, 1),
//                                       icon: Icon(_passwordVisible
//                                           ? MdiIcons.eyeOutline
//                                           : MdiIcons.eyeOffOutline),
//                                       onPressed: () {
//                                         setState(() {
//                                           _passwordVisible = !_passwordVisible;
//                                         });
//                                       },
//                                     ),
//                                   ),
//                                   obscureText: !_passwordVisible,
//                                   controller: cubit.passwordController,
//                                   validator: (value) {
//                                     if (value!.isEmpty) {
//                                       return AppLocalizations.of(context)
//                                           .translate('please_enter_password');
//                                     }
//                                     return null;
//                                   },
//                                 ),
//                               ),
//                               SizedBox(height: 40,),
//                               Container(
//                                 alignment: Alignment.center,
//                                 width: 200,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(50.0),
//                                   color: const Color(0xff3d63ff),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: const Color(0xFF4C2E84).withOpacity(0.2),
//                                       offset: const Offset(0, 15.0),
//                                       blurRadius: 60.0,
//                                     ),
//                                   ],
//                                 ),
//                                 child: TextButton(
//                                     child: isLoading ? CircularProgressIndicator():
//                                     Text(
//                                       AppLocalizations.of(context)
//                                           .translate('login'),
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                           color: Colors.white),),
//                                     onPressed: () async {
//                                       if (await Helper().checkConnectivity()) {
//                                         if (_formKey.currentState!.validate() &&
//                                             !isLoading) {
//                                           setState(() {
//                                             isLoading = true;
//                                           });
//
//                                           Map? loginResponse = await Api().login(
//                                               usernameController.text,
//                                               passwordController.text);
//
//                                           if (loginResponse!['success']) {
//                                             //schedule job for syncing callLogs
//                                             Helper().jobScheduler();
//                                             //Get current logged in user details and save it.
//
//                                             showLoadingDialogue();
//                                             await loadAllData(loginResponse, context);
//                                             Navigator.of(context).pop();
//
//                                             //Take to home page
//                                             Navigator.of(context).pushNamed('/layout');
//                                           }
//                                           else {
//                                             setState(() {
//                                               isLoading = false;
//                                             });
//
//                                             Fluttertoast.showToast(
//                                                 fontSize: 18,
//                                                 backgroundColor: Colors.red,
//                                                 msg: AppLocalizations.of(context)
//                                                     .translate('invalid_credentials'));
//                                           }
//                                         }
//                                       }
//                                     }),
//                               ),
//                             ]),
//                       ),
//
//                       Text(
//                         Config().appName,
//                         style: cubit.themeData.textTheme.headlineMedium
//                             ?.copyWith(color: Colors.white),
//                       ),
//                       Container(
//                         padding: EdgeInsets.only(top: size.height * 0.1),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: [
//                             TextFormField(
//                               style: AppTheme.getTextStyle(
//                                   cubit.themeData.textTheme.bodyLarge,
//                                   letterSpacing: 0.1,
//                                   color:
//                                       cubit.themeData.colorScheme.onBackground,
//                                   fontWeight: 500),
//                               decoration: InputDecoration(
//                                 hintText: AppLocalizations.of(context)
//                                     .translate('username'),
//                                 hintStyle: AppTheme.getTextStyle(
//                                     cubit.themeData.textTheme.titleSmall,
//                                     letterSpacing: 0.1,
//                                     color:
//                                         cubit.themeData.colorScheme.onSurface,
//                                     fontWeight: 500),
//                                 filled: true,
//                                 fillColor:
//                                     const Color.fromRGBO(248, 247, 251, 1),
//                                 enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(40),
//                                     borderSide: const BorderSide(
//                                       color: kDefaultColor,
//                                     )),
//                                 focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(40),
//                                     borderSide: const BorderSide(
//                                       color: kDefaultColor,
//                                     )),
//                                 suffixIcon: const Icon(MdiIcons.faceMan),
//                               ),
//                               controller: cubit.usernameController,
//                               validator: (value) {
//                                 if (value!.isEmpty) {
//                                   return AppLocalizations.of(context)
//                                       .translate('please_enter_username');
//                                 }
//                                 return null;
//                               },
//                               autofocus: true,
//                             ),
//                             SizedBox(
//                               height: 12,
//                             ),
//                             TextFormField(
//                               keyboardType: TextInputType.visiblePassword,
//                               style: AppTheme.getTextStyle(
//                                   cubit.themeData.textTheme.bodyLarge,
//                                   letterSpacing: 0.1,
//                                   color: cubit.themeData.colorScheme.onSurface,
//                                   fontWeight: 500),
//                               decoration: InputDecoration(
//                                 hintText: AppLocalizations.of(context)
//                                     .translate('password'),
//                                 hintStyle: AppTheme.getTextStyle(
//                                     cubit.themeData.textTheme.titleSmall,
//                                     letterSpacing: 0.1,
//                                     color:
//                                         cubit.themeData.colorScheme.onSurface,
//                                     fontWeight: 500),
//                                 filled: true,
//                                 fillColor:
//                                     const Color.fromRGBO(248, 247, 251, 1),
//                                 enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(40),
//                                     borderSide: BorderSide(
//                                       color: Colors.transparent,
//                                     )),
//                                 focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(40),
//                                     borderSide: BorderSide(
//                                       color: kDefaultColor,
//                                     )),
//                                 suffixIcon: IconButton(
//                                   color: kDefaultColor,
//                                   icon: Icon(cubit.passwordIcon),
//                                   onPressed: () {
//                                     cubit.passwordVisible =
//                                         !cubit.passwordVisible;
//                                     /*setState(() {
//                                     _passwordVisible = !_passwordVisible;
//                                   });*/
//                                   },
//                                 ),
//                               ),
//                               obscureText: !cubit.passwordVisible,
//                               controller: cubit.passwordController,
//                               validator: (value) {
//                                 if (value!.isEmpty) {
//                                   return AppLocalizations.of(context)
//                                       .translate('please_enter_password');
//                                 }
//                                 return null;
//                               },
//                             ),
//                             SizedBox(
//                               height: 20,
//                             ),
//                             SizedBox(
//                               width: double.infinity,
//                               child: ElevatedButton(
//                                 onPressed: () async {
//                                   await cubit.checkOnLogin(context);
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.white,
//                                     shape: RoundedRectangleBorder(
//                                         borderRadius:
//                                             BorderRadius.circular(30))),
//                                 child: Text(
//                                   AppLocalizations.of(context)
//                                       .translate('login'),
//                                   style: cubit.themeData.textTheme.labelLarge,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       SizedBox(
//                         height: size.height * 0.1,
//                       ),
//                       Text(
//                         AppLocalizations.of(context).translate('no_account'),
//                         style: cubit.themeData.textTheme.bodyLarge
//                             ?.copyWith(color: Colors.white),
//                       ),
//                       ElevatedButton(
//                         onPressed: () async {
//                           await cubit.register();
//                         },
//                         style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30))),
//                         child: Text(
//                           AppLocalizations.of(context).translate('register'),
//                           style: cubit.themeData.textTheme.labelLarge,
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ));
//         },
//       ),
//     );
//   }
// }
