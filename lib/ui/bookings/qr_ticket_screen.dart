import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TicketScreen extends StatefulWidget {
  final String ticketId;

  const TicketScreen({super.key, required this.ticketId});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _ticketData;
  String? _error;

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color pendingColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFF7F7FB);

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    setState(() => _isLoading = true);
    
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    if (currentUserId.isEmpty) {
      setState(() {
        _error = 'Please log in to view tickets';
        _isLoading = false;
      });
      return;
    }
    
    try {
      // FIXED: Query the bookings collection instead
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('ticketId', isEqualTo: widget.ticketId)
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _ticketData = querySnapshot.docs.first.data() as Map<String, dynamic>;
          _ticketData!['id'] = querySnapshot.docs.first.id;
          _isLoading = false;
        });
      } else {
        // Also try the users/tickets subcollection as fallback
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('tickets')
            .doc(widget.ticketId)
            .get();
        
        if (doc.exists) {
          setState(() {
            _ticketData = doc.data();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Ticket not found';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading ticket';
        _isLoading = false;
      });
      debugPrint('Error loading ticket: $e');
    }
  }

  String get _displayTicketId {
    final id = widget.ticketId;
    if (id.isEmpty) return 'N/A';
    if (id.length <= 12) return id;
    return '${id.substring(0, 6)}...${id.substring(id.length - 6)}';
  }

  String get _shortTicketId {
    final id = widget.ticketId;
    if (id.isEmpty) return 'N/A';
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          "My Ticket",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text('Loading ticket...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 20),
              Text(_error!, style: const TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (_ticketData == null) {
      return const Center(child: Text('No ticket data'));
    }

    return _buildTicketContent();
  }

  Widget _buildTicketContent() {
    final data = _ticketData!;
    
    final String eventTitle = data['eventTitle'] ?? 'Event';
    final String eventImageUrl = data['eventImageUrl'] ?? '';
    final String location = data['venue'] ?? data['eventLocation'] ?? data['location'] ?? 'Location TBD';
    final int quantity = (data['quantity'] ?? 1).toInt();
    final double totalPrice = (data['total'] ?? data['totalPrice'] ?? 0).toDouble();
    final bool isPaid = data['status'] == 'confirmed';
    final String status = data['status'] ?? (isPaid ? 'confirmed' : 'pending');
    
    String formattedDate = 'Date not available';
    if (data['createdAt'] != null) {
      final timestamp = data['createdAt'] as Timestamp;
      formattedDate = DateFormat('MMM dd, yyyy • h:mm a').format(timestamp.toDate());
    }

    // Get event date from the booking data
    String eventDate = 'Date TBD';
    if (data['eventDate'] != null && data['eventDate'] is String) {
      eventDate = data['eventDate'];
    } else if (data['eventDate'] != null) {
      final timestamp = data['eventDate'] as Timestamp;
      eventDate = DateFormat('MMM dd, yyyy • h:mm a').format(timestamp.toDate());
    }

    final qrData = {
      'ticketId': widget.ticketId,
      'eventId': data['eventId'] ?? 'N/A',
      'eventTitle': eventTitle,
      'date': eventDate,
      'location': location,
      'quantity': quantity,
    };

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusBanner(isPaid, status),
          const SizedBox(height: 16),
          _buildTicketCard(eventTitle, location, eventImageUrl, qrData, quantity, totalPrice, formattedDate, eventDate, status),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool isPaid, String status) {
    final isConfirmed = isPaid || status == 'confirmed';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isConfirmed ? successColor.withOpacity(0.1) : pendingColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConfirmed ? successColor.withOpacity(0.3) : pendingColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConfirmed ? Icons.check_circle : Icons.pending,
            color: isConfirmed ? successColor : pendingColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isConfirmed ? 'Payment confirmed — Enjoy the event!' : 'Awaiting payment confirmation',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isConfirmed ? successColor : pendingColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(
    String title,
    String location,
    String imageUrl,
    Map<String, dynamic> qrData,
    int quantity,
    double totalPrice,
    String purchaseDate,
    String eventDate,
    String status,
  ) {
    final isConfirmed = status == 'confirmed';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                // Event image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.event, color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.event, color: Colors.white),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.event, color: Colors.white),
                        ),
                ),
                const SizedBox(width: 16),
                // Event info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EVENT TICKET',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              eventDate,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // QR Code Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showFullscreenQR(qrData),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: QrImageView(
                      data: qrData.toString(),
                      version: QrVersions.auto,
                      size: 180,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF5B21B6),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF5B21B6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap QR to enlarge',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _displayTicketId,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          _buildDashedDivider(),
          
          // Ticket Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow(Icons.confirmation_number, 'Ticket ID', '#${_shortTicketId}'),
                const SizedBox(height: 14),
                _buildInfoRow(Icons.people, 'Quantity', '$quantity ticket${quantity > 1 ? 's' : ''}'),
                const SizedBox(height: 14),
                _buildInfoRow(Icons.payments, 'Total Paid', '₦${totalPrice.toStringAsFixed(0)}'),
                const SizedBox(height: 14),
                _buildInfoRow(Icons.calendar_today, 'Purchase Date', purchaseDate),
                const SizedBox(height: 14),
                _buildInfoRow(
                  Icons.verified,
                  'Status',
                  isConfirmed ? 'Confirmed' : 'Pending',
                  valueColor: isConfirmed ? successColor : pendingColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullscreenQR(Map<String, dynamic> qrData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: qrData.toString(),
                  version: QrVersions.auto,
                  size: 280,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF5B21B6),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF5B21B6),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _displayTicketId,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _shareTicket(),
            icon: const Icon(Icons.share, size: 20),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home, size: 20),
            label: const Text('Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareTicket() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildNotch(left: true),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dashCount = (constraints.constrainWidth() / 8).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    dashCount,
                    (index) => Container(
                      width: 4,
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                );
              },
            ),
          ),
          _buildNotch(left: false),
        ],
      ),
    );
  }

  Widget _buildNotch({required bool left}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.horizontal(
          left: left ? Radius.zero : const Radius.circular(8),
          right: left ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}