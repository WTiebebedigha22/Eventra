import 'package:flutter/material.dart';
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
}

class SeatSelectionScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const SeatSelectionScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  late List<List<SeatModel>> rows;
  final Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    _initSeats();
  }

  void _initSeats() {
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
          price: isVip ? 120.0 : 75.0,
        );
      });
    }).toList();
  }

  void _toggleSeat(SeatModel seat) {
    if (seat.status == SeatStatus.taken) return;
    setState(() {
      if (selectedIds.contains(seat.id)) {
        selectedIds.remove(seat.id);
      } else {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(title: const Text('Select Seats')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Stage indicator
                  _buildStage(),
                  const SizedBox(height: 28),

                  // Legend
                  _buildLegend(),
                  const SizedBox(height: 24),

                  // Seat grid
                  _buildSeatGrid(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Bottom summary bar
          if (selectedIds.isNotEmpty) _buildBottomBar(),
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
          ),
          child: Center(
            child: Text(
              'STAGE',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white, letterSpacing: 4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Perspective lines
        CustomPaint(
          size: const Size(double.infinity, 24),
          painter: _PerspectivePainter(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: AppColors.seatAvailable, label: 'Available'),
        const SizedBox(width: 20),
        _LegendItem(color: AppColors.seatSelected, label: 'Selected'),
        const SizedBox(width: 20),
        _LegendItem(color: AppColors.seatTaken, label: 'Taken'),
        const SizedBox(width: 20),
        _LegendItem(color: AppColors.seatVip, label: 'VIP'),
      ],
    );
  }

  Widget _buildSeatGrid() {
    return Column(
      children: rows.asMap().entries.map((entry) {
        final rowLabel = entry.value.first.row;
        final seats = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Row label
              SizedBox(
                width: 22,
                child: Text(
                  rowLabel,
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 4),
              // Seats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: seats.map((seat) {
                    final isSelected = selectedIds.contains(seat.id);
                    return _SeatWidget(
                      seat: seat,
                      isSelected: isSelected,
                      onTap: () => _toggleSeat(seat),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 4),
              // Row label (right)
              SizedBox(
                width: 22,
                child: Text(
                  rowLabel,
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedIds.length} seat${selectedIds.length > 1 ? 's' : ''} selected',
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    selectedIds.join(', '),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Continue to Payment',
            onPressed: () {},
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: seat.status == SeatStatus.taken ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _color.withOpacity(seat.status == SeatStatus.taken ? 0.3 : isSelected ? 1 : 0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(3),
            bottomRight: Radius.circular(3),
          ),
          border: isSelected
              ? Border.all(color: Colors.white, width: 1.5)
              : null,
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
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _PerspectivePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderDefault
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width / 2 - 100, 0),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2 + 100, 0),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}