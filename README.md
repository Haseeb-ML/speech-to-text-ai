# Speech to Text AI (Voice to Roman Urdu / English)

A state-of-the-art Flutter application that records voice, performs real-time transcription using WebSockets, and uses advanced LLMs to intelligently transliterate or translate the transcribed text.

## 🚀 Features

- **Real-Time Live Transcription:** Watch your spoken words appear on the screen instantly as you speak.
- **Intelligent Transliteration (Roman Urdu):** Converts raw Devanagari/Hindi scripts into natural-reading Roman Urdu (English alphabets).
- **Direct English Translation:** Option to directly translate the spoken Urdu/Hindi audio into pure English.
- **Audio Management:** Save, manage, and playback recorded audios locally.
- **Export Options:** Share your transcribed text or export it directly as a PDF.
- **Dark Mode Support:** Full dynamic theme switching (Light/Dark).

## 🛠️ Technology Stack & Architecture

This project is built using modern Flutter practices and integrates multiple powerful APIs.

### 1. Framework & State Management
- **Flutter / Dart**
- **Riverpod (`flutter_riverpod`):** Used for robust and scalable state management. The app's logic is cleanly separated into `Providers` (e.g., `AudioProvider`, `SettingsProvider`).

### 2. Live Audio Streaming (Deepgram)
- **Deepgram API (WebSocket v1):** Used for ultra-fast, real-time audio transcription.
- **Model:** `nova-2` (Deepgram's most powerful and fastest model for speech recognition).
- **Implementation:** The app captures audio via the microphone in raw PCM format (`linear16`, `16000Hz`) and streams it directly to Deepgram via a WebSocket connection (`web_socket_channel`).

### 3. AI Text Refinement (Groq LLaMA)
- **Groq API:** Used for near-instant inference of Large Language Models.
- **Model:** `llama-3.1-70b-versatile` (Meta's LLaMA 3.1 70B parameter model).
- **Implementation:** Once the recording stops, the raw transcription (which might contain messy Hinglish or Devanagari scripts) is sent to LLaMA 3.1. Depending on the user's settings, LLaMA either perfects the transliteration into clean **Roman Urdu** or translates it completely into **English**.

### 4. Local Storage
- **Shared Preferences (`shared_preferences`):** Used to persist user settings (Theme Mode, Output Language).
- **Path Provider (`path_provider`):** Used to save audio files (`.wav`) directly to the device's local storage.

## 📦 Getting Started

### Prerequisites
- Flutter SDK installed
- A [Deepgram API Key](https://console.deepgram.com/) (Not required for this repo's specific implementation as WebSocket is open, but good for scaling)
- A [Groq API Key](https://console.groq.com/keys)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Haseeb-ML/speech-to-text-ai.git
```

2. Install dependencies:
```bash
flutter pub get
```

3. Setup your API Key:
Go to `lib/features/audio_transcription/services/transcription_service.dart` and replace `YOUR_GROQ_API_KEY` with your actual Groq API key:
```dart
final apiKey = 'YOUR_GROQ_API_KEY';
```

4. Run the app:
```bash
flutter run
```

## 🔐 Security Note
Never push your actual API keys to GitHub. The code in this repository has placeholders for API keys to protect sensitive information. Use `.env` files or secure storage for production apps.
