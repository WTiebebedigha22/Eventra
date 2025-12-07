import 'package:flutter/material.dart';
import '../models/vendor/vendor.dart';
import '../models/vendor/category.dart';
import '../services/notification_service.dart';

class VendorProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();

  List<Vendor> vendors = [];
  List<Category> categories = [];
  bool isLoading = false;

  Future<void> loadVendors() async {
    isLoading = true;
    notifyListeners();

    vendors = await _db.getVendors();
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    categories = await _db.getCategories();
    notifyListeners();
  }

  List<Vendor> getVendorsByCategory(String categoryId) {
    return vendors.where((v) => v.categoryId == categoryId).toList();
  }

  Vendor? getVendorById(String id) {
    return vendors.firstWhere((v) => v.id == id, orElse: () => null as Vendor);
  }
}
