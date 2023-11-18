import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/launch_page.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_service.dart';
import 'screens/bottom_nav.dart';

void main() async{
  //Splash screen & Widget Init
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  //Initialize app for firebase
  await Firebase.initializeApp(
    name: 'animalplant-identifier',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

//New app that will open MyAppState
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();


}

//Creating MyAppState to display
class MyAppState extends State<MyApp> {
  final customColorScheme = const ColorScheme(
    primary: Color(0xFF3A83D0),
    secondary: Color(0xFF87BEDE),
    surface: Colors.white,
    background: Colors.white,
    error: Colors.red,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black,
    onBackground: Colors.black,
    onError: Colors.white,
    brightness: Brightness.light,
  );

  Widget currentPage = LaunchPage(title: 'Login / Sign Up');
  //Create instance of auth service
  AuthService authService = AuthService();


  //Override the initial state
  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  //Check if the user is logged in
  void checkLogin() async{
    print("Checking for Login");
    String? token = await authService.getToken();
    //If token exists the user is already logged in, if not they are logged out
    if(token != null){
      print("User is already logged in");
      //Set the current page to the navbar page
      setState(() {
        currentPage = const BottomNav();
      });
    }
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: '',
      theme: ThemeData(
        colorScheme: customColorScheme,
        useMaterial3: true,
      ),
      //Home is the page that will be called first
      home: currentPage,
      debugShowCheckedModeBanner: false,
    );
  }
}