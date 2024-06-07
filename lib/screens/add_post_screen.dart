import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fasum_marcel/location_picker.dart';  // Sesuaikan dengan path file Anda

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  TextEditingController _postTextController = TextEditingController();
  String? _imageUrl;
  XFile? _image;
  final User? user = FirebaseAuth.instance.currentUser;
  String? _locationMessage;
  LatLng? _selectedLocation;

  Future<void> _getImageFromCamera() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = image;
      });

      if (!kIsWeb) {
        String? imageUrl = await _uploadImage(image);
        setState(() {
          _imageUrl = imageUrl;
        });
      } else {
        setState(() {
          _imageUrl = image.path;
        });
      }
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('post_images').child('${DateTime.now().toIso8601String()}.jpg');
      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _pickLocation() async {
    final pickedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPicker(),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
        _locationMessage = 'Latitude: ${pickedLocation.latitude}, Longitude: ${pickedLocation.longitude}';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
      _locationMessage = 'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Postingan'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _getImageFromCamera,
              child: Container(
                height: 200,
                color: Colors.grey[200],
                child: _image != null
                    ? kIsWeb
                    ? Image.network(
                  _imageUrl!,
                  fit: BoxFit.cover,
                )
                    : Image.file(
                  File(_image!.path),
                  fit: BoxFit.cover,
                )
                    : Icon(
                  Icons.camera_alt,
                  size: 100,
                  color: Colors.grey[400],
                ),
                alignment: Alignment.center,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _postTextController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Tulis postingan Anda di sini...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text(_locationMessage ?? 'Mengambil lokasi...'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickLocation,
              child: Text('Pilih Lokasi di Peta'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_postTextController.text.isNotEmpty && _image != null) {
                  if (_imageUrl == null) {
                    _imageUrl = await _uploadImage(_image!);
                  }
                  if (_imageUrl != null) {
                    FirebaseFirestore.instance.collection('posts').add({
                      'text': _postTextController.text,
                      'image_url': _imageUrl,
                      'timestamp': Timestamp.now(),
                      'username': user?.email ?? 'Anonim',
                      'userId': user?.uid,
                      'location': _selectedLocation != null ? GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude) : null,
                    }).then((_) {
                      Navigator.pop(context);
                    }).catchError((error) {
                      print('Error saving post: $error');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menyimpan postingan. Silakan coba lagi.'),
                        ),
                      );
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal mengunggah gambar. Silakan coba lagi.'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Silakan tulis postingan dan pilih gambar.'),
                    ),
                  );
                }
              },
              child: Text('Posting'),
            ),
          ],
        ),
      ),
    );
  }
}
