import 'dart:async';
import 'package:flutter/material.dart';
import '../../../home/data/models/property_model.dart';
import '../../../shared/data/services/property_firestore_service.dart';

class WishlistProvider extends ChangeNotifier {
  final PropertyFirestoreService _firestoreService = PropertyFirestoreService();

  List<String> _wishlistIds = [];
  List<PropertyModel> _allProperties = [];
  StreamSubscription? _wishlistSubscription;
  StreamSubscription? _propertiesSubscription;

  List<String> get wishlistIds => List.unmodifiable(_wishlistIds);

  List<PropertyModel> get wishlistProperties {
    return _allProperties.where((p) => _wishlistIds.contains(p.id)).toList();
  }

  bool isFavorite(String propertyId) {
    return _wishlistIds.contains(propertyId);
  }

  void initialize(String userId) {
    _wishlistSubscription?.cancel();
    _propertiesSubscription?.cancel();

    _propertiesSubscription = _firestoreService.streamAllProperties().listen((props) {
      _allProperties = props;
      notifyListeners();
    });

    if (userId.isNotEmpty) {
      _wishlistSubscription = _firestoreService.streamWishlistPropertyIds(userId).listen((ids) {
        _wishlistIds = ids;
        notifyListeners();
      });
    } else {
      _wishlistIds = [];
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String userId, String propertyId) async {
    if (userId.isEmpty) {
      // Local fallback for guest
      if (_wishlistIds.contains(propertyId)) {
        _wishlistIds.remove(propertyId);
      } else {
        _wishlistIds.add(propertyId);
      }
      notifyListeners();
      return;
    }

    final added = await _firestoreService.toggleWishlist(userId, propertyId);
    if (added) {
      if (!_wishlistIds.contains(propertyId)) _wishlistIds.add(propertyId);
    } else {
      _wishlistIds.remove(propertyId);
    }
    notifyListeners();
  }

  Future<void> removeFavorite(String userId, String propertyId) async {
    await toggleFavorite(userId, propertyId);
  }

  @override
  void dispose() {
    _wishlistSubscription?.cancel();
    _propertiesSubscription?.cancel();
    super.dispose();
  }
}

