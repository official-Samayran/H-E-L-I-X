import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/base_connection_provider.dart';
import '../theme/theme_manager.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  late TextEditingController _ipController;
  late TextEditingController _nameController;
  late TextEditingController _macController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BaseConnectionProvider>(context, listen: false);
    _ipController = TextEditingController(text: provider.hostIP);
    _nameController = TextEditingController(text: provider.pcName);
    _macController = TextEditingController(text: provider.macAddress);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _nameController.dispose();
    _macController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: theme.backgroundColor.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.accentColor.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'N E T W O R K',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 24),
              _buildField('Host IP Address', _ipController, theme),
              const SizedBox(height: 16),
              _buildField('PC Name', _nameController, theme),
              const SizedBox(height: 16),
              _buildField('MAC Address (WoL)', _macController, theme),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentColor,
                  foregroundColor: theme.backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Provider.of<BaseConnectionProvider>(context, listen: false)
                      .saveConfigs(_ipController.text.trim(), _nameController.text.trim(), _macController.text.trim());
                  Navigator.pop(context);
                },
                child: const Text('SAVE CONFIGURATION', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, ThemeManager theme) {
    return TextField(
      controller: controller,
      style: TextStyle(color: theme.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textColor.withOpacity(0.6)),
        filled: true,
        fillColor: theme.chatBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

