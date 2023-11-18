import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

Map<dynamic, dynamic> animalMap = Map<dynamic, dynamic>();
Map<dynamic, dynamic> plantMap = Map<dynamic, dynamic>();

class PredictionPage extends StatefulWidget {
  const PredictionPage({
    Key? key,
    required this.title,
    required this.color,
    required this.model,
    required this.labels,
  }) : super(key: key);

  final String title;
  final Color color;
  final String model;
  final String labels;

  @override
  State<PredictionPage> createState() => PredictionPageState();
}

class PredictionPageState extends State<PredictionPage> {
  final imagePicker = ImagePicker();

  File? image;
  List? prediction = [];
  bool loading = false;


  List<CameraDescription>? cameras; //List out the cameras available
  CameraController? controller; //Controller for camera

  ImageClassification? objectDetection;

  @override
  void initState() {
    super.initState();
    loadCamera();
    objectDetection = ImageClassification(widget.model, widget.labels);
  }

  //Create the function to load the camera
  loadCamera() async {
    //Make sure cameras exist
    cameras = await availableCameras();
    if (cameras != null) {
      // True if camera exists
      controller = CameraController(cameras![0], ResolutionPreset.max);

      //Initialize the controller
      controller!.initialize().then((_) {
        //Check if camera is mounted (Started)
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    } else {
      //TODO: IF TIME ADD ERROR HANDLING FOR NO CAMERA
    }
  }

  //Function to take a picture
  Future<void> _captureImage() async {
    try {
      if (controller != null && controller!.value.isInitialized) {
        final XFile imageFile = await controller!.takePicture();
        final imagePath = imageFile.path;
        objectDetection!.analyseImage(imagePath).then((pred) => setState(() {
              prediction = pred;
            }));

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DisplayImagePage(
              name: prediction!.length >= 2
                  ? prediction![0]
                  : 'Name not available',
              confidence: prediction!.length >= 2
                  ? prediction![1]
                  : 'Confidence not available',
              imagePath: imagePath,
              title: widget.title,
            ),
          ),
        );
        objectDetection!.release();
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.title),
        backgroundColor: widget.color,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: controller == null
                      ? Center(child: Text("Loading Camera..."))
                      : !controller!.value.isInitialized
                          ? Center(
                              child: CircularProgressIndicator(),
                            )
                          : CameraPreview(controller!),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: loading
                  ? CircularProgressIndicator()
                  : FloatingActionButton(
                    onPressed: () async {
                      loading = true; // Set loading to true when starting image picking

                      setState(() {
                      });

                      final result = await imagePicker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (result != null) {
                        final imagePath = result.path;
                        objectDetection!.analyseImage(imagePath).then((pred) {
                          setState(() {
                            prediction = pred;
                            loading =
                                false; // Set loading to false when result is available
                          });

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DisplayImagePage(
                                name: prediction!.length >= 2
                                    ? prediction![0]
                                    : 'Name not available',
                                confidence: prediction!.length >= 2
                                    ? prediction![1]
                                    : 'Confidence not available',
                                imagePath: imagePath,
                                title: widget.title,
                              ),
                            ),
                          );
                          objectDetection!.release();
                        });
                      } else {
                        setState(() {
                          loading =
                              false; // Set loading to false when image picking is canceled
                        });
                      }
                    },
                    child: Icon(Icons.photo_library),
                    backgroundColor: widget.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: loading
          ? CircularProgressIndicator()
          : FloatingActionButton(
        onPressed: _captureImage,
        child: Icon(Icons.camera),
        backgroundColor: widget.color,
      ),
    );
  }
}

class DisplayImagePage extends StatefulWidget {
  final String name;
  final String confidence;
  final String imagePath;
  final String title;

  const DisplayImagePage(
      {required this.name,
      required this.confidence,
      required this.imagePath,
      required this.title});

  @override
  State<DisplayImagePage> createState() => _DisplayImagePageState();
}

class _DisplayImagePageState extends State<DisplayImagePage> {
  List<Map<String, dynamic>?> listOfJsonMap = [];
  String? description;
  String? advice;
  String? dangerous;
  String? risky;
  String? invasive;
  String? habitat;
  String? diet;

  Map<String, dynamic>? _animalDetails; // Store JSON data here
  DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  late FirebaseAuth _auth;

  @override
  void initState() {
    super.initState();
    getData();
    fetchData();
    updateHome(widget.name);
  }

  void saveMapData() {
    _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;

    //If post passes all checks save data
    // await _userRef.child('blockedUsers').push().set(userId);

    if (user != null) {
      databaseReference
          .child('users')
          .child(user.uid)
          .child('foundAnimals')
          .update(animalMap.cast<String, Object?>());

      databaseReference
          .child('users')
          .child(user.uid)
          .child('foundPlants')
          .update(plantMap.cast<String, Object?>());
    }
  }

  Future<void> getData() async{
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

    print(animalMap.values);
    setState(() {});
  }

  // Load the JSON data from a file (assuming your JSON file is in the assets folder)
  Future<String> loadJsonData() async {
    log("Loading Json Data...");
    if (widget.title == 'Animals') {
      return await DefaultAssetBundle.of(context)
          .loadString('assets/details/animals.json');
    } else {
      return await DefaultAssetBundle.of(context)
          .loadString('assets/details/plants.json');
    }
  }

// Parse the JSON data
  Future<List<dynamic>> parseJson() async {
    log("Parsing Data...");
    String jsonString = await loadJsonData();
    return json.decode(jsonString);
  }

  Future<Map<String, dynamic>?> getDataForAnimal(String animalName) async {
    log("Getting Json Data...");

    List<dynamic> jsonData = await parseJson();

    // Iterate through the JSON array to find the animal with the specified name
    for (var animal in jsonData) {
      if (animal['name'] == animalName) {
        return animal;
      }
    }

    // If the animal with the specified name is not found
    log("Returning Null");
    return null;
  }

  Future<void> fetchData() async {
    if (widget.name != null) {
      String? thisName = widget.name;
      Map<String, dynamic>? animalData = await getDataForAnimal(thisName!);
      setState(() {
        listOfJsonMap.add(animalData);
      });
    }
  }

  Future<void> updateHome(String name) async {
    // Ensure that getData is completed before proceeding
    await getData();

    int valueToAdd = 0;

    if (widget.title == 'Plant') {
      if (plantMap.containsKey(name)) {
        valueToAdd = plantMap[name];
      }
      plantMap.addAll({name: valueToAdd += 1});
    } else {
      print(animalMap.values);
      if (animalMap.containsKey(name)) {
        valueToAdd = animalMap[name];
      }
      print("VALUE TO ADD: ${valueToAdd + 1}");
      animalMap.addAll({name: valueToAdd += 1});
    }

    saveMapData();
    await fetchData();
  }


  Widget buildAnimalProperty(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 4), // Add some spacing between title and value
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final confidenceValue = double.tryParse(widget.confidence ?? '0.0') ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: (widget.title == 'Animals')
            ? Text("Animal Details")
            : Text("Plant Details"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
      ),
      body: listOfJsonMap.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Text("Object was not found"),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(15, 50, 15, 15),
              child: ListView(
                children: [
                  Container(child: Image.file(File(widget.imagePath))),
                  SizedBox(
                    height: 15,
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: 1,
                    itemBuilder: (BuildContext context, int index) {
                      String recLabel = widget.name;
                      String firstUpper = recLabel[0].toUpperCase();
                      recLabel = recLabel.substring(1, recLabel.length);
                      recLabel = firstUpper + recLabel;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  recLabel,
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 20.0,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: SizedBox(
                                  height: 32.0,
                                  child: Stack(
                                    children: [
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                            child: LinearProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.redAccent,
                                              ),
                                              value: confidenceValue / 100,
                                              backgroundColor: Colors.redAccent
                                                  .withOpacity(0.2),
                                              minHeight: 50,
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: Text(
                                                  '${(confidenceValue).toStringAsFixed(0)} %',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 20.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          buildAnimalProperty(
                              'Description',
                              listOfJsonMap[index]?['description'] ??
                                  'Description not available'),
                          SizedBox(height: 15),
                          buildAnimalProperty(
                              'Advice',
                              listOfJsonMap[index]?['advice'] ??
                                  'Advice not available'),
                          SizedBox(height: 15),
                          buildAnimalProperty(
                              'Dangerous',
                              listOfJsonMap[index]?['dangerous'] ??
                                  'Dangerous status not available'),
                          SizedBox(height: 15),
                          buildAnimalProperty(
                              'Habitat',
                              listOfJsonMap[index]?['habitat'] ??
                                  'Habitat information not available'),
                          SizedBox(height: 15),
                          buildAnimalProperty(
                              'Invasive',
                              listOfJsonMap[index]?['invasive'] != null
                                  ? (listOfJsonMap[index]!['invasive'] as bool
                                      ? 'Invasive'
                                      : 'Not Invasive')
                                  : 'Invasive information not available'),
                          SizedBox(height: 15),
                          buildAnimalProperty(
                              'Risky',
                              listOfJsonMap[index]?['risky'] != null
                                  ? (listOfJsonMap[index]!['risky'] as bool
                                      ? 'Risky, proceed with caution'
                                      : 'Not Risky')
                                  : 'Risky information not available'),
                          SizedBox(height: 15),
                          buildAnimalProperty(
                              'Diet',
                              listOfJsonMap[index]?['diet'] ??
                                  'Diet information not available'),
                        ],
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                  ),
                ],
              ),
            ),
    );
  }
}

class ImageClassification {
  final String _modelPath;
  final String _labelPath;

  Interpreter? _interpreter;
  List<String>? _labels;
  Tensor? inputTensor;
  Tensor? outputTensor;

  ImageClassification(this._modelPath, this._labelPath) {
    _loadModel();
    _loadLabels();
    log('Done.');
  }

  //Disposes the imageclassification
  void release() {
    if (_interpreter != null) {
      _interpreter!.close();
    }
  }

  // Load model
  Future<void> _loadModel() async {
    final options = InterpreterOptions();

    // Load model from assets
    _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
    // Get tensor input shape [1, 224, 224, 3]
    inputTensor = _interpreter!.getInputTensors().first;
    // Get tensor output shape [1, 3]
    outputTensor = _interpreter!.getOutputTensors().first;
  }

  Future<void> _loadLabels() async {
    log('Loading labels...');
    final labelsRaw = await rootBundle.loadString(_labelPath);
    _labels = labelsRaw.split('\n');
  }

  Future<List> analyseImage(String imagePath) async {
    log('Analysing image...');
    // Reading image bytes from file
    final imageData = File(imagePath).readAsBytesSync();

    // Decoding image
    final image = img.decodeImage(imageData);

    // Resizing image fpr model, [224, 224]
    final imageInput = img.copyResize(
      image!,
      width: inputTensor!.shape[1],
      height: inputTensor!.shape[2],
    );

    // Creating matrix representation, [224, 224, 3]
    final imageMatrix = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );

    List pred = await _runInference(imageMatrix);

    log('Done.');

    return [pred[0], pred[1]];
  }

  Future<List> _runInference(
    List<List<List<num>>> imageMatrix,
  ) async {
    log('Running inference...');

    // Tensor input [1, 224, 224, 3]
    final input = [imageMatrix];
    // Tensor output [1, 3]
    final output = [List.filled(outputTensor!.shape[1], 0)];

    // Run inference
    _interpreter!.run(input, output);

    // Get first output tensor
    final result = output.first;
    List pred = findIndexOfMax(result);
    String label = _labels![pred[0]].trim();
    log(label);
    String confidence = (pred[1] / 255 * 100).toStringAsFixed(2);
    log('confidence : $confidence');
    return [label, confidence];
  }

  List findIndexOfMax(List numbers) {
    if (numbers.isEmpty) {
      // Handle the case where the list is empty, if needed.
      return []; // Return -1 or another appropriate value.
    }

    int maxIndex = 0; // Start with the first element as the maximum.
    var maxValue = numbers[0]; // Initialize the maximum value.

    for (int i = 1; i < numbers.length; i++) {
      if (numbers[i] > maxValue) {
        // If a larger value is found, update the maximum value and index.
        maxValue = numbers[i];
        maxIndex = i;
      }
    }

    return [maxIndex, maxValue];
  }
}
