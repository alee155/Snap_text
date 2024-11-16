import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snaptext/Widgets/button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String _extractedText = '';

  String _name = '';
  String _email = '';
  String _address = '';
  String _phoneNumber = '';
  String _otherDetails = '';

  bool _isCard = false;

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<void> _pickFromCamera() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _recognizeTextFromImage(pickedFile.path);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _recognizeTextFromImage(pickedFile.path);
    }
  }

  Future<void> _recognizeTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    setState(() {
      _extractedText = recognizedText.text;
    });

    _checkIfCard(_extractedText);
    _extractDetails(_extractedText);
  }

  void _checkIfCard(String text) {
    if (text.contains('CNIC') || RegExp(r'\d{5}-\d{7}-\d{1}').hasMatch(text)) {
      setState(() {
        _isCard = true;
      });
    } else {
      setState(() {
        _isCard = false;
      });
    }
  }

  void _extractDetails(String text) {
    final nameMatch = RegExp(r'([A-Za-z]+(?: [A-Za-z]+)*)').firstMatch(text);
    final emailMatch =
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b')
            .firstMatch(text);
    final phoneMatch = RegExp(
            r'\+?[0-9]{1,4}?[-.\s]?[0-9]{1,4}[-.\s]?[0-9]{1,4}[-.\s]?[0-9]{1,9}')
        .firstMatch(text);
    final addressMatch = RegExp(
            r'([0-9]{1,4}\s[A-Za-z]+(?:\s[A-Za-z]+)*,\s[A-Za-z]+,\s[A-Za-z]+)')
        .firstMatch(text);

    setState(() {
      _name = nameMatch?.group(0) ?? '';
      _email = emailMatch?.group(0) ?? '';
      _phoneNumber = phoneMatch?.group(0) ?? '';
      _address = addressMatch?.group(0) ?? '';
      _otherDetails = 'Details extracted from the image';
    });
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _extractedText = '';
      _name = '';
      _email = '';
      _phoneNumber = '';
      _address = '';
      _otherDetails = '';
      _isCard = false;
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'Text copied to clipboard!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          )),
    );
  }

  @override
  dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Snap Text",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                height: 400,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _clearImage,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Text(
                          'No Image Selected',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _extractedText.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ColorizeAnimatedTextKit(
                        text: const ['No text extracted yet'],
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        colors: const [
                          Colors.orange,
                          Colors.black,
                          Colors.orange,
                          Colors.black,
                        ],
                        speed: const Duration(milliseconds: 1000),
                        totalRepeatCount: 100,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _isCard
                          ? Column(
                              children: [
                                if (_name.isNotEmpty)
                                  _buildDetailRow('Name', _name),
                                if (_email.isNotEmpty)
                                  _buildDetailRow('Email', _email),
                                if (_phoneNumber.isNotEmpty)
                                  _buildDetailRow('Phone Number', _phoneNumber),
                                if (_address.isNotEmpty)
                                  _buildDetailRow('Address', _address),
                              ],
                            )
                          : Stack(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: AnimatedTextKit(
                                    animatedTexts: [
                                      TyperAnimatedText(
                                        _extractedText,
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        speed: const Duration(milliseconds: 50),
                                      ),
                                    ],
                                    totalRepeatCount: 1,
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _copyToClipboard(_extractedText),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black54,
                                      ),
                                      child: const Icon(
                                        Icons.copy,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ImagePickerButton(
                  icon: Icons.camera,
                  label: 'Camera',
                  backgroundColor: Colors.orange,
                  onPressed: _pickFromCamera,
                ),
                ImagePickerButton(
                  icon: Icons.image,
                  label: 'Gallery',
                  backgroundColor: Colors.orange,
                  onPressed: _pickFromGallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            detail,
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(detail),
          ),
        ],
      ),
    );
  }
}
