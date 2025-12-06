import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Business Analytics',
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Date Picker Placeholder')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            // 1. Key Metrics Overview (KPIs)
            _KeyMetricsHeader(),
            SizedBox(height: 20),

            // 2. Visual Performance Chart
            _PerformanceChartCard(),
            SizedBox(height: 20),

            // 3. Recent Activity/Top Listings
            Text(
              'Top Performing Listings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _RecentActivityList(),
          ],
        ),
      ),
    );
  }
}

// --- 1. Key Metrics Header ---

class _KeyMetricsHeader extends StatelessWidget {
  const _KeyMetricsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const <Widget>[
            _KPICard(
              title: 'Total Views',
              value: '14,567',
              change: '+8.2%',
              icon: Icons.bar_chart_outlined,
              iconColor: Colors.green,
            ),
            _KPICard(
              title: 'Total Leads',
              value: '452',
              change: '+15.1%',
              icon: Icons.people_outline,
              iconColor: Color(0xFF007bff), // Ventra Blue
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const <Widget>[
            _KPICard(
              title: 'Avg. Rating',
              value: '4.8/5',
              change: '-0.1',
              icon: Icons.star_border,
              iconColor: Colors.orange,
            ),
            _KPICard(
              title: 'Promoted Items',
              value: '3/42',
              change: 'Active',
              icon: Icons.rocket_launch_outlined,
              iconColor: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }
}

// Helper Widget for Key Metric Indicator
class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color iconColor;

  const _KPICard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = change.startsWith('+') || change == 'Active';

    return Expanded(
      child: Card(
        color: theme.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Icon(icon, size: 20, color: iconColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. Performance Chart Section ---

class _PerformanceChartCard extends StatelessWidget {
  const _PerformanceChartCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Over Last 30 Days',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            
            // Custom Painter to simulate a line chart
            SizedBox(
              height: 150,
              width: double.infinity,
              child: _SimpleLineChart(
                lineColor: const Color(0xFF007bff), // Ventra Blue
                fillColor: const Color(0xFF007bff).withOpacity(0.2),
                isDarkMode: theme.brightness == Brightness.dark,
              ),
            ),
            const SizedBox(height: 10),

            // Chart Legend/Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ChartLegendItem(
                  color: const Color(0xFF007bff), 
                  label: 'Views: 14.5k',
                ),
                _ChartLegendItem(
                  color: Colors.green, 
                  label: 'Leads: 452',
                ),
                _ChartLegendItem(
                  color: Colors.orange, 
                  label: 'Clicks: 890',
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Helper for the Chart Legend
class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

// The heart of the visualization: Simple Line Chart using CustomPainter
class _SimpleLineChart extends StatelessWidget {
  final Color lineColor;
  final Color fillColor;
  final bool isDarkMode;

  const _SimpleLineChart({
    required this.lineColor,
    required this.fillColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        lineColor: lineColor,
        fillColor: fillColor,
        gridColor: isDarkMode ? Colors.white12 : Colors.black12,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  _LineChartPainter({
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  // Dummy data points (normalized to 0-1 range for a smooth look)
  final List<double> data = const [0.5, 0.7, 0.6, 0.85, 0.75, 0.9, 0.8, 0.95];

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final stepX = width / (data.length - 1);

    // 1. Draw Grid Lines (Horizontal)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final y = height - (height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // 2. Calculate Points
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      // Convert normalized data (0-1) to screen coordinates (y-axis is inverted)
      final y = height * (1 - data[i]);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // 3. Draw Fill Area (Gradient/Color)
    final fillPath = Path.from(path);
    // Move to bottom-right corner, then bottom-left, then close
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- 3. Recent Activity/Top Listings List ---

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList();

  // Dummy data for recent activity tiles
  final List<Map<String, dynamic>> activities = const [
    {
      'title': 'Grand Wedding Decor Package',
      'detail': '28 Leads last 7 days',
      'icon': Icons.trending_up,
      'color': Colors.green,
    },
    {
      'title': 'Corporate Retreat Catering',
      'detail': '2 new messages today',
      'icon': Icons.chat_bubble_outline,
      'color': Color(0xFF007bff), // Ventra Blue
    },
    {
      'title': 'DJ Setup Rental (Lagos)',
      'detail': 'View count increased by 12%',
      'icon': Icons.show_chart,
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _MetricTile(
          title: activity['title'],
          detail: activity['detail'],
          icon: activity['icon'],
          iconColor: activity['color'],
        );
      },
    );
  }
}

// Helper Widget for List Item/Metric Tile
class _MetricTile extends StatelessWidget {
  final String title;
  final String detail;
  final IconData icon;
  final Color iconColor;

  const _MetricTile({
    required this.title,
    required this.detail,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        color: theme.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          subtitle: Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Details for $title')),
            );
          },
        ),
      ),
    );
  }
}