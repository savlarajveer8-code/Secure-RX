// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'main_screen.dart'; 
import 'notification.dart';


// ==========================================
// THE MEDICATION SCREEN WIDGET
// ==========================================
class MedicationScreen extends StatefulWidget {
  final List<Medication> myMedications;

  const MedicationScreen({super.key, required this.myMedications});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  // Digital pens to grab text out of inputs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  
  String _selectedType = "Solid (Pill, Capsule, Tablet)";

  // Function that opens up the visual clock wheel
  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Function that rips a medicine off our list
  void _deleteMedication(int index) {
    setState(() {
      widget.myMedications.removeAt(index); 
    });
  }

  // Function that opens up the input pop-up card
  void _showAddMedicationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add New Medication',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Medication Name *'),
                    ),
                    TextField(
                      controller: _dosageController,
                      decoration: const InputDecoration(labelText: 'Dosage (e.g., 500) *'),
                      keyboardType: TextInputType.number, 
                    ),
                    
                    const SizedBox(height: 15),

                    // FIX: Changed 'value' to 'initialValue' to fix the deprecation error
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType, 
                      decoration: const InputDecoration(
                        labelText: 'Medication Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Solid (Pill, Capsule, Tablet)",
                          child: Text("💊 Solid (Pill/Capsule)"),
                        ),
                        DropdownMenuItem(
                          value: "Liquid / Injectable (Syrup, Vial, Injection)",
                          child: Text("🧪 Liquid / Injectable"),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            _selectedType = newValue; 
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () => _pickDate(context), 
                      child: AbsorbPointer( 
                        child: TextField(
                          controller: _dateController,
                          decoration: const InputDecoration(
                            labelText: 'Medication Date *',
                            suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
                          ),
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () => _pickTime(context), 
                      child: AbsorbPointer( 
                        child: TextField(
                          controller: _timeController,
                          decoration: const InputDecoration(
                            labelText: 'Select Medication Time *',
                            suffixIcon: Icon(Icons.access_time, color: Colors.blue),
                        ),
                      ),
                    ),
                  ),

                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearControllers();
                    Navigator.pop(context); 
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async { // <-- 2. Added 'async' here
                    if (_nameController.text.isNotEmpty &&
                        _dosageController.text.isNotEmpty &&
                        _timeController.text.isNotEmpty &&
                        _dateController.text.isNotEmpty) {
                      
                      setState(() {
                        widget.myMedications.add(
                          Medication(
                            name: _nameController.text,
                            dosage: _dosageController.text,
                            time: _timeController.text,
                            // FIX: Added the 'type' argument here so main_screen stays happy
                            type: _selectedType, 
                            notes: "Start Date: ${_dateController.text}\nNotes: ${_notesController.text}",
                          ),
                        );
                      });

                      // ------------------------------------------------------------------
                      // 3. MINIMAL NOTIFICATION CODE ADDED HERE:
                      // ------------------------------------------------------------------
                      try {
                        // Directly parses using primitive tools to avoid breaking your code
                        final parsedDate = DateTime.parse(_dateController.text);
                        int hour = int.parse(_timeController.text.split(":")[0]);
                        final minute = int.parse(_timeController.text.split(":")[1].split(" ")[0]);
                        final isPm = _timeController.text.toLowerCase().contains("pm");
                        
                        if (isPm && hour < 12) hour += 12;
                        if (!isPm && hour == 12) hour = 0;

                        final finalDateTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);

                        print("Scheduling notification for: $finalDateTime");
                        debugPrint('ABOUT TO SCHEDULE MEDICATION REMINDER');
debugPrint('Medication time: $finalDateTime');
                        await NotificationService.scheduleNotification(
                          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                          title: "💊 SecureRx Reminder",
                          body: "It's time for your ${_nameController.text} (${_dosageController.text}mg)!",
                          scheduledDateTime: finalDateTime,
                        );
                        print("notification schedules!");
                      } catch (e, stackTrace) {
                        debugPrint("Notification scheduling failed: $e");
                        debugPrintStack(stackTrace: stackTrace);
}
                      // ------------------------------------------------------------------
                    
                      _clearControllers();
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _clearControllers() {
    _nameController.clear();
    _dosageController.clear();
    _timeController.clear();
    _notesController.clear();
    _dateController.clear();
    _selectedType = "Solid (Pill, Capsule, Tablet)";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    _dateController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 186, 208, 241),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Medications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Prescription Boarding",
              style: TextStyle(
                fontSize: 26,
                color: Color.fromARGB(255, 24, 54, 79),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddMedicationDialog,
                icon: const Icon(Icons.add),
                label: const Text(
                  "Add New Medicine",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Your Schedule",
              style: TextStyle(
                fontSize: 20,
                color: Color.fromARGB(255, 24, 54, 79),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: widget.myMedications.where((med) => !med.taken).isEmpty
                  ? Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "No medications added yet.\nClick 'Add New Medicine' to start!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.myMedications
                        .where((med) => !med.taken)
                        .length,
                        
                      itemBuilder: (context, index) {
                        final visibleMedications = widget.myMedications
                            .where((med) => !med.taken)
                            .toList();

                        final currentMed = visibleMedications[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.medication, color: Colors.white),
                            ),
                            title: Text(
                              "${currentMed.name} (${currentMed.dosage})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Time: ${currentMed.time}"),
                                // Displaying the type explicitly in the UI card list
                                Text("Form: ${currentMed.type}", style: const TextStyle(fontWeight: FontWeight.w500)),
                                if (currentMed.notes != null)
                                  Text(
                                    "${currentMed.notes}",
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                _deleteMedication(index); 
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}