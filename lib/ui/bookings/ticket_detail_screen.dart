import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../app/app_theme.dart';
import '../../core/shared_widget.dart';

class TicketDetailScreen extends StatelessWidget {
  final String ticketId;
  final String eventTitle;
  final String date;
  final String time;
  final String venue;
  final String seat;
  final String section;
  final String price;
  final String organiser;
  final String eventImageUrl;
  final bool isUsed;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    required this.eventTitle,
    required this.date,
    required this.time,
    required this.venue,
    required this.seat,
    required this.section,
    required this.price,
    required this.organiser,
    required this.eventImageUrl,
    this.isUsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('My Ticket'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            _buildTicketBody(context),
            const SizedBox(height: 24),
            _buildActions(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          // Event header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: const LinearGradient(
                colors: AppColors.purpleGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isUsed)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'USED',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
                    ),
                  ),
                Text(
                  eventTitle,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      organiser,
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ticket info row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _InfoBlock(label: 'Date', value: date),
                _Divider(),
                _InfoBlock(label: 'Time', value: time),
                _Divider(),
                _InfoBlock(label: 'Section', value: section),
                _Divider(),
                _InfoBlock(label: 'Seat', value: seat),
              ],
            ),
          ),

          // Venue
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.accentPurple,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Venue', style: AppTextStyles.bodySmall),
                      const SizedBox(height: 2),
                      Text(venue, style: AppTextStyles.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dashed cut line
          _CutLine(),

          // QR code section
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Text(
                  'Scan to Enter',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                // QR code with styled container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Opacity(
                    opacity: isUsed ? 0.3 : 1.0,
                    child: QrImageView(
                      data: ticketId,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Ticket ID
                Text(
                  ticketId,
                  style: AppTextStyles.bodySmall.copyWith(
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                // Price badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
                  ),
                  child: Text(
                    price,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.accentOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        GradientButton(
          label: 'Add to Wallet',
          onPressed: () {},
          colors: AppColors.purpleGradient,
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Download PDF',
          variant: AppButtonVariant.outlined,
          icon: Icons.download_outlined,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 36,
      color: AppColors.borderDefault,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _CutLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.bgPrimary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dashW = 8.0;
              const gap = 6.0;
              final count = (constraints.maxWidth / (dashW + gap)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  count,
                  (_) => Container(
                    width: dashW,
                    height: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: gap / 2),
                    color: AppColors.borderDefault,
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.bgPrimary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}