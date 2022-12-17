import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class AddItem extends StatefulWidget {
  const AddItem({super.key});
  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  TextEditingController _controllerName = TextEditingController();
  GlobalKey<FormState> key = GlobalKey();

  final CollectionReference _reference =
      FirebaseFirestore.instance.collection('my_shop_list');
  String imageUrl = "";
  File? image;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
            key: key,
            child: Column(
              children: [
                TextFormField(
                  controller: _controllerName,
                  decoration:
                      InputDecoration(hintText: 'Enter the name of the item'),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the item name';
                    }

                    return null;
                  },
                ),
                IconButton(
                    onPressed: () async {
                      ImagePicker imagepicker = ImagePicker();
                      XFile? file = await imagepicker.pickImage(
                          source: ImageSource.gallery);
                      print('${file?.path}');

                      if (file == null) return;
                      String uniqueName =
                          DateTime.now().millisecondsSinceEpoch.toString();

                      Reference referenceRoot = FirebaseStorage.instance.ref();
                      Reference referenceDirImage =
                          referenceRoot.child('images');

                      Reference referenceUploadImage =
                          referenceDirImage.child(uniqueName);
                      try {
                        CroppedFile? imagecrop = await ImageCropper()
                            .cropImage(sourcePath: file.path);
                        if (imagecrop == null) return null;

                        await referenceUploadImage
                            .putFile(File(imagecrop.path));
                        setState(() {
                          image = File(imagecrop.path);
                          // Navigator.of(context).pop();
                        });

                        imageUrl = await referenceUploadImage.getDownloadURL();
                      } catch (error) {}
                    },
                    icon: Icon(Icons.camera_alt)),
                Center(
                  child: Container(
                    height: 200.0,
                    width: 200.0,
                    decoration: BoxDecoration(color: Colors.grey),
                    child: image == null
                        ? const Text("no image selected")
                        : CircleAvatar(
                            backgroundImage: FileImage(image!),
                            radius: 200.0,
                          ),
                  ),
                ),
                ElevatedButton(
                    onPressed: () async {
                      if (imageUrl == "") {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("please upload an images")));
                        return;
                      }
                      if (key.currentState!.validate()) {
                        String itemName = _controllerName.text;

                        Map<String, String> dataToSend = {
                          'name': itemName,
                          'image': imageUrl
                        };

                        _reference.add(dataToSend);
                      }
                    },
                    child: Text("submit"))
              ],
            )),
      ),
    );
  }
}
