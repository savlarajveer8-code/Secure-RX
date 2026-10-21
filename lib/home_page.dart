
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'verification_page.dart';

class HomePage extends StatefulWidget {
  final List<Medication> myMedications;
  final ValueChanged<bool> onLockStatusChanged;

  const HomePage({
    super.key,
    required this.myMedications,
    required this.onLockStatusChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver {
  static const String _caregiverKey = 'caregiver_phone_number';

  final TextEditingController _caregiverController =
      TextEditingController();

  String _caregiverNumber = '';
  bool _editingCaregiver = false;
  bool _loadingCaregiver = true;

  Timer? _missedCheckTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _loadCaregiverNumber();
    _checkForMissedMedications();

    _missedCheckTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkForMissedMedications(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForMissedMedications();
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadCaregiverNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNumber = prefs.getString(_caregiverKey) ?? '';

      if (!mounted) return;

      setState(() {
        _caregiverNumber = savedNumber;
        _caregiverController.text = savedNumber;
        _loadingCaregiver = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCaregiver = false);
    }
  }

  Future<void> _saveCaregiverNumber() async {
    final number = _caregiverController.text.trim();

    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a caregiver phone number.'),
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_caregiverKey, number);

      if (!mounted) return;

      setState(() {
        _caregiverNumber = number;
        _editingCaregiver = false;
      });

      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caregiver contact saved.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the caregiver contact.'),
        ),
      );
    }
  }

  void _editCaregiverNumber() {
    setState(() {
      _caregiverController.text = _caregiverNumber;
      _editingCaregiver = true;
    });
  }

  DateTime? _getFullDateTime(String notesStr, String timeStr) {
    try {
      if (!notesStr.contains('Start Date:')) return null;

      final dateLine = notesStr
          .split('\n')
          .firstWhere((line) => line.contains('Start Date:'));

      final datePart =
          dateLine.replaceAll('Start Date:', '').trim();

      final dateSegments = datePart.split('-');

      final year = int.parse(dateSegments[0]);
      final month = int.parse(dateSegments[1]);
      final day = int.parse(dateSegments[2]);

      String cleanTime = timeStr.trim().toUpperCase();

      final isPm = cleanTime.contains('PM');
      final isAm = cleanTime.contains('AM');

      cleanTime = cleanTime
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim();

      final timeSegments = cleanTime.split(':');

      int hour = int.parse(timeSegments[0]);
      final minute = int.parse(timeSegments[1]);

      if (isPm && hour != 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  void _checkForMissedMedications() {
    final now = DateTime.now();
    bool changed = false;

    for (final med in widget.myMedications) {
      if (med.taken || med.verified || med.missed) {
        continue;
      }

      final scheduled = _getFullDateTime(
        med.notes ?? '',
        med.time,
      );

      if (scheduled == null) continue;

      final deadline = scheduled.add(
        const Duration(minutes: 30),
      );

      if (now.isAfter(deadline)) {
        med.missed = true;
        changed = true;
      }
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _missedCheckTimer?.cancel();
    _caregiverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final activeMedications = widget.myMedications
        .where((med) => !med.taken && !med.missed && !med.verified)
        .toList();

    // Find a medication currently inside its verification window.
    Medication? eligibleMedication;

    for (final med in activeMedications) {
      final scheduled = _getFullDateTime(
        med.notes ?? '',
        med.time,
      );

      if (scheduled == null) continue;

      final unlockStart =
          scheduled.subtract(const Duration(minutes: 15));
      final unlockEnd =
          scheduled.add(const Duration(minutes: 30));

      if (!now.isBefore(unlockStart) &&
          !now.isAfter(unlockEnd)) {
        if (eligibleMedication == null) {
          eligibleMedication = med;
        } else {
          final currentScheduled = _getFullDateTime(
            eligibleMedication.notes ?? '',
            eligibleMedication.time,
          );

          if (currentScheduled == null ||
              scheduled.isBefore(currentScheduled)) {
            eligibleMedication = med;
          }
        }
      }
    }

    // If none is eligible yet, display the next upcoming medication.
    Medication? nextMedication = eligibleMedication;

    if (nextMedication == null) {
      DateTime? closestTime;

      for (final med in activeMedications) {
        final scheduled = _getFullDateTime(
          med.notes ?? '',
          med.time,
        );

        if (scheduled == null || !scheduled.isAfter(now)) {
          continue;
        }

        if (closestTime == null || scheduled.isBefore(closestTime)) {
          closestTime = scheduled;
          nextMedication = med;
        }
      }
    }

    // If no upcoming medication exists, show an active medication
    // for display only. This fallback does NOT unlock verification.
    nextMedication ??=
        activeMedications.isNotEmpty ? activeMedications.first : null;

    final bool hasMeds = nextMedication != null;
    final String medName =
        hasMeds ? nextMedication.name : 'No Medications';
    final String medDosage =
        hasMeds ? '(${nextMedication.dosage})' : '';
    final String medTime =
        hasMeds ? nextMedication.time : '--:--';

    final bool isUnlockAllowed = eligibleMedication != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onLockStatusChanged(isUnlockAllowed);
      }
    });

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 186, 208, 241),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Secure RX',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Your Health, Simplified',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                color: Color.fromARGB(255, 24, 54, 79),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Next Medication Card
            SizedBox(
              width: double.infinity,
              height: 250,
              child: Card(
                elevation: 12,
                shadowColor: const Color.fromARGB(255, 6, 54, 94),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NEXT MEDICATION',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '💊 $medName $medDosage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '🕗 $medTime',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Medication Verification Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUnlockAllowed
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VerificationScreen(
                              myMedications: widget.myMedications,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUnlockAllowed
                      ? const Color.fromARGB(255, 2, 134, 123)
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  isUnlockAllowed
                      ? 'Verify Medication'
                      : 'Locked Until Scheduled Window',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Caregiver Contact Card
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 8,
                shadowColor: const Color.fromARGB(255, 6, 54, 94),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.contact_phone,
                            color: Colors.blue,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Caregiver Contact',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 24, 54, 79),
                              ),
                            ),
                          ),
                          if (!_loadingCaregiver && !_editingCaregiver)
                            TextButton.icon(
                              onPressed: _editCaregiverNumber,
                              icon: const Icon(Icons.edit, size: 17),
                              label: Text(
                                _caregiverNumber.isEmpty ? 'Add' : 'Edit',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_loadingCaregiver)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else if (_editingCaregiver)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Caregiver phone number',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _caregiverController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: 'Enter phone number',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _caregiverController.text =
                                            _caregiverNumber;
                                        _editingCaregiver = false;
                                      });
                                      FocusScope.of(context).unfocus();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _saveCaregiverNumber,
                                    icon: const Icon(Icons.save),
                                    label: const Text('Save'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _caregiverNumber.isEmpty
                                    ? 'No caregiver number added yet.'
                                    : _caregiverNumber,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _caregiverNumber.isEmpty
                                      ? Colors.black54
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
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
