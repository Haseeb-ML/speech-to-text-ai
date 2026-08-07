import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Copy ke liye
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/providers/settings_provider.dart';
import 'package:share_plus/share_plus.dart'; // Share ke liye
import '../widgets/dialogue_text.dart'; 
import '../providers/audio_provider.dart';
import '../services/pdf_service.dart'; // PDF service

class TextViewScreen extends ConsumerWidget {
  final String transcribedText;

  const TextViewScreen({super.key, required this.transcribedText});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Current text get karne ke liye constructor se layenge
    final text = transcribedText;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Wapis jane ke liye
        ),
        title: const Text(
          'Final Text',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // Top right par Copy, Share aur PDF ke options
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Text copied to clipboard!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Save as PDF',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening PDF...')),
              );
              // Humari pehlay se bani hui service use karte hain
              await PdfService.viewPdf(text, 'transcription');
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Text',
            onPressed: () {
              final speakers = _getSpeakers(text);
              if (speakers.isEmpty) {
                Share.share(text, subject: 'Audio Transcription');
                return;
              }
              
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('What do you want to share?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        ListTile(
                          leading: const Icon(Icons.article),
                          title: const Text('Share Complete Text'),
                          onTap: () {
                            Navigator.pop(context);
                            Share.share(text, subject: 'Audio Transcription');
                          },
                        ),
                        const Divider(),
                        ...speakers.map((speaker) => ListTile(
                          leading: const Icon(Icons.person, color: Colors.blue),
                          title: Text('Share Only $speaker'),
                          onTap: () {
                            Navigator.pop(context);
                            final speakerText = _extractTextForSpeaker(text, speaker);
                            Share.share(speakerText, subject: '$speaker Transcription');
                          },
                        )).toList(),
                      ],
                    ),
                  );
                }
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).cardColor,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: DialogueText(
                  text: text.isEmpty ? 'No text transcribed yet...' : text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

List<String> _getSpeakers(String text) {
  final regex = RegExp(r'Person [A-Z]');
  final matches = regex.allMatches(text);
  return matches.map((m) => m.group(0)!).toSet().toList()..sort();
}

String _extractTextForSpeaker(String text, String speaker) {
  // Split by "Person " but keep the delimiter by using lookahead
  final parts = text.split(RegExp(r'(?=Person [A-Z]:)'));
  
  final speakerParts = parts.where((p) => p.startsWith('$speaker:')).map((p) {
      return p.trim();
  }).toList();
  
  return speakerParts.join('\n\n');
}
