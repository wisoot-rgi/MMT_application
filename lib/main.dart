import 'package:flutter/material.dart';
import 'package:flutter_application_mmt/home.dart';
import 'menu_drawer/setting_thickness_cal_const.dart'; // ✅ import ใหม่
import 'menu_bottom_navigation/input_thickness.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MMT App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}



// ================= HOME =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    //Center(child: Text("Home Page")),
    Home(),
    Center(child: Text("Cooling Page")),
    Center(child: Text("Machine Page")),
    Center(child: Text("Utility Page")),
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InputThicknessPage(),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bangkok Glass PCL Application"),
      ),

      // ================= DRAWER =================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'BG Menu',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 0);
              },
            ),

            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () => Navigator.pop(context),
            ),

            ExpansionTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 32),
                  leading:
                      const Icon(Icons.straighten, color: Colors.blue),
                  title: const Text("Thickness Cal Const"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ThicknessConstPage(), // ✅ เรียกจากไฟล์ใหม่
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      // ================= BODY =================
      body: _pages[_selectedIndex],


      // ================= BOTTOM NAV =================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.straighten),
            label: 'Thickness Calc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.precision_manufacturing),
            label: 'Machine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Utility',
          ),
        ],
      ),
    );
  }
}

