import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:profanity_filter/profanity_filter.dart';
import "package:firebase_auth/firebase_auth.dart";


class ChangeUser extends StatefulWidget{
  const ChangeUser({Key? key, required this.username}) : super(key: key);

  final String? username;

  @override
  State<ChangeUser> createState() => _ChangeUserState();

}

class _ChangeUserState extends State<ChangeUser> {
  TextEditingController _usernameController = TextEditingController();

  final databaseReference = FirebaseDatabase.instance.ref();
  late FirebaseAuth _auth;

  //Function to save user data
  void saveUserData() async {
    String newUsername = _usernameController.text;

    _auth = FirebaseAuth.instance;
    final profanityFilter = ProfanityFilter();
    final user = _auth.currentUser;

    //If post passes all checks save data
    if (user != null && !profanityFilter.hasProfanity(newUsername!)) {
      databaseReference.child('users').child(user.uid).update({
        'username': newUsername,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Change Username"),
      ),
      body: Container(
        padding: new EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: "Username",
                labelText: "${widget.username}",
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                saveUserData();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                shape: BeveledRectangleBorder(),
              ),
              child: Text('Save'),
            ),
          ],
        ),
        ),

    );
  }
}