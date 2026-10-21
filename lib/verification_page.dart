// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'ocr_service.dart';

class VerificationScreen extends StatefulWidget {
  final List<Medication> myMedications;
  

  const VerificationScreen({
    super.key,
    required this.myMedications,
    
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {

  bool _hasScanned = false;
  bool _verified = false;
  bool _correctMedication = false;

  String _scannedText = "";
  String _scannedMedication = "";
  // ignore: prefer_final_fields, unused_field
  String _scannedDosage = "";

  String _scannedStrength = "";
  double? _scannedMg;
  double? _scannedMl;

  double? _calculatedAmount;
  String _calculatedUnit = "";

DateTime? _getFullDateTime(String notesStr, String timeStr) {
  try {

    final datePart = notesStr
        .split("Start Date:")
        .last
        .trim()
        .split("\n")[0];

    final date = datePart.split("-");

    int year = int.parse(date[0]);
    int month = int.parse(date[1]);
    int day = int.parse(date[2]);

    String cleanTime = timeStr
        .replaceAll("AM", "")
        .replaceAll("PM", "")
        .trim();

    final time = cleanTime.split(":");

    int hour = int.parse(time[0]);
    int minute = int.parse(time[1]);

    if (timeStr.contains("PM") && hour != 12) {
      hour += 12;
    }

    if (timeStr.contains("AM") && hour == 12) {
      hour = 0;
    }

    return DateTime(
      year,
      month,
      day,
      hour,
      minute,
    );

  } catch (e) {
    return null;
  }
}

 Medication? get _expectedMedication {

  final now = DateTime.now();

  Medication? nextMedication;

  for (var med in widget.myMedications) {

    final medDateTime = _getFullDateTime(
      med.notes ?? "",
      med.time,
    );

    if (medDateTime == null) continue;

    final difference = medDateTime.difference(now).inMinutes;

    if (difference >= -30 && difference <= 15) {
      nextMedication = med;
      break;
    }
  }

  return nextMedication;
}
  
  // Opens the camera and scans the prescription bottle
Future<void> _scanBottle() async {

  // Creates an ImagePicker object
  final picker = ImagePicker();

  // Opens the camera
  final image = await picker.pickImage(
    source: ImageSource.camera,
  );

  // If the user cancels the camera,
  // stops the function.
  if (image == null) return;

  // Sends the picture to OCR
  final scannedText =
      await OCRService().scanText(image.path);

  // Updates the screen
  setState(() {

    _hasScanned = true;

    _scannedText = scannedText;

  print("OCR TEXT: $_scannedText");
  print("EXPECTED MED: ${_expectedMedication?.name}");

    if (_expectedMedication != null &&
    scannedText.toLowerCase().contains(
      _expectedMedication!.name.toLowerCase(),
    )) {
  _scannedMedication = _expectedMedication!.name;
}
    
    // Finds dosage 
    final mgMatch = RegExp(
      r'(\d+(\.\d+)?)\s*mg',
      caseSensitive: false,
    ).firstMatch(scannedText);

    if (mgMatch != null) {
      _scannedStrength = mgMatch.group(0)!;
      _scannedMg = double.parse(mgMatch.group(1)!);
}
    // Only extracts mL if the medication type is Liquid
    if (_expectedMedication != null &&
        _expectedMedication!.type.toLowerCase() == "liquid") {

      final mlMatch = RegExp(
        r'(\d+(\.\d+)?)\s*mg\s*/\s*(\d+(\.\d+)?)\s*mL',
        caseSensitive: false,
      ).firstMatch(scannedText);

      if (mlMatch != null) {
        _scannedMg = double.parse(mlMatch.group(1)!);
        _scannedMl = double.parse(mlMatch.group(3)!);

        _scannedStrength =
            "$_scannedMg mg / $_scannedMl mL";
      }
    }
   

    _verified = false;
    _correctMedication = false;

  });

}

  void _verifyMedication() {

  if (!_hasScanned || _expectedMedication == null) return;
  print("OCR TEXT: $_scannedText");
  print("EXPECTED MEDICATION: ${_expectedMedication!.name}");

  bool match =
      _scannedText
          .toLowerCase()
          .contains(
            _expectedMedication!.name.toLowerCase()
          );
  print("MATCH RESULT: $match");
  
  setState(() {
    _verified = true;
    _correctMedication = match;
  });
  if(match) {
    _expectedMedication!.verified =true;
    _calculateDose();
  }
}
  void _calculateDose() {

  if (_expectedMedication == null || _scannedMg == null) {
    return;
  }

  double prescribedDose =
      double.parse(
        _expectedMedication!.dosage
            .replaceAll(RegExp(r'[^0-9.]'), ''),
      );


  if (_expectedMedication!.type.toLowerCase() != "liquid") {

    double pills = prescribedDose / _scannedMg!;

    setState(() {
      _calculatedAmount = pills;
      _calculatedUnit = "tablets";
    });

  } else {

    if (_scannedMl == null) return;

    double mgPerMl = _scannedMg! / _scannedMl!;

    double mlNeeded = prescribedDose / mgPerMl;

    setState(() {
      _calculatedAmount = mlNeeded;
      _calculatedUnit = "mL";
    });

  }
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
          "Medication Verification",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Verify Your Medication",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 24, 54, 79),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),

              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(

                  children: [

                    const Icon(
                      Icons.camera_alt,
                      size: 70,
                      color: Colors.blue,
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "Scan Prescription Bottle",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Take a picture of your prescription bottle. The app will read the medication name and dosage automatically. Make sure the picture is clear, retake the picture if any text is not clear",
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton.icon(

                        icon: const Icon(Icons.camera_alt),

                        label: const Text(
                          "Open Camera",
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),

                        onPressed: _scanBottle,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(

                      children: [

                        Icon(
                          _hasScanned
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _hasScanned
                              ? Colors.green
                              : Colors.red,
                        ),

                        const SizedBox(width: 10),

                        Text(
                          _hasScanned
                              ? "Prescription Scanned"
                              : "No Prescription Scanned",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),

              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      "Detected Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "Medication: ${_scannedMedication.isEmpty ? "Not Detected" : _scannedMedication}",
                    ),

                    const SizedBox(height: 10),

                    
              
                    
                    const SizedBox(height: 10),

                    Text(
                      "Strength: ${_scannedStrength.isEmpty ? "Not Detected" : _scannedStrength}",
                    ),

                    

const SizedBox(height: 10),

Text(_scannedText),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(

                        onPressed:
                            _hasScanned
                                ? _verifyMedication
                                : null,

                        child: const Text(
                          "Verify Medication",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            if (_verified && !_correctMedication)
              Card(
                color: Colors.red[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(
                    color: Colors.red,
                    width: 1.5,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Verification Failed",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 15),

                      Text(
                        "The scanned prescription does not match the medication scheduled for this time.",
                        style: TextStyle(fontSize: 16),
                      ),

                      SizedBox(height: 10),

                      Text(
                        "Please scan the correct prescription bottle or try again.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_verified && _correctMedication)
              Card(
                color: Colors.green[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(
                    color: Colors.green,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Row(
                        children: [

                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 30,
                          ),

                          SizedBox(width: 10),

                          Text(
                            "Verification Successful",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),

                        ],
                      ),

                      const Divider(height: 25),

                      Text(
                        "Medication: ${_expectedMedication!.name}",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "The Dosage You Need To Take: ${_expectedMedication!.dosage} mg",
                        style: const TextStyle(fontSize: 14),
                      ),

                      const SizedBox(height: 8),

                      
                      const SizedBox(height: 12),

                      Text(
                        _calculatedAmount == null
                            ? "Dose could not be calculated."
                            : "Recommended Dose: ${_calculatedAmount!.toStringAsFixed(1)} $_calculatedUnit",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.assignment_turned_in),

                          label: const Text(
                            "Log Pill Taken",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),

                          onPressed: () {

                            _expectedMedication!.taken = true;
                            _expectedMedication!.verified = false;
                            _expectedMedication!.takenTime = DateTime.now();
                                TimeOfDay.now().format(context);

                            setState(() {});

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${_expectedMedication!.name} logged successfully!",
                                ),
                              ),
                            );

                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}
