import 'package:flutter/material.dart';
import 'package:test_project/screens/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';


class LaunchPage extends StatefulWidget{
  const LaunchPage({Key? key, required this.title}) : super(key : key);

  final String title;

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {

  //Init state and remove splash screen
  @override
  void initState() {
    super.initState();
    //Remove Screen After reading from firebase
    Future.delayed(Duration(
        milliseconds: 2000), () { //CHANGE VALUE HERE TO EDIT SPLASH SCREEN TIME
      //Remove Splash Screen
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFF87BEDE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF87BEDE),
        // title: Text(widget.title, style: TextStyle(color: Colors.white),),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(16.0), //CHANGE HERE TO EDIT THE PADDING
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(120.0), //EDIT HERE AFTER BORDER-RADIUS TO CHANGE HOW ROUNDED THE IMAGE IS
                child: Image.asset(
                  'assets/images/blue_jay.jpg', //EDIT HERE TO CHANGE THE LAUNCH PAGE IMAGE/WIDTH/HEIGHT
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 100),
              //EDIT THIS TO CHANGE SPACE BETWEEN BUTTONS AND IMAGE
              ElevatedButton(
                onPressed: (){
                  Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const Authentication_Page(
                              title: 'Login')
                      )
                  );
                },
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18, //EDIT THIS TO CHANGE FONT SIZE OF LOGIN BUTTON
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size(250, 50), //EDIT THIS TO CHANGE BUTTON SIZE
                ),
              ),
              const SizedBox(height: 50),
              //EDIT THIS TO CHANGE SPACE BETWEEN BUTTONS AND IMAGE
              ElevatedButton( //Sign UP Button
                onPressed: (){
                  Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const Authentication_Page(
                              title: 'Sign Up')
                      )
                  );
                },
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18, //EDIT THIS TO CHANGE FONT SIZE OF LOGIN BUTTON
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size(250, 50), //EDIT THIS TO CHANGE BUTTON SIZE
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

