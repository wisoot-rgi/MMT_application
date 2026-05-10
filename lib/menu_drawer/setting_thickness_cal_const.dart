import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThicknessConstPage extends StatefulWidget {
  const ThicknessConstPage({super.key});

  @override
  State<ThicknessConstPage> createState() => _ThicknessConstPageState();
}

class _ThicknessConstPageState extends State<ThicknessConstPage> {
  final patchThk = TextEditingController(text: "75");
  final airGap = TextEditingController(text: "1");

  final kTank = TextEditingController(text: "2.8");
  final kPatch = TextEditingController(text: "2.5");
  final kAir = TextEditingController(text: "0.03");

  final width = TextEditingController(text: "400");
  final height = TextEditingController(text: "200");

  String tankMaterial = "Fused Cast";
  String patchMaterial = "Chrome";

  // ==========================
  // SAVE
  // ==========================
  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble("patchThk", double.tryParse(patchThk.text) ?? 75);

    await prefs.setDouble("airGap", double.tryParse(airGap.text) ?? 1);

    await prefs.setDouble("kTank", double.tryParse(kTank.text) ?? 2.8);

    await prefs.setDouble("kPatch", double.tryParse(kPatch.text) ?? 2.5);

    await prefs.setDouble("kAir", double.tryParse(kAir.text) ?? 0.03);

    await prefs.setString("tankMaterial", tankMaterial);
    await prefs.setString("patchMaterial", patchMaterial);
  }

  // ==========================
  // LOAD
  // ==========================
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    patchThk.text = (prefs.getDouble("patchThk") ?? 75).toString();

    airGap.text = (prefs.getDouble("airGap") ?? 1).toString();

    kTank.text = (prefs.getDouble("kTank") ?? 2.8).toString();

    kPatch.text = (prefs.getDouble("kPatch") ?? 2.5).toString();

    kAir.text = (prefs.getDouble("kAir") ?? 0.03).toString();

    tankMaterial = prefs.getString("tankMaterial") ?? "Fused Cast";

    patchMaterial = prefs.getString("patchMaterial") ?? "Chrome";

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    loadFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    double w = double.tryParse(width.text) ?? 0;
    double h = double.tryParse(height.text) ?? 0;
    double area = (w * h) / 1000000;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Thickness Constant"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final navigator = Navigator.of(context);

              await saveToStorage();

              if (!mounted) return;

              navigator.pop(true);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildTitle("1. Material"),
          buildCard([
            buildDropdown("Tank", tankMaterial, [
              "Fused Cast",
              "AZS",
            ], (v) => tankMaterial = v!),
            buildDropdown("Patching", patchMaterial, [
              "Chrome",
              "AZS",
            ], (v) => patchMaterial = v!),
            buildText("Patch Thickness (mm)", patchThk),
            buildText("Air Gap (mm)", airGap),
          ]),

          buildTitle("2. K Value"),
          buildCard([
            buildText("K Tank (W/m.K)", kTank),
            buildText("K Patching (W/m.K)", kPatch),
            buildText("K Air (W/m.K)", kAir),
          ]),

          buildTitle("3. Cooling Area"),
          buildCard([
            buildText("Width (mm)", width),
            buildText("Height (mm)", height),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Area = ${area.toStringAsFixed(3)} m²",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget buildTitle(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    ),
  );

  Widget buildCard(List<Widget> children) => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: children),
    ),
  );

  Widget buildText(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (_) => setState(() {}),
    ),
  );

  Widget buildDropdown(
    String label,
    String selectedValue,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          setState(() {
            onChanged(v);
          });
        },
      ),
    );
  }
}
