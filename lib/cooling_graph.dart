import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CoolingGraphWidget extends StatefulWidget {
  final double qFlux;
  final double tempAir;
  final double lChar;

  const CoolingGraphWidget({
    super.key,
    required this.qFlux,
    required this.tempAir,
    required this.lChar,
  });

  @override
  State<CoolingGraphWidget> createState() => _CoolingGraphWidgetState();
}

class _CoolingGraphWidgetState extends State<CoolingGraphWidget> {
  final List<FlSpot> spots = [];

  double? touchX;
  double? touchY;

  @override
  void initState() {
    super.initState();
    generateData();
  }

  // ===========================
  // Generate data
  // ===========================
  void generateData() {
    spots.clear();

    for (double tReq = 100; tReq <= 650; tReq += 5) {
      final heat = calculateHeatRequired(tReq);
      if (!heat.isFinite || heat <= 0) continue;

      final velocity = calculateCoolingVelocity(tReq, heat);
      if (!velocity.isFinite || velocity <= 0) continue;

      spots.add(FlSpot(tReq, velocity));
    }

    setState(() {});
  }

  // ===========================
  // Heat required
  // ===========================
  double calculateHeatRequired(double tReq) {
    final tAir = widget.tempAir;
    final deltaT = tReq - tAir;

    if (deltaT.abs() < 1e-9) return 0;

    final radiation =
        5.67e-8 * 0.8 * (pow(tReq + 273.0, 4) - pow(tAir + 273.0, 4));

    final heat = (widget.qFlux - radiation) / deltaT;

    if (!heat.isFinite) return 0;

    return heat;
  }

  // ===========================
// Cooling velocity
// ===========================
double calculateCoolingVelocity(double tReq, double heatRequired) {
  final tAir = widget.tempAir;

  // Mean temperature (°C)
  final tMeanC = (tReq + tAir) / 2.0;

  // Mean temperature (K)
  final tMeanK = tMeanC + 273.15;

  // Characteristic length
  final l = widget.lChar;

  if (l <= 0) return 0;

  // Air properties
  const pr = 0.70;

  // Thermal conductivity (W/m.K)
  final kAir = 0.024 + (7e-5 * tMeanC);

  // Dynamic viscosity (kg/m.s)
  final mu = 1.716e-5 * pow(tMeanK / 273.15, 1.5) *
      ((273.15 + 111) / (tMeanK + 111));

  // Density (kg/m³)
  final rho = 353 / tMeanK;

  if (kAir <= 0 || rho <= 0 || mu <= 0) return 0;

  // Formula:
  // Vreq = [(Hconv*L)/(0.023*Pr^0.4*Kair)]^(10/8) * (mu/(rho*L))

  final term =
      (heatRequired * l) /
      (0.023 * pow(pr, 0.4) * kAir);

  if (term <= 0) return 0;

  final velocity =
      pow(term, 10 / 8) *
      (mu / (rho * l));

  if (!velocity.isFinite || velocity <= 0) return 0;

  return velocity.toDouble();
}
  // ===========================
  // Y range
  // ===========================
  double getMinY() {
    if (spots.isEmpty) return 0;
    return spots.map((e) => e.y).reduce(min);
  }

  double getMaxY() {
    if (spots.isEmpty) return 10;
    return spots.map((e) => e.y).reduce(max);
  }

  // ===========================
  // UI
  // ===========================
  @override
  Widget build(BuildContext context) {
    final minY = getMinY();
    final maxY = getMaxY();
    final padding = (maxY - minY) * 0.2;

    return Column(
      children: [
        const SizedBox(height: 10),

        

        // ✅ ขยายพื้นที่ + กัน label โดนตัด
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 12, 40),
            child: spots.isEmpty
                ? const Center(
                    child: Text(
                      "No graph data",
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      clipData: const FlClipData.none(), // 🔥 เพิ่มบรรทัดนี้
                      backgroundColor: Colors.white,

                      minX: 100,
                      maxX: 650,
                      minY: minY - padding,
                      maxY: maxY + padding,

                      // GRID
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        drawHorizontalLine: true,
                        horizontalInterval: (maxY - minY) / 5,
                        verticalInterval: 100,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.2),
                          strokeWidth: 1,
                          dashArray: [6, 4], // 🔥 เส้นประ
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.15),
                          strokeWidth: 1,
                          dashArray: [6, 4], // 🔥 เส้นประ
                        ),
                      ),

                      // BORDER
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),

                      // LINE
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.2, // 👈 เพิ่มตรงนี้
                          barWidth: 3.5,
                          isStrokeCapRound: true,
                          gradient: const LinearGradient(
                            colors: [Colors.cyan, Colors.blue],
                          ),
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan.withValues(alpha: 0.25),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],

                      // TOUCH
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (spot) => Colors.black87,
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                "T: ${spot.x.toStringAsFixed(1)}°C\n"
                                "V: ${spot.y.toStringAsFixed(2)} m/s",
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        touchCallback: (event, response) {
                          if (response == null ||
                              response.lineBarSpots == null ||
                              response.lineBarSpots!.isEmpty) {
                            return;
                          }

                          final spot = response.lineBarSpots!.first;

                          setState(() {
                            touchX = spot.x;
                            touchY = spot.y;
                          });
                        },
                      ),

                      // CROSSHAIR
                      extraLinesData: ExtraLinesData(
                        verticalLines: touchX == null
                            ? []
                            : [
                                VerticalLine(
                                  x: touchX!,
                                  color: Colors.cyan.withValues(alpha: 0.8),
                                  strokeWidth: 1.2,
                                  dashArray: [5, 5],
                                ),
                              ],
                        horizontalLines: touchY == null
                            ? []
                            : [
                                HorizontalLine(
                                  y: touchY!,
                                  color: Colors.cyan.withValues(alpha: 0.8),
                                  strokeWidth: 1.2,
                                  dashArray: [5, 5],
                                ),
                              ],
                      ),

                      // TITLES
                      titlesData: FlTitlesData(
                        bottomTitles: const AxisTitles(
                          axisNameSize: 40, // 🔥 เพิ่ม
                          axisNameWidget: Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              "Temp Required (°C)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: 100,
                          ),
                        ),

                        leftTitles: AxisTitles(
                          axisNameSize: 40, // 🔥 เพิ่มบรรทัดนี้
                          axisNameWidget: const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(
                              "Cooling Velocity (m/s)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 50, // 👈 step ทีละ 50
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(), // 👈 ไม่มีทศนิยม
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),

                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 10),

        // ✅ ไม่ใช้ ...[] → ป้องกัน error
        if (touchX != null && touchY != null)
          Column(
            children: [
              Text(
                "T = ${touchX!.toStringAsFixed(1)} °C | "
                "V = ${touchY!.toStringAsFixed(2)} m/s",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
            ],
          ),
      ],
    );
  }
}
