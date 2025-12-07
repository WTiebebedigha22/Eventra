import '../models/vendor_model.dart';
import '../models/event_model.dart';
import 'vendor_service.dart';
import 'event_service.dart';

class SearchService {
  final VendorService _vendorService = VendorService();
  final EventService _eventService = EventService();

  Future<List<dynamic>> search(String query) async {
    query = query.toLowerCase();

    final vendors = await _vendorService.getVendors();
    final events = await _eventService.fetchEvents();

    final matchesV = vendors.where((v) => v.name.toLowerCase().contains(query));
    final matchesE = events.where((e) => e.title.toLowerCase().contains(query));

    return [...matchesV, ...matchesE];
  }
}
