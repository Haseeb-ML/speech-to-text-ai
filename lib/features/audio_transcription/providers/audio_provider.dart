import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../services/transcription_service.dart';
import '../../settings/providers/settings_provider.dart';

// Class for saved audios
class SavedAudio {
  final String path;
  final String text;
  final int duration;
  final DateTime date;

  SavedAudio({required this.path, required this.text, required this.duration, required this.date});
}

// Yeh class hamari Audio ki current state (haalat) ko store karti hai
class AudioState {
  final bool isRecording;
  final bool isPaused;
  final String? audioPath;
  final String transcribedText;
  final int recordDuration; // Timer ke seconds
  final List<SavedAudio> savedAudios; // Saved audios list

  AudioState({
    this.isRecording = false,
    this.isPaused = false,
    this.audioPath,
    this.transcribedText = '',
    this.recordDuration = 0,
    this.savedAudios = const [],
  });

  AudioState copyWith({
    bool? isRecording,
    bool? isPaused,
    String? audioPath,
    bool clearAudioPath = false, // Naya parameter null set karne ke liye
    String? transcribedText,
    int? recordDuration,
    List<SavedAudio>? savedAudios,
  }) {
    return AudioState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      audioPath: clearAudioPath ? null : (audioPath ?? this.audioPath),
      transcribedText: transcribedText ?? this.transcribedText,
      recordDuration: recordDuration ?? this.recordDuration,
      savedAudios: savedAudios ?? this.savedAudios,
    );
  }
}

// Yeh class UI se commands leti hai aur state (haalat) ko update karti hai
class AudioProvider extends StateNotifier<AudioState> {
  final Ref ref;

  AudioProvider(this.ref) : super(AudioState());

  Timer? _timer;
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  StreamSubscription<Uint8List>? _recordStreamSub;
  File? _currentFile;
  RandomAccessFile? _randomAccessFile;
  DeepgramLiveService? _deepgramService;
  int _totalBytes = 0;
  String _finalText = "";
  String _partialText = "";

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

        _currentFile = File(path);
        _randomAccessFile = await _currentFile!.open(mode: FileMode.write);
        
        // 44 byte ka khali WAV header pehle likh dein (jab recording stop hogi toh isay update karenge)
        final dummyHeader = Uint8List(44);
        await _randomAccessFile!.writeFrom(dummyHeader);
        _totalBytes = 0;
        _finalText = "";
        _partialText = "";

        // Deepgram Live Service start karo
        _deepgramService = DeepgramLiveService();
        _deepgramService!.startStreaming((partial, isFinal) {
          if (isFinal) {
            _finalText += " " + partial;
            _partialText = "";
          } else {
            _partialText = partial;
          }
          state = state.copyWith(transcribedText: (_finalText + " " + _partialText).trim());
        });

        // Ab stream start karo bajaye direct record ke
        final stream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits, 
            sampleRate: 16000, 
            numChannels: 1,
            echoCancel: true,
            autoGain: true,
            noiseSuppress: true,
          ),
        );
        
        // Data aate hi file mein aur Deepgram ko bhejo
        _recordStreamSub = stream.listen((data) {
          _randomAccessFile?.writeFromSync(data);
          _totalBytes += data.length;
          _deepgramService?.sendAudio(data);
        });

        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          state = state.copyWith(recordDuration: state.recordDuration + 1);
        });
        state = state.copyWith(
          isRecording: true, 
          isPaused: false, 
          transcribedText: '', 
          recordDuration: 0,
          clearAudioPath: true,
        );
      }
    } catch (e) {
      print("Recording Error: $e");
    }
  }

  Future<void> pauseRecording() async {
    await _audioRecorder.pause();
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  Future<void> resumeRecording() async {
    await _audioRecorder.resume();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(recordDuration: state.recordDuration + 1);
    });
    state = state.copyWith(isPaused: false);
  }

  Future<void> stopRecording() async {
    _timer?.cancel();
    await _audioRecorder.stop();
    await _recordStreamSub?.cancel();
    _deepgramService?.stopStreaming();
    
    // Header update kar ke file close karo taake .wav playable ho
    if (_randomAccessFile != null) {
      _writeWavHeader(_randomAccessFile!, _totalBytes);
      await _randomAccessFile!.close();
    }
    
    final realPath = _currentFile?.path;
    if (realPath != null) {
      state = state.copyWith(isRecording: false, isPaused: false, audioPath: realPath);
      
      // Ab humein poora text Urdu script mein mil chuka hai (Live Deepgram se)
      final urduText = state.transcribedText;
      if (urduText.isNotEmpty) {
        // UI mein dikhao ke ab Roman Urdu mein convert ho raha hai
        state = state.copyWith(transcribedText: "Aawaz convert ho chuki hai. Ab text refine ho raha hai...\n\nRaw:\n$urduText");
        
        // Settings se language uthao (Roman Urdu ya English)
        final targetLang = ref.read(settingsProvider).language;
        
        final finalRes = await GroqLlamaService.transliterateToRomanUrdu(urduText, targetLanguage: targetLang);
        state = state.copyWith(transcribedText: finalRes);
      }
    } else {
      state = state.copyWith(isRecording: false, isPaused: false);
    }
  }

  void _writeWavHeader(RandomAccessFile raf, int audioDataSize) {
    raf.setPositionSync(0);
    final byteData = ByteData(44);
    
    byteData.setUint8(0, 0x52); // R
    byteData.setUint8(1, 0x49); // I
    byteData.setUint8(2, 0x46); // F
    byteData.setUint8(3, 0x46); // F
    byteData.setUint32(4, 36 + audioDataSize, Endian.little);
    byteData.setUint8(8, 0x57); // W
    byteData.setUint8(9, 0x41); // A
    byteData.setUint8(10, 0x56); // V
    byteData.setUint8(11, 0x45); // E
    byteData.setUint8(12, 0x66); // f
    byteData.setUint8(13, 0x6D); // m
    byteData.setUint8(14, 0x74); // t
    byteData.setUint8(15, 0x20); // space
    byteData.setUint32(16, 16, Endian.little); 
    byteData.setUint16(20, 1, Endian.little); // PCM
    byteData.setUint16(22, 1, Endian.little); // Mono
    byteData.setUint32(24, 16000, Endian.little); 
    byteData.setUint32(28, 16000 * 1 * 2, Endian.little); 
    byteData.setUint16(32, 2, Endian.little); 
    byteData.setUint16(34, 16, Endian.little); 
    byteData.setUint8(36, 0x64); // d
    byteData.setUint8(37, 0x61); // a
    byteData.setUint8(38, 0x74); // t
    byteData.setUint8(39, 0x61); // a
    byteData.setUint32(40, audioDataSize, Endian.little);
    
    raf.writeFromSync(byteData.buffer.asUint8List());
  }

  void updateText(String text) {
    state = state.copyWith(transcribedText: text);
  }

  void clearText() {
    state = state.copyWith(transcribedText: '');
  }

  void clearAudio() {
    state = state.copyWith(clearAudioPath: true, recordDuration: 0, transcribedText: '');
  }

  void saveCurrentAudio() {
    if (state.audioPath != null) {
      final newAudio = SavedAudio(
        path: state.audioPath!,
        text: state.transcribedText,
        duration: state.recordDuration,
        date: DateTime.now(),
      );
      state = state.copyWith(
        savedAudios: [...state.savedAudios, newAudio],
        clearAudioPath: true,
        recordDuration: 0,
        transcribedText: '',
      );
    }
  }

  void deleteSavedAudio(SavedAudio audioToDelete) {
    final updatedList = state.savedAudios.where((audio) => audio.path != audioToDelete.path).toList();
    state = state.copyWith(savedAudios: updatedList);
    
    try {
      final file = File(audioToDelete.path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      print("File delete error: $e");
    }
  }

  void deleteAllSavedAudios() {
    // Delete physical files
    for (var audio in state.savedAudios) {
      try {
        final file = File(audio.path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        print("Delete all error: $e");
      }
    }
    // Clear list in state
    state = state.copyWith(savedAudios: []);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}

final audioProvider = StateNotifierProvider<AudioProvider, AudioState>((ref) {
  return AudioProvider(ref);
});
