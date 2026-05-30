import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _currentLang = AppText.lang;

  _saveLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    setState(() { 
      _currentLang = lang; 
      AppText.lang = lang; // 즉시 반영
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppText.get('lang_set'))),
      body: Column(
        children: [
          RadioListTile(title: const Text("한국어"), value: 'ko', groupValue: _currentLang, onChanged: (v) => _saveLang(v!)),
          RadioListTile(title: const Text("English"), value: 'en', groupValue: _currentLang, onChanged: (v) => _saveLang(v!)),
        ],
      ),
    );
  }
}