import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Upload profile picture to Firebase Storage
  Future<String?> uploadProfilePicture({
    required String uid,
    required File imageFile,
  }) async {
    try {
      final Reference storageRef = _storage.ref().child('profile_pictures/$uid.jpg');
      
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  // Show image source selection dialog
  Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151A1E),
          title: Text(
            'Select Image Source',
            style: Theme.of(dialogContext).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF19D99F)),
                title: Text('Gallery', style: Theme.of(dialogContext).textTheme.headlineSmall),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  final File? image = await pickImageFromGallery();
                  if (context.mounted) {
                    Navigator.pop(context, image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF19D99F)),
                title: Text('Camera', style: Theme.of(dialogContext).textTheme.headlineSmall),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  final File? image = await pickImageFromCamera();
                  if (context.mounted) {
                    Navigator.pop(context, image);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF19D99F))),
            ),
          ],
        );
      },
    );
  }
}
