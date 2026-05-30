import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'translations.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _idController.text = prefs.getString('user_id') ?? '';
      _nameController.text = prefs.getString('user_name') ?? '';
      _ageController.text = prefs.getString('user_age') ?? '';
      _weightController.text = prefs.getString('user_weight') ?? '';
      _imagePath = prefs.getString('user_image');
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() { _imagePath = image.path; });
    }
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', _idController.text);
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_age', _ageController.text);
    await prefs.setString('user_weight', _weightController.text);
    if (_imagePath != null) await prefs.setString('user_image', _imagePath!);
    if (mounted) Navigator.pop(context, true); // 저장 후 돌아가기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppText.get('user_set'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _imagePath != null ? FileImage(File(_imagePath!)) : null,
                child: _imagePath == null ? const Icon(Icons.camera_alt, size: 40) : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(AppText.get('id'), _idController),
            _buildTextField(AppText.get('name'), _nameController),
            _buildTextField(AppText.get('age'), _ageController, keyboardType: TextInputType.number),
            _buildTextField(AppText.get('weight'), _weightController, keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveUserData,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: Text(AppText.get('save')),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
    );
  }
}