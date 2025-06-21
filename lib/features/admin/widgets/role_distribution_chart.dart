import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RoleDistributionChart extends StatelessWidget {
  final Map<String, dynamic> data;

  const RoleDistributionChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución de Roles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _generateSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _generateLegendItems(),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generateSections() {
    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    var colorIndex = 0;

    data.forEach((role, count) {
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[colorIndex % colors.length],
            value: count.toDouble(),
            title: count.toString(),
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        colorIndex++;
      }
    });

    return sections;
  }

  List<Widget> _generateLegendItems() {
    final List<Widget> items = [];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    var colorIndex = 0;

    final roleNames = {
      'student': 'Estudiantes',
      'teacher': 'Tutores',
      'admin': 'Administradores',
      'superAdmin': 'Super Admin',
    };

    data.forEach((role, count) {
      if (count > 0) {
        items.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[colorIndex % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text('${roleNames[role] ?? role}: $count'),
            ],
          ),
        );
        colorIndex++;
      }
    });

    return items;
  }
} 