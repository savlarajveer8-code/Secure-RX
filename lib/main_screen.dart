
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'prescription_page.dart';
import 'verification_page.dart';
import 'history_page.dart';

class Medication {
  final String name;
  final String dosage;
  final String time;
  final String type;
  final String? notes;

  bool taken;
  bool verified;
  bool missed;
  DateTime? takenTime;

  Medication({
    required this.name,
    required this.dosage,
    required this.time,
    required this.type,
    this.notes,
    this.taken = false,
    this.verified = false,
    this.missed = false,
    this.takenTime,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTab = 0;
  bool _canAccessVerification = false;

  final List<Medication> _globalMedications = [];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        myMedications: _globalMedications,
        onLockStatusChanged: (bool allowed) {
          _canAccessVerification = allowed;
        },
      ),
      MedicationScreen(myMedications: _globalMedications),
      VerificationScreen(myMedications: _globalMedications),
      HistoryPage(myMedications: _globalMedications),
    ];

    return Scaffold(
      body: pages[_currentTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 2 && !_canAccessVerification) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "🔒 Verification Tab Locked. Please use the "
                  "'Verify Medication' button on Home during "
                  "your active verification window.",
                ),
                backgroundColor: Colors.redAccent,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }

          setState(() {
            _currentTab = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Meds',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.safety_check),
            label: 'Verify',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
