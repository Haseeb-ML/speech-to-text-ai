import 'package:flutter/material.dart';

class DialogueText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const DialogueText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    // Merge the provided style with the default text style to get correct theme colors
    final baseStyle = DefaultTextStyle.of(context).style.merge(style);

    if (text.isEmpty) {
      return Text(
        "Live connection established...\nBolna shuru karein, text yahan aata jayega!",
        style: baseStyle,
        textAlign: TextAlign.center,
      );
    }

    // Match "Person A:", "Person B:", etc. at the start of a line or after spaces/newlines
    final RegExp regex = RegExp(r'(Person [A-Z]:)');
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: baseStyle, textAlign: TextAlign.center);
    }

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final matchedString = match.group(0)!;
      Color color = Colors.blue; 
      if (matchedString.contains('A')) color = Colors.blue;
      else if (matchedString.contains('B')) color = Colors.green;
      else if (matchedString.contains('C')) color = Colors.orange;
      else if (matchedString.contains('D')) color = Colors.purple;
      else color = Colors.red;

      spans.add(TextSpan(
        text: matchedString,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return RichText(
      textAlign: TextAlign.left, // Left align for chat format
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }
}
