import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../home/data/models/property_model.dart';

class PropertyFirestoreService {
  static final PropertyFirestoreService _instance = PropertyFirestoreService._internal();
  factory PropertyFirestoreService() => _instance;
  PropertyFirestoreService._internal();

  final CollectionReference _propertiesCollection =
      FirebaseFirestore.instance.collection('properties');
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// Create a new property document in Firestore
  Future<String> createProperty({
    required PropertyModel property,
    List<File> localImages = const [],
  }) async {
    try {
      final docRef = _propertiesCollection.doc();
      final List<String> finalImages = List.from(property.images);

      // Process local images (convert to base64 data URI if valid file, or retain paths)
      for (final file in localImages) {
        if (await file.exists()) {
          try {
            final bytes = await file.readAsBytes();
            if (bytes.lengthInBytes <= 1048576) { // under 1MB
              final base64String = base64Encode(bytes);
              final ext = file.path.split('.').last.toLowerCase();
              final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
              finalImages.add('data:$mimeType;base64,$base64String');
            } else {
              // File is large, save path
              finalImages.add(file.path);
            }
          } catch (e) {
            debugPrint('Error reading image file: $e');
            finalImages.add(file.path);
          }
        }
      }

      // Default fallback thumbnail if no image provided
      if (finalImages.isEmpty) {
        finalImages.add('https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg');
      }

      final propertyWithImages = property.copyWith(
        id: docRef.id,
        images: finalImages,
      );

      await docRef.set(propertyWithImages.toMap());
      debugPrint('✅ Property created in Firestore: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating property in Firestore: $e');
      rethrow;
    }
  }

  /// Stream all active properties for HomeScreen / FindHomeScreen
  Stream<List<PropertyModel>> streamAllProperties() {
    return _propertiesCollection
        .orderBy('postDate', descending: true)
        .snapshots()
        .map((snapshot) {
      final List<PropertyModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            list.add(PropertyModel.fromMap(data, doc.id));
          } else if (data is Map) {
            list.add(PropertyModel.fromMap(Map<String, dynamic>.from(data), doc.id));
          }
        } catch (e) {
          debugPrint('Error parsing property doc ${doc.id}: $e');
        }
      }
      return list;
    });
  }

  /// Stream properties owned by a specific house owner
  Stream<List<PropertyModel>> streamOwnerProperties(String ownerId, {String? ownerEmail}) {
    if (ownerId.isEmpty && (ownerEmail == null || ownerEmail.isEmpty)) {
      return streamAllProperties();
    }

    Query query = _propertiesCollection;
    if (ownerId.isNotEmpty) {
      query = query.where('ownerId', isEqualTo: ownerId);
    } else if (ownerEmail != null && ownerEmail.isNotEmpty) {
      query = query.where('ownerEmail', isEqualTo: ownerEmail);
    }

    return query.snapshots().map((snapshot) {
      final List<PropertyModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            list.add(PropertyModel.fromMap(data, doc.id));
          } else if (data is Map) {
            list.add(PropertyModel.fromMap(Map<String, dynamic>.from(data), doc.id));
          }
        } catch (e) {
          debugPrint('Error parsing property doc ${doc.id}: $e');
        }
      }

      list.sort((a, b) => b.postDate.compareTo(a.postDate));
      return list;
    });
  }

  /// Update an existing property in Firestore
  Future<void> updateProperty(PropertyModel property) async {
    try {
      await _propertiesCollection.doc(property.id).set(
            property.toMap(),
            SetOptions(merge: true),
          );
      debugPrint('✅ Property updated in Firestore: ${property.id}');
    } catch (e) {
      debugPrint('❌ Error updating property: $e');
      rethrow;
    }
  }

  /// Delete a property from Firestore
  Future<void> deleteProperty(String propertyId) async {
    try {
      await _propertiesCollection.doc(propertyId).delete();
      debugPrint('✅ Property deleted from Firestore: $propertyId');
    } catch (e) {
      debugPrint('❌ Error deleting property: $e');
      rethrow;
    }
  }

  /// Toggle property favorite status in user's wishlist sub-collection
  Future<bool> toggleWishlist(String userId, String propertyId) async {
    if (userId.isEmpty || propertyId.isEmpty) return false;
    try {
      final wishlistDoc = _usersCollection
          .doc(userId)
          .collection('wishlist')
          .doc(propertyId);

      final snapshot = await wishlistDoc.get();
      if (snapshot.exists) {
        await wishlistDoc.delete();
        return false; // Removed
      } else {
        await wishlistDoc.set({
          'propertyId': propertyId,
          'savedAt': FieldValue.serverTimestamp(),
        });
        return true; // Added
      }
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
      return false;
    }
  }

  /// Stream list of favorite property IDs for a user
  Stream<List<String>> streamWishlistPropertyIds(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }
    return _usersCollection
        .doc(userId)
        .collection('wishlist')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }
}

