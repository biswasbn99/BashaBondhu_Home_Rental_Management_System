import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../home/data/models/property_model.dart';
import '../models/app_notification_model.dart';
import 'notification_firestore_service.dart';

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

      // Check Auto-Approval setting from Firestore
      bool autoApprove = true;
      try {
        final settingsDoc = await FirebaseFirestore.instance.collection('app_settings').doc('general').get();
        if (settingsDoc.exists && settingsDoc.data() != null) {
          autoApprove = (settingsDoc.data()!['autoApprovalEnabled'] as bool?) ?? true;
        }
      } catch (_) {}

      final propertyWithImages = property.copyWith(
        id: docRef.id,
        images: finalImages,
        approvalStatus: autoApprove ? 'approved' : 'pending',
        isAvailable: autoApprove ? true : false,
        approvedAt: autoApprove ? DateTime.now() : null,
      );

      await docRef.set(propertyWithImages.toMap());
      debugPrint('✅ Property created in Firestore: ${docRef.id} with ${finalImages.length} images (AutoApproved: $autoApprove)');

      // Dispatch Notification to Admin
      try {
        final postTitle = property.shortAddress.isNotEmpty
            ? property.shortAddress
            : "${property.houseType.name} in ${property.area.name}";
        final locationStr = "${property.area.name}, ${property.district.name}";
        final ownerName = property.contactName.isNotEmpty
            ? property.contactName
            : property.ownerEmail.split('@').first;

        await NotificationFirestoreService().createNotification(
          AppNotificationModel(
            id: '',
            recipientType: 'admin',
            recipientId: 'admin',
            recipientEmail: property.ownerEmail,
            title: 'New Property Listing Added',
            titleBn: 'নতুন বাড়িভাড়া বিজ্ঞাপন পোস্ট',
            message: 'User $ownerName (${property.ownerEmail}) posted a new property: "$postTitle" (৳${property.amount}, $locationStr). Status: ${autoApprove ? 'Auto-Approved' : 'Pending Review'}.',
            messageBn: 'ইউজার $ownerName (${property.ownerEmail}) নতুন বাড়িভাড়া বিজ্ঞাপন দিয়েছেন: "$postTitle" (ভাড়া: ৳${property.amount}, $locationStr)। স্ট্যাটাস: ${autoApprove ? 'স্বয়ংক্রিয় অনুমোদিত' : 'পেন্ডিং'}।',
            type: 'post_created',
            targetType: 'property',
            targetId: docRef.id,
            data: {
              'propertyId': docRef.id,
              'postTitle': postTitle,
              'amount': property.amount,
              'location': locationStr,
              'ownerEmail': property.ownerEmail,
              'ownerName': ownerName,
              'ownerId': property.ownerId,
              'approvalStatus': autoApprove ? 'approved' : 'pending',
              'category': 'Listing',
              'image': finalImages.isNotEmpty ? finalImages.first : '',
            },
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        debugPrint('Error sending admin notification on property create: $e');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating property in Firestore: $e');
      rethrow;
    }
  }

  /// Stream all active properties for HomeScreen / FindHomeScreen (only approved & available by default)
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
            final bool isLive = p.isAvailable && p.approvalStatus == 'approved';
            if (!onlyAvailable || isLive) {
              list.add(p);
            }
          } else if (data is Map) {
            final p = PropertyModel.fromMap(Map<String, dynamic>.from(data), doc.id);
            final bool isLive = p.isAvailable && p.approvalStatus == 'approved';
            if (!onlyAvailable || isLive) {
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
      // Check Auto-Approval setting from Firestore
      bool autoApprove = true;
      try {
        final settingsDoc = await FirebaseFirestore.instance.collection('app_settings').doc('general').get();
        if (settingsDoc.exists && settingsDoc.data() != null) {
          autoApprove = (settingsDoc.data()!['autoApprovalEnabled'] as bool?) ?? true;
        }
      } catch (_) {}

      // If autoApprove is false OR post was rejected, reset to pending for review
      final bool shouldBePending = !autoApprove || property.approvalStatus == 'rejected';
      final updatedProperty = property.copyWith(
        approvalStatus: shouldBePending ? 'pending' : property.approvalStatus,
        isAvailable: shouldBePending ? false : property.isAvailable,
        rejectionReason: '',
      );

      await _propertiesCollection.doc(property.id).set(
            updatedProperty.toMap(),
            SetOptions(merge: true),
          );
      debugPrint('✅ Property updated in Firestore: ${property.id} (status: ${updatedProperty.approvalStatus})');

      // Dispatch Notification to Admin
      try {
        final postTitle = property.shortAddress.isNotEmpty
            ? property.shortAddress
            : "${property.houseType.name} in ${property.area.name}";
        final locationStr = "${property.area.name}, ${property.district.name}";
        final ownerName = property.contactName.isNotEmpty
            ? property.contactName
            : property.ownerEmail.split('@').first;

        await NotificationFirestoreService().createNotification(
          AppNotificationModel(
            id: '',
            recipientType: 'admin',
            recipientId: 'admin',
            recipientEmail: property.ownerEmail,
            title: 'Property Post Updated & Resubmitted',
            titleBn: 'বাড়িভাড়া বিজ্ঞাপন সংশোধন ও পুনরায় জমা',
            message: 'User $ownerName (${property.ownerEmail}) updated and resubmitted property listing "$postTitle" (৳${property.amount}, $locationStr). Please review.',
            messageBn: 'ইউজার $ownerName (${property.ownerEmail}) বাড়িভাড়া বিজ্ঞাপন "$postTitle" (ভাড়া: ৳${property.amount}, $locationStr) সংশোধন করে পুনরায় পর্যালোচনার জন্য জমা দিয়েছেন। অনুগ্রহ করে রিভিউ করুন।',
            type: 'post_updated',
            targetType: 'property',
            targetId: property.id,
            data: {
              'propertyId': property.id,
              'postTitle': postTitle,
              'amount': property.amount,
              'location': locationStr,
              'ownerEmail': property.ownerEmail,
              'ownerName': ownerName,
              'ownerId': property.ownerId,
              'approvalStatus': shouldBePending ? 'pending' : property.approvalStatus,
              'category': 'Listing',
              'image': property.images.isNotEmpty ? property.images.first : '',
            },
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        debugPrint('Error sending admin notification on property update: $e');
      }
    } catch (e) {
      debugPrint('❌ Error updating property: $e');
      rethrow;
    }
  }

  /// Delete a property from Firestore
  Future<void> deleteProperty(String propertyId) async {
    try {
      // Fetch details before delete
      String postTitle = 'Property #$propertyId';
      String ownerEmail = '';
      String ownerName = '';
      try {
        final snap = await _propertiesCollection.doc(propertyId).get();
        if (snap.exists && snap.data() != null) {
          final data = Map<String, dynamic>.from(snap.data() as Map);
          postTitle = data['shortAddress'] ?? data['houseType'] ?? 'Property #$propertyId';
          ownerEmail = data['ownerEmail'] ?? '';
          ownerName = data['contactName'] ?? '';
        }
      } catch (_) {}

      await _propertiesCollection.doc(propertyId).delete();
      debugPrint('✅ Property deleted from Firestore: $propertyId');

      // Dispatch Notification to Admin
      try {
        await NotificationFirestoreService().createNotification(
          AppNotificationModel(
            id: '',
            recipientType: 'admin',
            recipientId: 'admin',
            recipientEmail: ownerEmail,
            title: 'Property Listing Deleted',
            titleBn: 'বাড়িভাড়া বিজ্ঞাপন মুছে ফেলা হয়েছে',
            message: 'User ${ownerName.isNotEmpty ? ownerName : ownerEmail} deleted property listing "$postTitle" ($propertyId).',
            messageBn: 'ইউজার ${ownerName.isNotEmpty ? ownerName : ownerEmail} বাড়িভাড়া বিজ্ঞাপন "$postTitle" ($propertyId) মুছে ফেলেছেন।',
            type: 'post_deleted',
            targetType: 'property',
            targetId: propertyId,
            data: {
              'propertyId': propertyId,
              'postTitle': postTitle,
              'ownerEmail': ownerEmail,
              'ownerName': ownerName,
              'category': 'Listing',
            },
            createdAt: DateTime.now(),
          ),
        );
      } catch (e) {
        debugPrint('Error sending admin notification on property delete: $e');
      }
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

