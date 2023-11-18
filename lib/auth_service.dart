import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

//Handles all of login storage
class AuthService{
  //Initialize service for login
  final FirebaseAuth auth = FirebaseAuth.instance;
  final storage = const FlutterSecureStorage();

  //Function to store token for login
  Future<void> storeTokenAndData(UserCredential userCredential) async{
    String? token;
    IdTokenResult? tokenResult = await userCredential.user!.getIdTokenResult();
    token = tokenResult.token;

    if(token != null){
      await storage.write(key: "token", value: token);
      await storage.write(key: "userCredential", value: userCredential.toString());
    }
    print("Token save attempted");
  }
  //Function to get token
  Future<String?> getToken() async {
    return await storage.read(key: "token");
  }
  //Logout function
  Future<void> logout() async {
    try {
      //Signs out from firebase id
      await auth.signOut();
      //Remove sign in token
      await storage.delete(key: "token");
      await storage.delete(key: "userCredential"); //:TODO Remove line if logout error
    } catch (e){
      print(e);
    }
  }
    Future<String?> getUserUID() async{
    final User? user = auth.currentUser;
    return user?.uid;
    }
}