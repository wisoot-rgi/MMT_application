import 'dart:io'; // 👈 สำคัญมาก
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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

  //---------------------------------
  // 👇 วางตรงนี้ได้เลย
  Future<void> saveToFile() async {
    final dir = await getApplicationDocumentsDirectory();

    final folder = Directory('${dir.path}/parameter');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final file = File('${folder.path}/cal_thickness_const.txt');

    String data =
        '''
patchThk=${patchThk.text}
airGap=${airGap.text}
kTank=${kTank.text}
kPatch=${kPatch.text}
kAir=${kAir.text}
''';

    await file.writeAsString(data);
    debugPrint("Saved file at: ${file.path}");
  }

  //---------------------------------
  Future<void> loadFromFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/parameter/cal_thickness_const.txt');

    if (await file.exists()) {
      final content = await file.readAsString();

      final lines = content.split('\n');

      for (var line in lines) {
        if (line.contains('=')) {
          final parts = line.split('=');
          final key = parts[0].trim();
          final value = parts[1].trim();

          switch (key) {
            case 'patchThk':
              patchThk.text = value;
              break;
            case 'airGap':
              airGap.text = value;
              break;
            case 'kTank':
              kTank.text = value;
              break;
            case 'kPatch':
              kPatch.text = value;
              break;
            case 'kAir':
              kAir.text = value;
              break;
          }
        }
      }

      setState(() {});
    }
  }

  //---------------------------------
  @override
  void initState() {
    super.initState();
    loadFromFile(); // ✅ โหลดทันที
  }

  //---------------------------------
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
              await saveToFile();
              
              if (!context.mounted) return; // ✅ แก้ warning ตรงจุด

              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildTitle("1. Material"),
          buildCard([
            buildDropdown("Tank", [
              "Fused Cast",
              "AZS",
            ], (v) => tankMaterial = v!),
            buildDropdown("Patching", [
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
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: items.first,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
