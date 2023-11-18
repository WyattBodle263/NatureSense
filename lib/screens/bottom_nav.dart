import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'predictions.dart';
import 'community.dart';
import 'package:test_project/screens/profile_page.dart';
import 'home.dart';
import 'plant_predictions.dart';
class BottomNav extends StatefulWidget{
  const BottomNav({Key? key}) : super(key: key);

  @override
  BottomNavState createState() => BottomNavState();
}

class BottomNavState extends State<BottomNav>{
  //Get rid of splash screen
  @override
  void initState(){
    super.initState();
    //Put code to run when state is initialized
    Future.delayed(Duration(milliseconds: 2000), () { //CHANGE VALUE HERE TO EDIT SPLASH SCREEN TIME
      //Remove Splash Screen
      FlutterNativeSplash.remove();
    });
  }

  //Create an index for which tab is in use 0 indexing means start at 0
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    //Animal 0
    HomeScreen(),
    PredictionPage(title: "Animals", color: Colors.red, model: "assets/models/animals.tflite", labels: "assets/labels/animals.txt"),
    PlantPredictionPage(title: "Plant", color: Colors.green, model: "assets/models/plants.tflite", labels: "assets/labels/plants.txt"),
    CommunityPage(title: "Community"),
    ProfilePage(title: 'Profile Settings'),
    //Plant 1
    //Community 2
    //Profile 3
  ];

  //Function for when we tap a different tab
  void _onTabTapped(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onTabTapped,
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget{
  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
}) : super (key: key);
  final int selectedIndex;
  final Function(int) onItemTapped;

  @override
  Widget build(BuildContext context){
    return Container(
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              size: 30,
            ),
            label: '',
            backgroundColor: Colors.orange,
          ),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.pets,
                size: 30,
              ),
            label: '',
            backgroundColor: Colors.red,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.spa,
              size: 30,
            ),
            label: '',
            backgroundColor: Colors.green,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.people_alt_rounded,
              size: 30,
            ),
            label: '',
            backgroundColor: Color(0xFF3A83D0),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              size: 30,
            ),
            label: '',
            backgroundColor: Color(0xFF3A83D0),
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Colors.black,
        onTap: onItemTapped,
      ),
    );
  }
}