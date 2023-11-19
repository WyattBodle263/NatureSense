import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'predictions.dart';

class PlantPredictionPage extends StatefulWidget {
  const PlantPredictionPage({
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
  State<PlantPredictionPage> createState() => PlantPredictionPageState();
}

class PlantPredictionPageState extends State<PlantPredictionPage> {
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

  void resetObjectDetection() {
    objectDetection?.release(); // Release resources of the existing objectDetection instance
    objectDetection = ImageClassification(widget.model, widget.labels); // Create a new instance
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
      print("No camera found");
      //TODO: IF TIME ADD ERROR HANDLING FOR NO CAMERA
    }
  }
  //Function to take a picture
  Future<void> _captureImage() async {
    print(widget.model);
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
        resetObjectDetection();
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
                      ? Center(
                      child: Text("Loading Camera..."))
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
                      setState(() {
                        loading = true; // Set loading to true when starting image picking
                      });

                      final result = await imagePicker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (result != null) {
                        final imagePath = result.path;
                        objectDetection!
                            .analyseImage(imagePath)
                            .then((pred) {
                          setState(() {
                            prediction = pred;
                            loading = false; // Set loading to false when result is available
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
                          resetObjectDetection();
                        });
                      } else {
                        setState(() {
                          loading = false; // Set loading to false when image picking is canceled
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

