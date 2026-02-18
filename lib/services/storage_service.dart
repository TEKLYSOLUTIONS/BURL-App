import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';

/// Service for handling file uploads to Firebase Storage
class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  /// [source] - ImageSource.gallery or ImageSource.camera
  static Future<XFile?> pickImage({
    required ImageSource source,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Compress image file
  /// Note: Compression is skipped on Windows/macOS/Linux as flutter_image_compress
  /// doesn't fully support desktop platforms
  static Future<File?> compressImage(File file) async {
    // Skip compression on desktop platforms where it's not fully supported
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      debugPrint('⚠️ Image compression skipped on desktop platform');
      return null;
    }

    try {
      final filePath = file.absolute.path;
      
      // Check if file exists
      if (!await file.exists()) {
        debugPrint('⚠️ Source file does not exist: $filePath');
        return null;
      }

      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      final splitPath = filePath.substring(0, lastIndex);
      final outPath = "${splitPath}_compressed.jpg";

      var result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
      );

      if (result != null) {
        debugPrint('✅ Image compressed successfully');
        return File(result.path);
      }
      
      debugPrint('⚠️ Compression returned null');
      return null;
    } catch (e) {
      debugPrint('❌ Error compressing image: $e');
      return null;
    }
  }

  /// Upload profile picture to Firebase Storage
  /// [userId] - The user's ID for organizing files
  /// [imageFile] - The image file to upload
  /// Returns the download URL of the uploaded image
  static Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Verify file exists before processing
      if (!await imageFile.exists()) {
        throw Exception('Source file does not exist at path: ${imageFile.path}');
      }

      // Try to compress image (will be skipped on desktop platforms)
      File fileToUpload = imageFile;
      final compressedFile = await compressImage(imageFile);
      if (compressedFile != null && await compressedFile.exists()) {
        fileToUpload = compressedFile;
      }

      // Create a unique file name
      final String extension = fileToUpload.path.substring(fileToUpload.path.lastIndexOf('.'));
      final String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}$extension';

      debugPrint('📤 Uploading file: ${fileToUpload.path}');

      // Create reference to Firebase Storage
      final Reference ref =
          _storage.ref().child('profile_pictures').child(fileName);

      // Upload file
      final UploadTask uploadTask = ref.putFile(
        fileToUpload,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Profile picture uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading profile picture: $e');
      rethrow;
    }
  }

  /// Delete a file from Firebase Storage by URL
  static Future<void> deleteFileByUrl(String fileUrl) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      debugPrint('✅ File deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting file: $e');
      // Don't rethrow as file might not exist
    }
  }

  /// Upload any file to Firebase Storage
  /// [folderPath] - Folder path in storage (e.g., 'documents', 'videos')
  /// [fileName] - Name of the file
  /// [file] - The file to upload
  static Future<String> uploadFile({
    required String folderPath,
    required String fileName,
    required File file,
  }) async {
    try {
      final Reference ref = _storage.ref().child(folderPath).child(fileName);

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// Show bottom sheet to select image source
  static Future<XFile?> showImageSourceSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose Photo Source',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.blue.shade700,
                  ),
                ),
                title: Text(
                  'Camera',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Take a new photo',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Colors.purple.shade700,
                  ),
                ),
                title: Text(
                  'Gallery',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Choose from gallery',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      return await pickImage(source: source);
    }
    return null;
  }
}
