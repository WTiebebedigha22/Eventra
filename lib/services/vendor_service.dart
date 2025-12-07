import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor_model.dart';
import 'app_exceptions.dart';

class VendorService {
  final _ref = FirebaseFirestore.instance.collection('vendors');

  Future<List<VendorModel>> getVendors() async {
    try {
      final snap = await _ref.get();
      return snap.docs.map((e) => VendorModel.fromMap(e.data(), e.id)).toList();
    } catch (_) {
      throw FirebaseException("Failed to load vendors");
    }
  }

  Future<VendorModel> getVendor(String id) async {
    try {
      final doc = await _ref.doc(id).get();
      return VendorModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      throw FirebaseException("Cannot fetch vendor");
    }
  }
}
