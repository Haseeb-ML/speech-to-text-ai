import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/settings_provider.dart';
import '../../audio_transcription/providers/audio_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _totalSizeStr = "Calculating...";

  @override
  void initState() {
    super.initState();
    _calculateStorageSize();
  }

  Future<void> _calculateStorageSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      int totalBytes = 0;
      
      for (var file in files) {
        if (file is File && (file.path.endsWith('.wav') || file.path.endsWith('.m4a'))) {
          totalBytes += file.lengthSync();
        }
      }

      setState(() {
        if (totalBytes < 1024 * 1024) {
          _totalSizeStr = "${(totalBytes / 1024).toStringAsFixed(2)} KB";
        } else {
          _totalSizeStr = "${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB";
        }
      });
    } catch (e) {
      setState(() {
        _totalSizeStr = "Unknown";
      });
    }
  }

  Future<void> _clearAllAudios() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All Audio Files?"),
        content: const Text("This action cannot be undone. All your saved audio recordings will be deleted permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              // Call provider to clear state and files
              ref.read(audioProvider.notifier).deleteAllSavedAudios();
              
              await _calculateStorageSize();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All audio files cleared successfully!")),
                );
              }
            },
            child: const Text("Delete All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final themeNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings', 
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 22)
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Theme Settings
          const Text("Appearance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            child: SwitchListTile(
              title: const Text("Dark Mode"),
              subtitle: const Text("Switch between light and dark themes"),
              secondary: Icon(settings.isDarkMode ? Icons.dark_mode : Icons.light_mode),
              value: settings.isDarkMode,
              onChanged: (value) {
                themeNotifier.toggleTheme();
              },
            ),
          ),
          const SizedBox(height: 30),

          const SizedBox(height: 30),

          // Storage Settings
          const Text("Storage & Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.storage, color: Colors.orange),
              title: const Text("Audio Storage Used"),
              subtitle: Text(_totalSizeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
                onPressed: _clearAllAudios,
                child: const Text("Clear All", style: TextStyle(color: Colors.red)),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // About App
          const Text("About", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),
          const Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.info_outline, color: Colors.blue),
              title: Text("Audio Recorder & Transcriber"),
              subtitle: Text("Version 1.0.0\nDeveloped for fast & accurate transcriptions."),
            ),
          ),
        ],
      ),
    );
  }
}
