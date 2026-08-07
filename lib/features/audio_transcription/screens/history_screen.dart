import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/audio_provider.dart';
import 'text_view_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final historyAudios = ref.watch(audioProvider).historyAudios;
    
    // Filter history based on search query
    final filteredHistory = historyAudios.where((audio) {
      if (_searchQuery.isEmpty) return true;
      return audio.text.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'History',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                hintText: 'Search transcripts...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          Expanded(
            child: filteredHistory.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty 
                          ? "No history yet.\nRecordings will appear here automatically." 
                          : "No matches found.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final audio = filteredHistory[index];
                      final dateStr = DateFormat('MMM dd, yyyy - hh:mm a').format(audio.date);
                      
                      // Preview text (first 50 characters)
                      final previewText = audio.text.length > 50 
                          ? '${audio.text.substring(0, 50).replaceAll('\n', ' ')}...' 
                          : audio.text.replaceAll('\n', ' ');

                      return Card(
                        elevation: 2,
                        color: Theme.of(context).cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TextViewScreen(transcribedText: audio.text),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  previewText.isEmpty ? 'No text transcribed' : previewText,
                                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
