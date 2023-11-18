import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
List<String> list = <String>['Animals', 'Plants'];

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String dropDownValue = list.first;
  DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  Map<dynamic, dynamic> animalMap = Map<dynamic, dynamic>();
  Map<dynamic, dynamic> plantMap = Map<dynamic, dynamic>();
  late FirebaseAuth _auth;

  @override
  void initState() {
    super.initState();
    print("Should be getting data");
    getData();
    setState(() {});
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    getData();
  }

  void getData() async{
    print("GETTING DATA FOR THE HOME PAGE");
    _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;

    //Populate animal map
    final animalUsersEvent = await databaseReference.child('users').child(user!.uid).child('foundAnimals').once();
    final animalUserSnapshot = animalUsersEvent.snapshot;
    final animalUsersData = animalUserSnapshot.value;

    if(animalUsersData is Map<dynamic, dynamic>){
      animalMap = animalUsersData;
    }
    //Populate plant map
    final plantUsersEvent = await databaseReference.child('users').child(user!.uid).child('foundPlants').once();
    final plantUserSnapshot = plantUsersEvent.snapshot;
    final plantUsersData = plantUserSnapshot.value;

    if(plantUsersData is Map<dynamic, dynamic>){
      plantMap = plantUsersData;
    }
    setState(() {});
  }

  bool displayAnimalMap = true;

  //Function to change map
  void toggleMap() {
    setState(() {
      if (dropDownValue == 'Animals') {
        displayAnimalMap = true;
      } else {
        displayAnimalMap = false;
      }
    });
    print("Animal Map size: ${animalMap.length}");
    print("Plant Map size: ${plantMap.length}");


  }

  @override
  Widget build(BuildContext context) {
    Map<dynamic, dynamic> selectedMap = displayAnimalMap ? animalMap : plantMap;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: false,
        title: Text('Home'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 20),
              DropdownButton<String>(
                value: dropDownValue,
                items: list.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    dropDownValue = value!;
                    toggleMap();
                  });
                },
              ),
            ],
          ),
          selectedMap.length == 0
              ? Column(
                  children: [
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            "Discovered $dropDownValue will appear here when found"),
                      ],
                    )
                  ],
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: selectedMap.length,
                    itemBuilder: (context, index) {
                      var key = selectedMap.keys.elementAt(index);
                      var value = selectedMap.values.elementAt(index);
                      String keyUpper = key.toString();
                      String upperFirst = keyUpper[0].toUpperCase();
                      keyUpper = keyUpper.substring(1, keyUpper.length);
                      keyUpper = upperFirst + keyUpper;

                      return ListTile(
                        title: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage:
                                  AssetImage('assets/images/animal_plant_photos/$key.jpg')
                                      as ImageProvider<Object>?,
                              radius: 25,
                            ),
                            SizedBox(width: 10),
                            Text('$keyUpper : $value', style: TextStyle(
                              fontSize: 30,
                            ),),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
