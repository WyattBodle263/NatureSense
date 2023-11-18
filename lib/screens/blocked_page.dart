import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockedUsers extends StatefulWidget{
  @override
  _BlockedUsersState createState() => _BlockedUsersState();
}

class _BlockedUsersState extends State<BlockedUsers>{
  //List to hold blocked user UID and one to hold their literal usernames
  Set<String> _blockedUsers = {};
  List<String> _blockedUsernames = [];

  //Create firebase database and auth calls
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //Address to users in our database
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('users');

  @override
  void initState(){
    super.initState();
    _blockedUsernames.clear();
    _blockedUsers.clear();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    //Create an event to get a snapshot for the data
    final blockedUsersEvent = await _userRef.child(_auth.currentUser!.uid).child('blockedUsers').once();
    final blockedUsersSnapshot = blockedUsersEvent.snapshot;
    final blockedUsersData = blockedUsersSnapshot.value;
    List<String> blockedUserIds = [];
    if(blockedUsersData is Map<dynamic, dynamic>) {
      blockedUserIds = blockedUsersData.values.whereType<String>()
          .toList();
      setState(() {
        _blockedUsers = Set.from(blockedUserIds);
        //Clears username from screen
        _blockedUsernames.clear();
      });
    }else{
      setState(() {
        //If theres no blocked users clear the screen
        _blockedUsernames.clear();
      });
    }
    //Converting each blocked users UID to a readable username
    for(final userUID in _blockedUsers){
      final blockedUsersEvent = await _userRef.child(userUID).once();
      final usernameSnapshot = blockedUsersEvent.snapshot;
      final usernameData = usernameSnapshot.value;

      if(usernameData is Map<dynamic, dynamic> && usernameData.containsKey('username') && usernameData['username'] is String){
        final usernames = usernameData['username'];
        setState(() {
          _blockedUsernames.add(usernames);
        });
      }
    }
  }
  //Method to unblock a user
  Future<void> _unblockUser(String userID) async{
    try{
      final userList = _blockedUsers.toList();
      final index = _blockedUsernames.indexOf(userID);

      if(index != -1){
        final user = _auth.currentUser!.uid;
        final blockedUserEvent = await _userRef.child(user).child('blockedUsers').once();
        final blockedSnapshot = blockedUserEvent.snapshot;
        final blockedData = blockedSnapshot.value;

        if(blockedData is Map<dynamic, dynamic>){
          for(final key in blockedData.keys){
            final value = blockedData[key];
            if(value == userList[index]){
              //Delete username
              await _userRef.child(user).child('blockedUsers').child(key).remove();
            }
          }
        }
        _blockedUsernames.clear();
        _blockedUsers.clear();
        await _loadBlockedUsers();
      }else{
        print("User not found to delete");
      }
    } catch(e){
      print(e);
    }
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Users'),
      ),
      body: ListView(
        children: _blockedUsernames.map((userId) => ListTile(
          title: Text(userId),
          trailing: ElevatedButton(
            onPressed: (){
              _unblockUser(userId);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Unblock'),
                Icon(Icons.delete)
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}