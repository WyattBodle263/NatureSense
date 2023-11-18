import 'package:test_project/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:test_project/screens/change_username.dart';
import 'launch_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'blocked_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AuthService authService = AuthService();
  final databaseReference = FirebaseDatabase.instance.ref();
  late FirebaseAuth _auth;
  bool isLoading = true;

  //Variables for profile settings
  String? username;
  int? selectedProfilePic = null;
  String? profilePicURL = null;
  TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserData();

  }

  //Populate the textfields with the current data
  void loadUserData()  async {
    _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;
    if (user != null) {
      //If user exists
      DatabaseReference userReference =
      databaseReference.child('users').child(user.uid);
      await userReference.onValue.listen((event) {
        final dataSnapshot = event.snapshot;
        final userData = dataSnapshot.value as Map<dynamic, dynamic>?;

        if (userData != null) {
          setState(() {
            username = userData['username'] as String?;
            selectedProfilePic = userData['selectedProfilePic'] as int? ?? 1;
            profilePicURL = userData['profilePicURL'] as String? ??
                'assets/images/profile_pictures/avatar1.png';
            _usernameController.text = username ?? '';
            isLoading = false;
          });
        }
      });
    }
  }

  //Function to save user data
  void saveUserData() async {
    _auth = FirebaseAuth.instance;
    final profanityFiler = ProfanityFilter();
    final user = _auth.currentUser;

    //If post passes all checks save data
    if (user != null && !profanityFiler.hasProfanity(username!)) {
      databaseReference.child('users').child(user.uid).set({
        'username': username,
        'selectedProfilePic': selectedProfilePic,
        'profilePicURL': profilePicURL,
      });
    }
  }

  void showProfilePicSelection() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Profile Picture'),
            content: Wrap(
              alignment: WrapAlignment
                  .center, //CHANGE HERE TO ADJUST SPACING AND CENTERING
              spacing: 10,
              children: List.generate(10, (index) {
                //IF OUT OF BOUNDS ERROR CHANGE TO 9
                final profilePicNumber = index + 1;
                final imagePath =
                    'assets/images/profile_pictures/avatar$profilePicNumber.png';
                return GestureDetector(
                  onTap: () {
                    selectProfilePic(profilePicNumber);
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    backgroundImage: AssetImage(imagePath),
                    radius:
                    25, //CHANGE IF YOU WANT BIGGER OR SMALLER PROFILE PIC
                    backgroundColor: selectedProfilePic == profilePicNumber
                        ? Colors.blue
                        : Colors.transparent,
                  ),
                );
              }),
            ),
          );
        }
    );
  }

  void selectProfilePic(int profilePicNumber) {
    if (profilePicNumber >= 1 && profilePicNumber <= 10) {
      //CHANGE NUMBER BASED ON HOW MANY IMAGES
      setState(() {
        selectedProfilePic = profilePicNumber; //Sets the profile pic to number
        profilePicURL =
        'assets/images/profile_pictures/avatar$profilePicNumber.png';
        saveUserData();
      });
    }
  }

  void deleteUserAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      //Delete account logic
      try {
        _auth = FirebaseAuth.instance;
        final user = _auth.currentUser;
        if (user != null) {
          //Delete from firebase
          await user.delete();
          //Delete token from phone storage
          authService.logout();
          //Take me to launch page
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LaunchPage(title: 'Login / Sign Up'),
            ),
          );
        }
      } catch (error) {
        print(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        automaticallyImplyLeading: false,
        title: const Text('Profile Settings'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          :Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 20),
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: showProfilePicSelection,
                  child: CircleAvatar(
                    backgroundImage:
                    AssetImage(profilePicURL!) as ImageProvider<Object>?,
                    radius: 50,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Align(
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                SizedBox(width: 20),
                Text(
                  '$username',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Divider(color: Colors.black, thickness: 0.5),
          ListView(
            shrinkWrap: true,
            children: [
              Container(
                height: 60.0,
                child: ListTile(
                  leading: Icon(Icons.accessibility),
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Username'),
                  onTap: () {
                    String? userRef;
                    _auth = FirebaseAuth.instance;
                    final user = _auth.currentUser;
                    if (user != null) {
                      userRef = user.uid;
                    }
                    Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChangeUser(username: username,),
                        )
                    );
                  },
                ),
              ),
              Divider(color: Colors.black, thickness: 0.5),
              Container(
                height: 60.0,
                child: ListTile(
                  leading: Icon(Icons.block),
                  trailing: Icon(Icons.arrow_forward_ios),
                  title: Text('Blocked Users'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => BlockedUsers()
                      ),
                    );
                  },
                ),
              ),
              Divider(color: Colors.black, thickness: 0.5),
              Container(
                height: 60.0,
                child: ListTile(
                  leading: Icon(Icons.transit_enterexit),
                  title: Text('Log Out'),
                  onTap: () {
                    authService.logout();
                    Navigator.of(context).pop();
                  },
                ),
              ),
              Divider(color: Colors.black, thickness: 0.5),
              Container(
                height: 60.0,
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete Account', style: TextStyle(color: Colors.red)),
                  onTap: () => deleteUserAccount(),
                ),
              ),
              Divider(color: Colors.black, thickness: 0.5),
            ],
          ),
        ],
      ),
    );
  }
}

