import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_provider.dart';
import '../widgets/dialogue_text.dart';
import 'text_view_screen.dart'; // Nayii screen ko import kiya

class RecordAudioScreen extends ConsumerWidget {
  const RecordAudioScreen({super.key});

  String _formatDuration(int seconds) {
    final hours = (seconds / 3600).floor().toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {}, 
        ),
        title: Text(
          'Audio to Text',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Agar recording start ho gayi hai toh naya UI show karo, warna purana default UI
          if (audioState.isRecording || audioState.audioPath != null)
            Expanded(child: _buildRecordingLayout(context, ref, audioState))
          else
            Expanded(child: _buildDefaultLayout(context, ref)),
        ],
      ),
    );
  }

  // --- NAYA DESIGN (Jab recording chal rahi ho ya pause ho) ---
  Widget _buildRecordingLayout(BuildContext context, WidgetRef ref, AudioState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start, // Top se shuru karne ke liye
      children: [
        const SizedBox(height: 10), // Thori si top spacing
        // Timer (Size aur chota kiya gaya hai)
        Text(
          _formatDuration(state.recordDuration),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
        ),
        const SizedBox(height: 10),
        
        // Live Animated Waveform
        AnimatedWaveform(isRecording: state.isRecording, isPaused: state.isPaused),
        const SizedBox(height: 20),

        // Text Box (Bada mic icon remove kar diya gaya hai, taake yeh jagah le le)
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 15), // Margin kam kiya taake width zyada milay
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: AutoScrollTextBox(
              text: state.transcribedText.isEmpty 
                  ? 'Listening...\n\n(Aapka text yahan show hoga)' 
                  : state.transcribedText,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Bottom 2 Buttons (Pause aur Stop) ya (Cancel aur Save)
        if (state.audioPath == null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBottomButton(
                icon: state.isPaused ? Icons.play_arrow : Icons.pause, 
                onTap: () {
                  if (state.isPaused) {
                    ref.read(audioProvider.notifier).resumeRecording();
                  } else {
                    ref.read(audioProvider.notifier).pauseRecording();
                  }
                }
              ),
              const SizedBox(width: 40),
              _buildBottomButton(
                icon: Icons.stop, 
                onTap: () {
                  ref.read(audioProvider.notifier).stopRecording();
                }
              ),
            ],
          )
        else 
          // Jab Stop ho jaye toh Cancel aur Save show karo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBottomButton(
                icon: Icons.close, 
                color: Colors.red.shade100,
                iconColor: Colors.red,
                onTap: () {
                  ref.read(audioProvider.notifier).clearAudio();
                }
              ),
              const SizedBox(width: 40),
              _buildBottomButton(
                icon: Icons.check, 
                color: Colors.green.shade100,
                iconColor: Colors.green,
                onTap: () {
                  // Audio ko list mein save karo
                  ref.read(audioProvider.notifier).saveCurrentAudio();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Audio saved successfully! Go to Folder tab to view.')),
                  );
                }
              ),
            ],
          ),
          
        const SizedBox(height: 20),
      ],
    );
  }

  // --- PURANA DESIGN (Jab app khulti hai) ---
  Widget _buildDefaultLayout(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Record your voice and convert it instantly.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(),
        // Asal Bara Mic (Ab yeh clickable hai)
        GestureDetector(
          onTap: () {
             ref.read(audioProvider.notifier).startRecording();
          },
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.withOpacity(0.1), width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B5ED7), // Solid blue bg
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.3), spreadRadius: 5, blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.mic, size: 70, color: Colors.white), // Bara white icon
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        const Text(
          'Tap the microphone to start recording.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 60), // Thori space
      ],
    );
  }

  // Chota function bottom buttons ke liye (Size kam kiya gaya hai)
  Widget _buildBottomButton({required IconData icon, required VoidCallback onTap, Color? color, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45, // Chota size
        height: 45, // Chota size
        decoration: BoxDecoration(
          color: color ?? Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24, color: iconColor), // Chota icon
      ),
    );
  }
}

// Yeh class Waveform ko "Live" animation dene ke liye banayi gayi hai
class AnimatedWaveform extends StatefulWidget {
  final bool isRecording;
  final bool isPaused;

  const AnimatedWaveform({
    super.key,
    required this.isRecording,
    required this.isPaused,
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  late List<double> _heights;

  @override
  void initState() {
    super.initState();
    _heights = List.generate(20, (index) => 4.0);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Speed of wave change
    )..addListener(() {
        if (_controller.status == AnimationStatus.completed) {
          _updateHeights();
          _controller.reverse();
        } else if (_controller.status == AnimationStatus.dismissed) {
          _updateHeights();
          _controller.forward();
        }
      });

    if (widget.isRecording && !widget.isPaused) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !widget.isPaused) {
      if (!_controller.isAnimating) _controller.forward();
    } else {
      _controller.stop();
    }
  }

  void _updateHeights() {
    setState(() {
      for (int i = 0; i < 20; i++) {
        // Height bada di gayi hai (ab max 34.0 tak jayegi)
        _heights[i] = 4.0 + _random.nextDouble() * 30.0; 
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40, // Yeh height fix kar di gayi hai (aur ab badi kar di hai)
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(20, (index) {
          final height = widget.isRecording && !widget.isPaused ? _heights[index] : 4.0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 2.5,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF0B5ED7).withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }),
      ),
    );
  }
}

class AutoScrollTextBox extends StatefulWidget {
  final String text;
  const AutoScrollTextBox({super.key, required this.text});

  @override
  State<AutoScrollTextBox> createState() => _AutoScrollTextBoxState();
}

class _AutoScrollTextBoxState extends State<AutoScrollTextBox> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(AutoScrollTextBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: DialogueText(
        text: widget.text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
