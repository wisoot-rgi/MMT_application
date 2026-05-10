import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_mmt/cooling_graph.dart';
import 'package:flutter_application_mmt/menu_drawer/setting_thickness_cal_const.dart';
import 'package:flutter_application_mmt/model/cal_thickness.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:flutter_application_mmt/menu_drawer/setting_thickness_cal_const.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InputThicknessPage extends StatefulWidget {
  const InputThicknessPage({super.key});

  @override
  State<InputThicknessPage> createState() => _InputThicknessPageState();
}

class _InputThicknessPageState extends State<InputThicknessPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final widthController = TextEditingController();
  final heightController = TextEditingController();
  final velocityController = TextEditingController();

  final tempInsideController = TextEditingController();
  final tempOutsideController = TextEditingController();
  final tempAirController = TextEditingController();

  String patchingType = "Non-Patching";
  //String resultText = "";
  List<String> results = [];
  double nozzleArea = 0;
  double lastQFlux = 0;
  double lastLChar = 0;
  double lastTempAir = 0;

  //------------Nozzle area calculation ----------------
  void calculateAreaIfReady() {
    final widthText = widthController.text;
    final heightText = heightController.text;

    if (widthText.isEmpty || heightText.isEmpty) {
      setState(() {
        nozzleArea = 0;
      });
      return;
    }

    final width = double.tryParse(widthText);
    final height = double.tryParse(heightText);

    if (width == null || height == null) return;

    setState(() {
      nozzleArea = (width * height) / 1000000;
    });
  }

  //--------------------------------------------------------
  // ✅ เก็บค่าที่ load มา
  double patchThk = 0;
  double airGap = 0;
  double kTank = 0;
  double kPatch = 0;

  // =====================================================
  // ✅ วางฟังก์ชันนี้ตรงนี้ (หลังตัวแปร / ก่อน build ก็ได้)
  // =====================================================
  Future<void> loadConstants() async {
    final prefs = await SharedPreferences.getInstance();

    // ❌ ห้ามใช้ _patchThk
    // ✅ ใช้แบบนี้แทน
    double patchThkVal = prefs.getDouble("patchThk") ?? 75;
    double airGapVal = prefs.getDouble("airGap") ?? 1;
    double kTankVal = prefs.getDouble("kTank") ?? 5;
    double kPatchVal = prefs.getDouble("kPatch") ?? 2.5;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/parameter/cal_thickness_const.txt');

      if (await file.exists()) {
        final content = await file.readAsString();
        final lines = content.split('\n');

        for (var line in lines) {
          if (!line.contains('=')) continue;

          final parts = line.split('=');
          final key = parts[0].trim();
          final value = double.tryParse(parts[1].trim());

          if (value == null) continue;

          switch (key) {
            case 'patchThk':
              patchThkVal = value;
              break;
            case 'airGap':
              airGapVal = value;
              break;
            case 'kTank':
              kTankVal = value;
              break;
            case 'kPatch':
              kPatchVal = value;
              break;
          }
        }
      }
    } catch (e) {
      debugPrint("Load error: $e");
    }

    setState(() {
      patchThk = patchThkVal;
      airGap = airGapVal;
      kTank = kTankVal;
      kPatch = kPatchVal;
    });
  }

  //---------------------------------
  bool isInputValid() {
    return widthController.text.isNotEmpty &&
        heightController.text.isNotEmpty &&
        velocityController.text.isNotEmpty &&
        tempInsideController.text.isNotEmpty &&
        tempOutsideController.text.isNotEmpty &&
        tempAirController.text.isNotEmpty;
  }

  void tryAutoCalculate() {
    if (!mounted) return;

    if (_formKey.currentState?.validate() ?? false) {
      _handleCalculate();
    } else {
      debugPrint("⚠️ Input not complete → skip auto calculate");
    }
  }

  //---------------------------------

  @override
  void initState() {
    super.initState();
    loadConstants(); // ✅ โหลดทันที
  }

  //================ graph =============================================
  void showCoolingGraph() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 12, // 👈 ขยายชิดขอบจอ
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: double.infinity, // 👈 เต็มความกว้าง
          height: MediaQuery.of(context).size.height * 0.85, // 👈 สูง 85% จอ
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), // 👈 เพิ่มล่าง
            child: Column(
              children: [
                // 🔹 Header
                const Text(
                  "Cooling Graph",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                // 🔹 Graph
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 8, // 👈 กันแกน Y ชิด
                      right: 8,
                      bottom: 12, // 👈 กันแกน X โดนตัด
                    ),
                    child: CoolingGraphWidget(
                      qFlux: lastQFlux,
                      lChar: lastLChar,
                      tempAir: lastTempAir,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  //--------------graph widget -------------------------------------

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Thickness Calculation"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          //----------------------------
          // 👉 ปุ่มไปหน้า Setting
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThicknessConstPage(),
                ),
              );

              // ✅ กลับมาแล้ว reload ค่าใหม่
              await loadConstants();
              tryAutoCalculate(); // ✅ auto calculate
            },
          ),
          //-----------------------------
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              if (lastQFlux == 0 || lastLChar == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please calculate first")),
                );
                return;
              }

              showCoolingGraph();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildSectionTitle("1. Nozzle"),
              buildNozzleCard(),

              buildSectionTitle("2. Air Velocity"),
              buildVelocityCard(),

              buildSectionTitle("3. Temperature"),
              buildTempCard(),

              buildSectionTitle("Result"),

              Card(
                color: Colors.blue.shade700,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: results.isEmpty
                        ? [
                            buildBulletText(
                              "Calculation result will appear here",
                            ),
                          ]
                        : results.map((e) => buildBulletText(e)).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              buildCalculateButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- UI Components ----------------

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget buildNozzleCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: buildTextField(
                    "Width (mm)",
                    widthController,
                    onChanged: calculateAreaIfReady,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: buildTextField(
                    "Height (mm)",
                    heightController,
                    onChanged: calculateAreaIfReady,
                  ),
                ),
              ],
            ),
            buildAreaDisplay(),
          ],
        ),
      ),
    );
  }

  Widget buildAreaDisplay() {
    return Text(
      nozzleArea > 0
          ? "Area = ${nozzleArea.toStringAsFixed(4)} m²"
          : "Area = -",
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Widget buildVelocityCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: buildTextField("Velocity (m/s)", velocityController),
      ),
    );
  }

  Widget buildTempCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            buildTextField("Inside (°C)", tempInsideController),
            buildTextField("Outside (°C)", tempOutsideController),
            buildTextField("Air (°C)", tempAirController),
            const SizedBox(height: 10),
            buildPatchingSelector(),
          ],
        ),
      ),
    );
  }

  Widget buildPatchingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Patching", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: buildOptionCard("Non-Patching")),
            const SizedBox(width: 10),
            Expanded(child: buildOptionCard("With-Patching")),
          ],
        ),
      ],
    );
  }

  Widget buildOptionCard(String value) {
    final isSelected = patchingType == value;

    Color activeColor = value == "With-Patching" ? Colors.orange : Colors.green;

    return GestureDetector(
      onTap: () => setState(() => patchingType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              value == "With-Patching"
                  ? Icons.build_circle
                  : Icons.check_circle_outline,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBulletText(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6, right: 8),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget buildCalculateButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blue,
      ),
      onPressed: _handleCalculate,
      child: const Text("Calculate", style: TextStyle(fontSize: 18)),
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    VoidCallback? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.isEmpty ? "Required" : null,
        onChanged: (_) {
          if (onChanged != null) onChanged();
        },
      ),
    );
  }

  // =========================================================
  // 🔥 CALCULATION SECTION (แยกชัดเจน)
  // =========================================================

  final formatter = NumberFormat("#,##0.###");

  void _handleCalculate() {
    if (!_formKey.currentState!.validate()) return;
    if (!isInputValid()) return;

    final width = double.tryParse(widthController.text) ?? 0;
    final height = double.tryParse(heightController.text) ?? 0;
    final velocity = double.tryParse(velocityController.text) ?? 0;
    final tempAir = double.tryParse(tempAirController.text) ?? 0;
    final tempOutside = double.tryParse(tempOutsideController.text) ?? 0;
    final tempInside = double.tryParse(tempInsideController.text) ?? 0;

    // Characteristic Length
    final lChar = CalThickness.calculateLCharacteristic(
      width: width,
      height: height,
    );

    // Reynolds
    final reynolds = CalThickness.calculateReynolds(
      velocity: velocity,
      tempAir: tempAir,
      tempOutside: tempOutside,
      lChar: lChar,
    );

    // Nusselt
    final nusselt = CalThickness.calculateNusselt(reynolds);

    // Convection
    final hConv = CalThickness.calculateHConv(
      nusselt: nusselt,
      tempOutside: tempOutside,
      tempAir: tempAir,
      lChar: lChar,
    );

    // Radiation
    final hRad = CalThickness.calculateHRad(
      tempOutside: tempOutside,
      tempAir: tempAir,
    );

    final hTotal = CalThickness.calculateHTotal(hConv: hConv, hRad: hRad);

    final qFlux = CalThickness.calculateQFlux(
      hTotal: hTotal,
      tempOutside: tempOutside,
      tempAir: tempAir,
    );

    if (qFlux == 0) return;

    final rTotal = CalThickness.calculateResistance(
      tempInside: tempInside,
      tempOutside: tempOutside,
      qFlux: qFlux,
    );

    double tankThk = 0;

    double chromeInnerTemp = 0;
    double rGap = 0;
    double rChrome = 0;
    double rAZS = 0;

    double kAir = 0;
    double kRad = 0;
    double kAirGap = 0;

    if (patchingType == "Non-Patching") {
      tankThk = CalThickness.calculateAZSThickness(
        resistance: rTotal,
        kTank: kTank,
      );
    } else {
      // Chrome inner temperature
      chromeInnerTemp = tempOutside + (qFlux * (patchThk / 1000) / kPatch);

      // Air gap thickness (m)
      final lGap = airGap / 1000;

      // -------------------------------------
      // ตามสูตร Excel
      // T air gap = T chrome inner (°C)
      // -------------------------------------

      final tAirGap = chromeInnerTemp;

      // K air ใช้ °C
      kAir = 0.024 + (7e-5 * tAirGap);

      // Mean temperature สำหรับ radiation (Kelvin)
      final tm = tAirGap + 273.15;

      // Radiation conductivity
      const sigma = 5.67e-8;
      kRad = 4 * sigma * lGap * tm * tm * tm*0; //cancelled K rad

      // Total air-gap conductivity
      kAirGap = kAir + kRad;

      // Resistances
      rGap = lGap / kAirGap;
      rChrome = (patchThk / 1000) / kPatch;
      rAZS = rTotal - rGap - rChrome;

      // Tank thickness
      tankThk = rAZS * kTank * 1000;

      // Debug
      debugPrint("T air gap (°C) = $tAirGap");
      debugPrint("Tm (K) = $tm");
      debugPrint("K air = $kAir");
      debugPrint("K rad = $kRad");
      debugPrint("K air gap = $kAirGap");
      debugPrint("R gap = $rGap");
    }

    // Graph
    lastQFlux = qFlux;
    lastLChar = lChar;
    lastTempAir = tempAir;

    if (tankThk > 250 && mounted) {
      Future.microtask(() => showWarningDialog(tankThk));
    }

    setState(() {
      String tankDisplay;

      if (patchingType == "Non-Patching") {
        tankDisplay = "${tankThk.toStringAsFixed(2)} mm";
      } else {
        double tankPart;
        double patchPart;

        if (tankThk < 0) {
          tankPart = 0;
          patchPart = patchThk + tankThk;
        } else {
          tankPart = tankThk;
          patchPart = patchThk;
        }

        tankDisplay =
            "${tankPart.toStringAsFixed(2)} / "
            "${patchPart.toStringAsFixed(2)} mm "
            "[tank / patching]";
      }

      results = [
        "L_characteristic = ${formatter.format(lChar)} m",
        "Reynolds number = ${formatter.format(reynolds)}",
        "Nusselt number = ${formatter.format(nusselt)}",
        "H conv = ${formatter.format(hConv)} W/m²·K",
        "H rad = ${formatter.format(hRad)} W/m²·K",
        "H total = ${formatter.format(hTotal)} W/m²·K",
        "Q flux = ${formatter.format(qFlux)} W/m²",

        if (patchingType == "With-Patching") ...[
          "T chrome inner = ${formatter.format(chromeInnerTemp)} °C",
          "R total = ${formatter.format(rTotal)} m²·K/W",
          //"K air = ${formatter.format(kAir)} W/m·K",
          //"K rad = ${formatter.format(kRad)} W/m·K",
          //"K air gap = ${formatter.format(kAirGap)} W/m·K",
          //"R air gap = ${formatter.format(rGap)} m²·K/W",
          //"R chrome = ${formatter.format(rChrome)} m²·K/W",
          "R AZS = ${formatter.format(rAZS)} m²·K/W",
        ],

        "Tank Thickness = $tankDisplay",
      ];
    });
  }

  //----------------- Dialog messages --------
  void showWarningDialog(double tankThk) {
    showDialog(
      context: context,
      barrierDismissible: false, // ❗ บังคับให้ user กด OK
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔶 ICON
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
              ),

              const SizedBox(height: 16),

              // 🔴 TITLE
              const Text(
                "WARNING",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              // 📌 CASE DESCRIPTION
              const Text(
                "Tank Thickness exceeds limit",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),

              const SizedBox(height: 16),

              // 📊 VALUE BOX
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Calculated Thickness",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${tankThk.toStringAsFixed(2)} mm",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 📌 MESSAGE
              const Text(
                "Please check the input parameters again.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 20),

              // 🔘 BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ThicknessConstPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- CLEANUP ----------------
  @override
  void dispose() {
    widthController.dispose();
    heightController.dispose();
    velocityController.dispose();
    tempInsideController.dispose();
    tempOutsideController.dispose();
    tempAirController.dispose();
    super.dispose();
  }
}
