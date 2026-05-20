import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/location_service.dart';
import '../../services/vendor_profile_service.dart';

class VendorProfileProvider extends ChangeNotifier {
  final VendorProfileService _service;
  VendorProfileProvider(this._service);

  bool _loading = false;
  String? _error;
  VendorProfile? _profile;

  bool get loading => _loading;
  String? get error => _error;
  VendorProfile? get profile => _profile;

  Future<void> load(String uid) async {
    _loading = true;
    notifyListeners();
    _profile = await _service.getProfile(uid);
    _loading = false;
    notifyListeners();
  }

  Future<bool> save({
    required String displayName,
    required String bio,
    required String category,
    required String location,
    double? lat,
    double? lng,
    String? geohash,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.upsertProfile(
        displayName: displayName,
        bio: bio,
        category: category,
        location: location,
        lat: lat,
        lng: lng,
        geohashValue: geohash,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> uploadPhoto() async {
    await _service.uploadProfilePhoto();
    notifyListeners();
  }

  Future<void> addPortfolioImage() async {
    await _service.addPortfolioImage();
    notifyListeners();
  }

  Future<void> removePortfolioImage(String url) async {
    await _service.removePortfolioImage(url);
    notifyListeners();
  }

  Stream browseVendors({String? category}) =>
      _service.browseVendors(category: category);
}

class VendorOnboardingScreen extends StatefulWidget {
  final VendorProfile? existing;
  const VendorOnboardingScreen({super.key, this.existing});

  @override
  State<VendorOnboardingScreen> createState() =>
      _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState extends State<VendorOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _locationCtrl;
  String? _selectedCategory;
  double? _lat, _lng;
  String? _geohash;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.displayName ?? '');
    _bioCtrl = TextEditingController(text: e?.bio ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _selectedCategory = e?.category;
    _lat = e?.lat;
    _lng = e?.lng;
    _geohash = e?.geohash;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    final pos = await LocationService().getCurrentLocation();
    if (pos == null) return;
    final address = await LocationService()
        .getAddressFromCoords(pos.latitude, pos.longitude);
    _lat = pos.latitude;
    _lng = pos.longitude;
    _geohash = LocationService().geohash(_lat!, _lng!);
    if (address != null) _locationCtrl.text = address;
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a service category')));
      return;
    }
    final provider = context.read<VendorProfileProvider>();
    final ok = await provider.save(
      displayName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      category: _selectedCategory!,
      location: _locationCtrl.text.trim(),
      lat: _lat,
      lng: _lng,
      geohash: _geohash,
    );
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Error saving profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorProfileProvider>();
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Profile' : 'Set Up Your Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundImage: provider.profile?.photoUrl != null
                        ? NetworkImage(provider.profile!.photoUrl!)
                        : null,
                    child: provider.profile?.photoUrl == null
                        ? const Icon(Icons.person, size: 52)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 16),
                        onPressed: provider.uploadPhoto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Business / Display Name *',
                  border: OutlineInputBorder()),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                  labelText: 'Bio / About',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                  labelText: 'Service Category *',
                  border: OutlineInputBorder()),
              items: kVendorCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _detectLocation,
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Use my location',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Portfolio
            const Text('Portfolio Images',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            _PortfolioGrid(
              images: provider.profile?.portfolioImages ?? [],
              onAdd: provider.addPortfolioImage,
              onRemove: provider.removePortfolioImage,
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: provider.loading ? null : _submit,
                child: provider.loading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Text(isEdit ? 'Save Changes' : 'Complete Setup',
                        style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioGrid extends StatelessWidget {
  final List<String> images;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _PortfolioGrid({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length + 1,
      itemBuilder: (_, i) {
        if (i == images.length) {
          return InkWell(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade600),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined,
                  size: 32, color: Colors.grey),
            ),
          );
        }
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(images[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(images[i]),
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}