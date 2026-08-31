import 'dart:async';
import 'package:flutter/material.dart';
import '../../../home/data/models/property_model.dart';
import '../../../shared/data/services/property_firestore_service.dart';

class MyPostProvider extends ChangeNotifier {
  final PropertyFirestoreService _firestoreService = PropertyFirestoreService();

  List<PropertyModel> _myPosts = [];
  bool _isLoading = true;
  StreamSubscription? _subscription;
  String _currentOwnerId = '';

  List<PropertyModel> get myPosts => List.unmodifiable(_myPosts);
  bool get isLoading => _isLoading;

  void initOwner(String ownerId, {String? ownerEmail}) {
    if (_currentOwnerId == ownerId && _subscription != null) return;
    _currentOwnerId = ownerId;
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _firestoreService
        .streamOwnerProperties(ownerId, ownerEmail: ownerEmail)
        .listen(
      (posts) {
        _myPosts = posts;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error streaming owner properties: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> updatePost(PropertyModel updatedPost) async {
    try {
      await _firestoreService.updateProperty(updatedPost);
      final index = _myPosts.indexWhere((p) => p.id == updatedPost.id);
      if (index != -1) {
        _myPosts[index] = updatedPost;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating post: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String id) async {
    try {
      await _firestoreService.deleteProperty(id);
      _myPosts.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  Future<void> toggleRentedStatus(PropertyModel post) async {
    final newRentedStatus = !post.isRentedOut;
    try {
      // Optimistic local update
      final index = _myPosts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _myPosts[index] = post.copyWith(isAvailable: !newRentedStatus);
        notifyListeners();
      }
      await _firestoreService.togglePropertyRentedStatus(post.id, newRentedStatus);
    } catch (e) {
      debugPrint('Error toggling rented status: $e');
      final index = _myPosts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _myPosts[index] = post;
        notifyListeners();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
