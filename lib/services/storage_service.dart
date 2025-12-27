import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;

/// Service for managing file storage operations with Firebase Storage
class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  factory StorageService() => _instance;
  StorageService._internal();

  final _logger = Logger('StorageService');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = Uuid();

  /// Upload a profile image for a user
  /// Returns the download URL of the uploaded image
  Future<String> uploadProfileImage(String userId, dynamic imageFile) async {
    try {
      _logger.info('Uploading profile image for user: $userId');
      
      // Generate a unique filename
      final String fileName = '${_uuid.v4()}.jpg';
      final String storagePath = 'profile_images/$userId/$fileName';
      
      // Create a reference to the file location
      final Reference ref = _storage.ref().child(storagePath);
      
      // Handle different image file types based on platform
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // For web platform, imageFile is likely a Uint8List from Image.memory
        if (imageFile is Uint8List) {
          uploadTask = ref.putData(
            imageFile,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          throw Exception('Unsupported image format for web');
        }
      } else {
        // For mobile/desktop platforms, imageFile is likely a File
        if (imageFile is File) {
          uploadTask = ref.putFile(imageFile);
        } else {
          throw Exception('Unsupported image format for mobile/desktop');
        }
      }
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        _logger.info('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      _logger.info('Profile image uploaded successfully. URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      _logger.severe('Error uploading profile image: $e');
      rethrow;
    }
  }

  /// Download a profile image from a URL
  /// For web, this returns a Uint8List
  /// For mobile/desktop, this saves to a file and returns the File
  Future<dynamic> downloadProfileImage(String imageUrl, {String? localPath}) async {
    try {
      _logger.info('Downloading profile image from: $imageUrl');
      
      if (kIsWeb) {
        // For web, download as bytes
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          throw Exception('Failed to download image: ${response.statusCode}');
        }
      } else {
        // For mobile/desktop, save to file
        if (localPath == null) {
          throw Exception('Local path is required for mobile/desktop platforms');
        }
        
        final file = File(localPath);
        final ref = _storage.refFromURL(imageUrl);
        await ref.writeToFile(file);
        return file;
      }
    } catch (e) {
      _logger.severe('Error downloading profile image: $e');
      rethrow;
    }
  }

  /// Delete a profile image from storage
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      _logger.info('Deleting profile image: $imageUrl');
      
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      
      _logger.info('Profile image deleted successfully');
    } catch (e) {
      _logger.severe('Error deleting profile image: $e');
      rethrow;
    }
  }

  /// Get all profile images for a user
  Future<List<String>> getUserProfileImages(String userId) async {
    try {
      _logger.info('Fetching profile images for user: $userId');
      
      final ListResult result = await _storage.ref('profile_images/$userId').listAll();
      
      List<String> imageUrls = [];
      for (var item in result.items) {
        final String url = await item.getDownloadURL();
        imageUrls.add(url);
      }
      
      _logger.info('Found ${imageUrls.length} profile images for user: $userId');
      return imageUrls;
    } catch (e) {
      _logger.severe('Error fetching profile images: $e');
      return [];
    }
  }
}
