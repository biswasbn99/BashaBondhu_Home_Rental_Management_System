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

      // Process local images
      for (final file in localImages) {
        if (await file.exists()) {
          try {
            final bytes = await file.readAsBytes();
            final base64String = base64Encode(bytes);
            final ext = file.path.split('.').last.toLowerCase();
            final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
            finalImages.add('data:$mimeType;base64,$base64String');
          } catch (e) {
            debugPrint('Error reading image file: $e');
          }
        }
      }

      final propertyWithImages = property.copyWith(
        id: docRef.id,
        images: finalImages,
      );

      await docRef.set(propertyWithImages.toMap());
      debugPrint('✅ Property created in Firestore: ${docRef.id} with ${finalImages.length} images');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating property in Firestore: $e');
      rethrow;
    }
  }

  /// Stream all active properties for HomeScreen / FindHomeScreen (only available by default)
  Stream<List<PropertyModel>> streamAllProperties({bool onlyAvailable = true}) {
    return _propertiesCollection
        .snapshots()
        .map((snapshot) {
      final List<PropertyModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final p = PropertyModel.fromMap(data, doc.id);
            if (!onlyAvailable || p.isAvailable) {
              list.add(p);
            }
          } else if (data is Map) {
            final p = PropertyModel.fromMap(Map<String, dynamic>.from(data), doc.id);
            if (!onlyAvailable || p.isAvailable) {
              list.add(p);
            }
          }
        } catch (e) {
          debugPrint('Error parsing property doc ${doc.id}: $e');
        }
      }
      list.sort((a, b) => b.postDate.compareTo(a.postDate));
      return list;
    });
  }

  /// Stream properties owned by a specific house owner
  Stream<List<PropertyModel>> streamOwnerProperties(String ownerId, {String? ownerEmail}) {
    return _propertiesCollection.snapshots().map((snapshot) {
      final List<PropertyModel> list = [];
      final String cleanId = ownerId.trim();
      final String cleanEmail = (ownerEmail ?? '').trim().toLowerCase();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final p = PropertyModel.fromMap(data, doc.id);
            final bool matchesId = cleanId.isNotEmpty && p.ownerId == cleanId;
            final bool matchesEmail = cleanEmail.isNotEmpty && p.ownerEmail.trim().toLowerCase() == cleanEmail;
            if (cleanId.isEmpty && cleanEmail.isEmpty) {
              list.add(p);
            } else if (matchesId || matchesEmail) {
              list.add(p);
            }
          } else if (data is Map) {
            final p = PropertyModel.fromMap(Map<String, dynamic>.from(data), doc.id);
            final bool matchesId = cleanId.isNotEmpty && p.ownerId == cleanId;
            final bool matchesEmail = cleanEmail.isNotEmpty && p.ownerEmail.trim().toLowerCase() == cleanEmail;
            if (cleanId.isEmpty && cleanEmail.isEmpty) {
              list.add(p);
            } else if (matchesId || matchesEmail) {
              list.add(p);
            }
          }
        } catch (e) {
          debugPrint('Error parsing property doc ${doc.id}: $e');
        }
      }

      list.sort((a, b) => b.postDate.compareTo(a.postDate));
      return list;
    });
  }

  /// Get properties owned by a specific house owner (Future)
  Future<List<PropertyModel>> getOwnerProperties(String ownerId, {String? ownerEmail}) async {
    try {
      final snapshot = await _propertiesCollection.get();
      final List<PropertyModel> list = [];
      final String cleanId = ownerId.trim();
      final String cleanEmail = (ownerEmail ?? '').trim().toLowerCase();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final p = PropertyModel.fromMap(data, doc.id);
            final bool matchesId = cleanId.isNotEmpty && p.ownerId == cleanId;
            final bool matchesEmail = cleanEmail.isNotEmpty && p.ownerEmail.trim().toLowerCase() == cleanEmail;
            if (cleanId.isEmpty && cleanEmail.isEmpty) {
              list.add(p);
            } else if (matchesId || matchesEmail) {
              list.add(p);
            }
          } else if (data is Map) {
            final p = PropertyModel.fromMap(Map<String, dynamic>.from(data), doc.id);
            final bool matchesId = cleanId.isNotEmpty && p.ownerId == cleanId;
            final bool matchesEmail = cleanEmail.isNotEmpty && p.ownerEmail.trim().toLowerCase() == cleanEmail;
            if (cleanId.isEmpty && cleanEmail.isEmpty) {
              list.add(p);
            } else if (matchesId || matchesEmail) {
              list.add(p);
            }
          }
        } catch (e) {
          debugPrint('Error parsing property doc ${doc.id}: $e');
        }
      }

      list.sort((a, b) => b.postDate.compareTo(a.postDate));
      return list;
    } catch (e) {
      debugPrint('Error getting owner properties: $e');
      return [];
    }
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

  /// Toggle property rented status (isAvailable = !isRentedOut)
  Future<void> togglePropertyRentedStatus(String propertyId, bool isRentedOut) async {
    try {
      await _propertiesCollection.doc(propertyId).set({
        'isAvailable': !isRentedOut,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Property rented status updated: $propertyId -> isAvailable: ${!isRentedOut}');
    } catch (e) {
      debugPrint('❌ Error toggling property rented status: $e');
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

