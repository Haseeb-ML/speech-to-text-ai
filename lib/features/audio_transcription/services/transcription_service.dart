import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';// ---------------------------------------------------------
// Chain of Responsibility Pattern - Base Class
// ---------------------------------------------------------
// Yeh base class hai. Har API/Service isko extend karegi.
abstract class TranscriptionHandler {
  TranscriptionHandler? nextHandler;

  // Next service set karne ke liye (maslan Groq ke baad Gemini)
  void setNext(TranscriptionHandler handler) {
    nextHandler = handler;
  }

  // Audio se text banane ka main function
  Future<String?> transcribe(File audioFile);
}

// ---------------------------------------------------------
// 1. Groq Whisper API (Primary Option)
// ---------------------------------------------------------
class GroqHandler extends TranscriptionHandler {
  @override
  Future<String?> transcribe(File audioFile) async {
    try {
      print("Trying Groq API...");
      // Groq Whisper API has been replaced by Deepgram WebSockets for live streaming.
      // But we still use Groq's LLaMA to transliterate final text to Roman Urdu.
      return null; // GroqHandler is no longer used for transcription.
    } catch (e) {
      print("Groq failed: $e");
      if (nextHandler != null) {
        return await nextHandler!.transcribe(audioFile);
      }
      return null;
    }
  }
}

class GroqLlamaService {
  static Future<String> transliterateToRomanUrdu(String urduText, {String targetLanguage = 'Roman Urdu'}) async {
    try {
      final apiKey = 'YOUR_GROQ_API_KEY';
      final chatUri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final systemPrompt = targetLanguage == 'English' 
        ? "You are a highly accurate translator. The user will provide a text in Hindi/Urdu. Translate it perfectly into pure English. If the text contains speaker labels like 'Person A:' or 'Person B:', you MUST format the output as a dialogue script with exactly TWO newlines between speakers (e.g., \n\nPerson A: Hello\n\nPerson B: Hi). Do NOT add any extra commentary, just return the translated English text."
        : "You are an expert at transliterating text into natural Roman Urdu. The user will provide a text in Devanagari (Hindi) or Roman English. Convert it perfectly into Roman Urdu with correct spacing, punctuation, and grammar. If the text contains speaker labels like 'Person A:' or 'Person B:', you MUST format the output as a dialogue script with exactly TWO newlines between speakers (e.g., \n\nPerson A: Kiya haal hai?\n\nPerson B: Main theek). Do not output anything else except the converted text.";

      final requestBody = {
        "model": "llama-3.1-70b-versatile",
        "messages": [
          {
            "role": "system",
            "content": systemPrompt
          },
          {
            "role": "user",
            "content": urduText
          }
        ],
        "temperature": 0.3
      };

      final chatResponse = await http.post(
        chatUri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody)
      );

      if (chatResponse.statusCode == 200) {
        final chatJson = jsonDecode(chatResponse.body);
        return chatJson['choices'][0]['message']['content'].toString().trim();
      } else {
        return urduText; // Fallback
      }
    } catch (e) {
      print("LLaMA transliteration failed: $e");
      return urduText;
    }
  }
}

// ---------------------------------------------------------
// Fast Local Transliteration (Hindi to Roman) for Live Preview
// ---------------------------------------------------------
class LocalTransliterator {
  static final Map<String, String> _hindiToRomanMap = {
    'अ': 'a', 'आ': 'aa', 'इ': 'i', 'ई': 'ee', 'उ': 'u', 'ऊ': 'oo', 'ए': 'e', 'ऐ': 'ai', 'ओ': 'o', 'औ': 'au',
    'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh', 'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh', 'ट': 't', 'ठ': 'th',
    'ड': 'd', 'ढ': 'dh', 'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh', 'न': 'n', 'प': 'p', 'फ': 'f', 'ब': 'b',
    'भ': 'bh', 'म': 'm', 'य': 'y', 'र': 'r', 'ल': 'l', 'व': 'w', 'श': 'sh', 'ष': 'sh', 'स': 's', 'ह': 'h',
    'ा': 'a', 'ि': 'i', 'ी': 'ee', 'ु': 'u', 'ू': 'oo', 'े': 'e', 'ै': 'ai', 'ो': 'o', 'ौ': 'au',
    'ं': 'n', 'ँ': 'n', 'ः': 'ah', '्': '', 'ड़': 'r', 'ढ़': 'rh', 'ज़': 'z', 'फ़': 'f', 'ख़': 'kh', 'ग़': 'g'
  };

  static String toRoman(String hindiText) {
    StringBuffer romanText = StringBuffer();
    for (int i = 0; i < hindiText.length; i++) {
      String char = hindiText[i];
      romanText.write(_hindiToRomanMap[char] ?? char);
    }
    return romanText.toString();
  }
}

// ---------------------------------------------------------
// Deepgram Live Streaming Service
// ---------------------------------------------------------
class DeepgramLiveService {
  IOWebSocketChannel? _channel;
  final String _apiKey = 'YOUR_DEEPGRAM_API_KEY';
  int _lastSpeaker = -1;
  
  void startStreaming(void Function(String partialText, bool isFinal) onTextReceived) {
    _lastSpeaker = -1; // Reset speaker state
    try {
      final uri = Uri.parse('wss://api.deepgram.com/v1/listen?model=nova-2&encoding=linear16&sample_rate=16000&channels=1&language=hi&diarize=true');
      
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: {
          'Authorization': 'Token $_apiKey',
        },
      );
      
      _channel!.stream.listen((message) {
        try {
          final data = jsonDecode(message);
          if (data['channel'] != null && data['channel']['alternatives'] != null) {
            final words = data['channel']['alternatives'][0]['words'] as List<dynamic>?;
            final isFinal = data['is_final'] ?? false;
            
            if (words != null && words.isNotEmpty) {
              String formattedChunk = "";
              int tempSpeaker = _lastSpeaker;
              
              for (var w in words) {
                int speaker = w['speaker'] ?? 0;
                String wordStr = w['punctuated_word'] ?? w['word'] ?? "";
                
                if (speaker != tempSpeaker) {
                  final speakerChar = String.fromCharCode(65 + speaker); // 0 -> A, 1 -> B
                  formattedChunk += "\n\nPerson $speakerChar: ";
                  tempSpeaker = speaker;
                }
                formattedChunk += wordStr + " ";
              }
              
              if (isFinal) {
                _lastSpeaker = tempSpeaker;
              }
              
              final romanTranscript = LocalTransliterator.toRoman(formattedChunk);
              onTextReceived(romanTranscript + " ", isFinal);
            }
          }
        } catch (e) {
          // Ignore JSON parse errors silently
        }
      }, onDone: () {}, onError: (error) {});
    } catch(e) {
      print('Deepgram Connect Error: $e');
    }
  }

  void sendAudio(Uint8List audioBytes) {
    if (_channel != null) {
      _channel!.sink.add(audioBytes);
    }
  }
  
  void stopStreaming() {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({"type": "CloseStream"}));
      Future.delayed(const Duration(seconds: 2), () {
        _channel?.sink.close();
        _channel = null;
      });
    }
  }
}

// ---------------------------------------------------------
// 2. Gemini API (1st Fallback)
// ---------------------------------------------------------
class GeminiHandler extends TranscriptionHandler {
  @override
  Future<String?> transcribe(File audioFile) async {
    try {
      print("Trying Gemini API...");
      // TODO: Yahan Gemini 2.0/2.5 ka HTTP POST request code aayega
      
      throw Exception("Gemini Failed (Not implemented yet)");
    } catch (e) {
      print("Gemini failed: $e");
      // Agar Gemini fail ho jaye, toh next par jao
      if (nextHandler != null) {
        return await nextHandler!.transcribe(audioFile);
      }
      return null;
    }
  }
}

// ---------------------------------------------------------
// 3. Native Speech To Text (2nd Fallback)
// ---------------------------------------------------------
// Yeh package 'speech_to_text' use karta hai jo mobile ka apna built-in system hai
class NativeSpeechHandler extends TranscriptionHandler {
  @override
  Future<String?> transcribe(File audioFile) async {
    try {
      print("Trying Native SpeechToText...");
      // TODO: speech_to_text package ka logic aayega
      // Note: Yeh real-time kaam karta hai normally, pre-recorded audio ke liye humein isay theek se set karna hoga
      
      throw Exception("Native Speech Failed (Not implemented yet)");
    } catch (e) {
      print("Native Speech failed: $e");
      // Agar Native bhi fail ho jaye toh Vosk par jao
      if (nextHandler != null) {
        return await nextHandler!.transcribe(audioFile);
      }
      return null;
    }
  }
}

// ---------------------------------------------------------
// 4. Vosk / Whisper.cpp (Final Fallback - Offline)
// ---------------------------------------------------------
class VoskHandler extends TranscriptionHandler {
  @override
  Future<String?> transcribe(File audioFile) async {
    try {
      print("Trying Vosk (Offline)...");
      // TODO: Yahan Vosk ya Whisper.cpp ka on-device logic aayega
      
      return "Final Fallback Text (Demo)"; 
    } catch (e) {
      print("Vosk failed: $e");
      return "Transcription completely failed. Please check your internet or try again.";
    }
  }
}

// ---------------------------------------------------------
// Main Service (Jo baqi app use karegi)
// ---------------------------------------------------------
class TranscriptionService {
  late TranscriptionHandler _chain;

  TranscriptionService() {
    // Chain banana: Groq -> Gemini -> Native -> Vosk
    final groq = GroqHandler();
    final gemini = GeminiHandler();
    final nativeSpeech = NativeSpeechHandler();
    final vosk = VoskHandler();

    // Inko aapas mein link kar rahe hain
    groq.setNext(gemini);
    gemini.setNext(nativeSpeech);
    nativeSpeech.setNext(vosk);

    // Chain ka pehla hissa Groq hai
    _chain = groq;
  }

  // App is function ko call karegi
  Future<String> processAudio(String audioPath) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      return "Error: Audio file nahi mili.";
    }

    // Chain shuru karo
    final result = await _chain.transcribe(file);
    return result ?? "Transcription mein masla aaya hai.";
  }
}
