import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CotisationStatsScreen extends StatelessWidget {
  final List<dynamic> cotisations;

  const CotisationStatsScreen({
    super.key,
    required this.cotisations,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, double> stats = {};

    // Regrouper par mois/année
    for (final c in cotisations) {
      String key = "${c['mois']}/${c['annee']}";
      stats[key] = (stats[key] ?? 0) + double.parse(c['montant'].toString());
    }

    final total = stats.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistiques des Cotisations"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Total cotisé : ${total.toStringAsFixed(0)} FCFA",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(stats.length, (i) {
                    final key = stats.keys.toList()[i];
                    final valeur = stats[key]!;

                    return BarChartGroupData(
                      x: i, // ⬅ correction : FLChart exige double
                      barRods: [
                        BarChartRodData(
                          toY: valeur, // ⬅ correction : doit être double
                          color: Colors.blue,
                          width: 20.0,
                          borderRadius: BorderRadius.circular(6),
                        )
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= stats.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              stats.keys.toList()[index],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),

                    // Axe Y
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
