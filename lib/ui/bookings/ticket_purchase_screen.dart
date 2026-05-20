import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/booking_service.dart';

// ─── Booking List (for both customer and vendor) ──────────────────────────────

class BookingListScreen extends StatefulWidget {
  final bool isVendor;
  const BookingListScreen({super.key, this.isVendor = false});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _statuses = [null, BookingStatus.pending, BookingStatus.accepted,
      BookingStatus.completed, BookingStatus.rejected];
  final _labels = ['All', 'Pending', 'Accepted', 'Completed', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isVendor ? 'Booking Requests' : 'My Bookings'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: _statuses.map((status) => _BookingTab(
              status: status,
              isVendor: widget.isVendor,
            )).toList(),
      ),
    );
  }
}

class _BookingTab extends StatelessWidget {
  final BookingStatus? status;
  final bool isVendor;
  const _BookingTab({this.status, required this.isVendor});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final stream = isVendor
        ? provider.vendorBookings(status: status)
        : provider.myBookings(status: status);

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
              child: Text('No bookings here', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final booking = BookingModel.fromDoc(docs[i]);
            return _BookingCard(booking: booking, isVendor: isVendor);
          },
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isVendor;
  const _BookingCard({required this.booking, required this.isVendor});

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending: return Colors.orange;
      case BookingStatus.accepted: return Colors.green;
      case BookingStatus.rejected: return Colors.red;
      case BookingStatus.completed: return Colors.blue;
      case BookingStatus.cancelled: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BookingProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(booking.eventTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(booking.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(booking.status)),
                  ),
                  child: Text(
                    booking.status.name.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        color: _statusColor(booking.status),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isVendor ? 'From: ${booking.customerName}' : 'Vendor: ${booking.vendorName}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d yyyy').format(booking.eventDate),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            if (booking.eventDescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(booking.eventDescription,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isVendor && booking.status == BookingStatus.pending) ...[
                  OutlinedButton(
                    onPressed: () => provider.rejectBooking(booking.id),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red)),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => provider.acceptBooking(booking.id),
                    child: const Text('Accept'),
                  ),
                ],
                if (isVendor && booking.status == BookingStatus.accepted)
                  ElevatedButton(
                    onPressed: () => provider.markCompleted(booking.id),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue),
                    child: const Text('Mark Completed'),
                  ),
                if (!isVendor && booking.canCancel)
                  OutlinedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Cancel Booking'),
                          content: const Text(
                              'Are you sure you want to cancel this booking?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('No')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Yes, Cancel')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        provider.cancelBooking(booking.id);
                      }
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Create Booking Screen ────────────────────────────────────────────────────

class CreateBookingScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final String customerName;

  const CreateBookingScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.customerName,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _eventDate;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d != null) setState(() => _eventDate = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an event date')));
      return;
    }

    final provider = context.read<BookingProvider>();
    final id = await provider.createBooking(
      vendorId: widget.vendorId,
      vendorName: widget.vendorName,
      customerName: widget.customerName,
      eventTitle: _titleCtrl.text.trim(),
      eventDescription: _descCtrl.text.trim(),
      eventDate: _eventDate!,
    );

    if (!mounted) return;
    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request sent! ✅')));
      Navigator.pop(context, id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Something went wrong')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Request Booking')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Vendor info chip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront),
                  const SizedBox(width: 10),
                  Text(widget.vendorName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Event Title *',
                  border: OutlineInputBorder()),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Event Description',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Event Date *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today)),
                child: Text(
                  _eventDate != null
                      ? DateFormat('EEEE, MMMM d, yyyy').format(_eventDate!)
                      : 'Select date',
                  style: TextStyle(
                      color: _eventDate != null
                          ? null
                          : Theme.of(context).hintColor),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: provider.loading ? null : _submit,
                child: provider.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Send Booking Request',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}