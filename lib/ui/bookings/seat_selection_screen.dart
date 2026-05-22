import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../app/app_theme.dart';
import '../../core/shared_widget.dart';

enum SeatStatus { available, selected, taken, vip }

class SeatModel {
  final String id;
  final String row;
  final int number;
  final SeatStatus status;
  final double price;

  SeatModel({
    required this.id,
    required this.row,
    required this.number,
    required this.status,
    required this.price,
  });

  SeatModel copyWith({SeatStatus? status}) {
    return SeatModel(
      id: id,
      row: row,
      number: number,
      status: status ?? this.status,
      price: price,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'row': row,
      'number': number,
      'status': status.toString(),
      'price': price,
    };
  }
}

class SeatSelectionScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final double eventPrice;

  const SeatSelectionScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.eventPrice = 0,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> with SingleTickerProviderStateMixin {
  late List<List<SeatModel>> rows;
  final Set<String> selectedIds = {};
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  static const double vipPrice = 120.0;
  static const double regularPrice = 75.0;
  
  final NumberFormat currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _loadSeats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSeats() async {
    setState(() => _isLoading = true);
    
    try {
      // Try to load saved seats from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('seats')
          .doc('layout')
          .get();
      
      if (doc.exists) {
        // Load from Firestore
        final data = doc.data()!;
        final seatsData = data['seats'] as List<dynamic>;
        // Parse seats data...
      } else {
        // Initialize default seats
        _initDefaultSeats();
      }
    } catch (e) {
      _initDefaultSeats();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initDefaultSeats() {
    const rowLabels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final takenSpots = {'B3', 'B4', 'C7', 'D2', 'D3', 'D8', 'E5', 'F1', 'F2', 'G6'};
    final vipRows = {'A', 'B'};

    rows = rowLabels.map((rowLabel) {
      final isVip = vipRows.contains(rowLabel);
      return List.generate(10, (i) {
        final seatId = '$rowLabel${i + 1}';
        final isTaken = takenSpots.contains(seatId);
        return SeatModel(
          id: seatId,
          row: rowLabel,
          number: i + 1,
          status: isTaken
              ? SeatStatus.taken
              : isVip
                  ? SeatStatus.vip
                  : SeatStatus.available,
          price: isVip ? vipPrice : (widget.eventPrice > 0 ? widget.eventPrice : regularPrice),
        );
      });
    }).toList();
  }

  void _toggleSeat(SeatModel seat) {
    if (seat.status == SeatStatus.taken) {
      _showSnackBar('This seat is already taken', isError: true);
      return;
    }
    
    HapticFeedback.lightImpact();
    setState(() {
      if (selectedIds.contains(seat.id)) {
        selectedIds.remove(seat.id);
      } else {
        if (selectedIds.length >= 10) {
          _showSnackBar('Maximum 10 seats per booking', isError: true);
          return;
        }
        selectedIds.add(seat.id);
      }
    });
  }

  double get totalPrice {
    double total = 0;
    for (final row in rows) {
      for (final seat in row) {
        if (selectedIds.contains(seat.id)) {
          total += seat.price;
        }
      }
    }
    return total;
  }

  String get selectedSeatsText {
    final List<String> seats = [];
    for (final row in rows) {
      for (final seat in row) {
        if (selectedIds.contains(seat.id)) {
          seats.add(seat.id);
        }
      }
    }
    return seats.join(', ');
  }

  Future<void> _proceedToPayment() async {
    if (selectedIds.isEmpty) {
      _showSnackBar('Please select at least one seat', isError: true);
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please login to continue', isError: true);
      return;
    }
    
    // Navigate to payment screen with selected seats
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'eventId': widget.eventId,
        'eventTitle': widget.eventTitle,
        'seats': selectedSeatsText,
        'totalPrice': totalPrice,
        'quantity': selectedIds.length,
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Select Seats'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildEventInfo(),
                          const SizedBox(height: 20),
                          _buildStage(),
                          const SizedBox(height: 28),
                          _buildLegend(),
                          const SizedBox(height: 24),
                          _buildSeatGrid(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  if (selectedIds.isNotEmpty) _buildBottomBar(),
                ],
              ),
            ),
    );
  }

  Widget _buildEventInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, color: AppColors.accentPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.eventTitle,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'VIP: \$${vipPrice.toStringAsFixed(2)} | Regular: \$${regularPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage() {
    return Column(
      children: [
        Container(
          width: 200,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.purpleGradient),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'STAGE',
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        CustomPaint(
          size: const Size(double.infinity, 24),
          painter: _PerspectivePainter(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LegendItem(color: AppColors.seatAvailable, label: 'Available'),
          _LegendItem(color: AppColors.seatSelected, label: 'Selected'),
          _LegendItem(color: AppColors.seatTaken, label: 'Taken'),
          _LegendItem(color: AppColors.seatVip, label: 'VIP'),
        ],
      ),
    );
  }

  Widget _buildSeatGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final rowLabel = entry.value.first.row;
          final seats = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Row label left
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      rowLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Seats
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: seats.asMap().entries.map((seatEntry) {
                      final seat = seatEntry.value;
                      final isSelected = selectedIds.contains(seat.id);
                      return _SeatWidget(
                        seat: seat,
                        isSelected: isSelected,
                        onTap: () => _toggleSeat(seat),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                // Row label right
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      rowLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentPurple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 100),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedIds.length} seat${selectedIds.length > 1 ? 's' : ''} selected',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedSeatsText,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      currencyFormat.format(totalPrice),
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Continue to Payment',
              onPressed: _proceedToPayment,
              icon: Icons.payment,
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatWidget extends StatelessWidget {
  final SeatModel seat;
  final bool isSelected;
  final VoidCallback onTap;

  const _SeatWidget({
    required this.seat,
    required this.isSelected,
    required this.onTap,
  });

  Color get _color {
    if (isSelected) return AppColors.seatSelected;
    switch (seat.status) {
      case SeatStatus.taken:
        return AppColors.seatTaken;
      case SeatStatus.vip:
        return AppColors.seatVip;
      default:
        return AppColors.seatAvailable;
    }
  }

  String get _priceLabel {
    if (seat.status == SeatStatus.vip) return 'VIP';
    if (seat.price > 0) return '\$${seat.price.toInt()}';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: seat.status == SeatStatus.taken ? null : onTap,
      child: Tooltip(
        message: '${seat.id} - ${_priceLabel.isNotEmpty ? _priceLabel : 'Regular'}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _color.withValues(alpha: seat.status == SeatStatus.taken ? 0.3 : (isSelected ? 1 : 0.8)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            border: isSelected
                ? Border.all(color: Colors.white, width: 2)
                : seat.status == SeatStatus.vip
                    ? Border.all(color: const Color.fromARGB(255, 129, 129, 1), width: 1)
                    : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.seatSelected.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: seat.status == SeatStatus.taken
                ? const Icon(Icons.close, size: 12, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _PerspectivePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderDefault
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final startX = size.width / 2;
    
    // Left perspective line
    canvas.drawLine(
      Offset(startX - 80, 0),
      Offset(20, size.height),
      paint,
    );
    
    // Right perspective line
    canvas.drawLine(
      Offset(startX + 80, 0),
      Offset(size.width - 20, size.height),
      paint,
    );
    
    // Additional perspective lines for depth
    final innerPaint = Paint()
      ..color = AppColors.borderDefault.withValues(alpha: 0.5)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(startX - 120, 0),
      Offset(0, size.height),
      innerPaint,
    );
    
    canvas.drawLine(
      Offset(startX + 120, 0),
      Offset(size.width, size.height),
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}