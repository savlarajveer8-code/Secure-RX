import 'package:flutter/material.dart';
import 'main_screen.dart'; 
import 'notification.dart'; 

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();

  
  await NotificationService.init();

  runApp(const MedLockApp());
}

class MedLockApp extends StatelessWidget {
  const MedLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(), 
    );
  }
}