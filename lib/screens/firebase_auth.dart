import 'package:flutter/material.dart';
//:TODO firebase auth imports
import 'package:test_project/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_project/screens/launch_page.dart';
import 'package:test_project/screens/bottom_nav.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:firebase_database/firebase_database.dart';

class Authentication_Page extends StatefulWidget{
  const Authentication_Page({Key? key, required this.title}) : super(key: key);

  final String title;
  @override
  Authentication_PageState createState() => Authentication_PageState();
}

class Authentication_PageState extends State<Authentication_Page> {
  late FirebaseAuth _auth;

  //Text controller for user and pass
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  //Set an empty string to hold errors
  String errorMessage = '';

  @override
  void initState(){
    super.initState();
  }


  AuthService authService = AuthService();

  //Function to save user data
  Future<bool> saveUserData() async {
    _auth = FirebaseAuth.instance;
    final profanityFilter = ProfanityFilter();
    final user = _auth.currentUser;
    final databaseReference = FirebaseDatabase.instance.ref();

    //If post passes all checks save data
    if(user != null && !profanityFilter.hasProfanity(_usernameController.text)) {
      databaseReference.child('users').child(user.uid).update({
        'username': _usernameController.text,
      });
      return true;
    }else{
      errorMessage = "Username contains profane language please change it and try again.";
      return false;
    }
  }

  //Method to login
  void _login(){
    setState(() {
      errorMessage = '';
    });

    //Create strings to hold username and pass
    String email = _emailController.text;
    String password = _passwordController.text;

    FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
    ).then((userCredential){
      authService.storeTokenAndData(userCredential);
      Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (context) => const BottomNav()),
      );
    }).catchError((error) {
      setState(() {
        errorMessage = 'Failed to sign in ${error.toString()}';
      });
    });
  }

  //Method to handle the navigation
  void _goBack(){
    Navigator.pop(context);
  }
  //Method for sign up
  void _signup(){

    setState(() {
      errorMessage = '';
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    //:TODO Add sign up methods
    FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password
    ).then((userCredential) async {
      Future<bool> usernameAllowed = saveUserData();

      if(await usernameAllowed) {
        authService.storeTokenAndData(userCredential);
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const BottomNav()),
        );
      }else{
        _auth = FirebaseAuth.instance;
        final user = _auth.currentUser;
        await user?.delete();
      }
    }).catchError((error) {
      setState(() {
        errorMessage = 'Failed to sign up ${error.toString()}';
      });
    });
  }

  //Disposes of textfield controller
  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          widget.title,
            style: TextStyle(
            color: Colors.white,
          ),
        ),
        //Button to pop the screen back to launch page
        leading: widget.title == "Login"
          ? null
            : IconButton(
            onPressed: _goBack,
            icon: Icon(Icons.arrow_back_ios_new)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.red,
              )
            ),
            TextField( //Email TEXTFIELD
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            if(widget.title != 'Login')
              const SizedBox(height: 16.0),
            if(widget.title != 'Login')
              TextField( //USERNAME TEXTFIELD
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
              ),
            const SizedBox(height: 16.0),
            TextField( //PASSWORD TEXTFIELD
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //LOGIN / SIGN UP BUTTON
                ElevatedButton(
                    onPressed: (){
                      //Check if the user wants to sign up or login
                      if(widget.title == 'Login'){
                        _login();
                      }else{
                        _signup();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      minimumSize: const Size(250,50), //EDIT THIS TO CHANGE BUTTON SIZE
                    ),
                    child: Text(
                      widget.title,
                      style: const TextStyle( //EDIT HERE TO CHANGE LOGIN BUTTON STYLE
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}


