import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/audio_provider.dart';
import 'text_view_screen.dart';

class SavedAudioScreen extends ConsumerWidget {
  const SavedAudioScreen({super.key});

  String _formatDuration(int seconds) {
    final minutes = ((seconds % 3600) / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAudios = ref.watch(audioProvider).savedAudios;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Saved Audios',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: savedAudios.isEmpty
                ? const Center(
                    child: Text(
                      "No saved audios yet.\nRecord something and save it!", 
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    )
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: savedAudios.length,
                    itemBuilder: (context, index) {
                      // Recent pehlay dekhane ke liye hum list ko reverse order mein parhte hain
                      final audio = savedAudios[savedAudios.length - 1 - index];
                      final displayIndex = savedAudios.length - index;
                      
                      return AudioListItem(audio: audio, displayIndex: displayIndex);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AudioListItem extends ConsumerStatefulWidget {
  final SavedAudio audio;
  final int displayIndex;

  const AudioListItem({super.key, required this.audio, required this.displayIndex});

  @override
  ConsumerState<AudioListItem> createState() => _AudioListItemState();
}

class _AudioListItemState extends ConsumerState<AudioListItem> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = ((seconds % 3600) / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            // Play/Pause Button
            GestureDetector(
              onTap: () async {
                try {
                  if (_isPlaying) {
                    await _audioPlayer.pause();
                  } else {
                    await _audioPlayer.play(DeviceFileSource(widget.audio.path));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error playing audio. Please restart the app! (Press "q" then "flutter run")')),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: const Color(0xFF0B5ED7),
                  size: 35,
                ),
              ),
            ),
            const SizedBox(width: 15),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recording ${widget.displayIndex}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Duration: ${_formatDuration(widget.audio.duration)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            // View Text aur Delete Icons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.green, size: 26),
                  tooltip: 'Share Audio',
                  onPressed: () {
                    Share.shareXFiles([XFile(widget.audio.path)], text: 'Check out this audio recording!');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.text_snippet, color: Color(0xFF0B5ED7), size: 26),
                  tooltip: 'View Text',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TextViewScreen(transcribedText: widget.audio.text),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 26),
                  tooltip: 'Delete Audio',
                  onPressed: () {
                    // Audio ko delete karna
                    ref.read(audioProvider.notifier).deleteSavedAudio(widget.audio);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Audio deleted successfully!')),
                    );
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
