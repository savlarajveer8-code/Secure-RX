import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {

  Future<String> scanText(String imagePath) async {

    final inputImage = InputImage.fromFilePath(imagePath);

    final textRecognizer =
        TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    return recognizedText.text;
  }
}