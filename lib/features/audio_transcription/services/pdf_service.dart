import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Yeh class PDF banane aur usko view/share karne ka logic handle karti hai
class PdfService {
  
  // 1. Text se PDF document banane ka function
  static Future<pw.Document> generatePdf(String transcribedText) async {
    // Ek naya khali PDF document banate hain
    final pdf = pw.Document();

    // Isme ek page add karte hain
    pdf.addPage(
      pw.Page(
        // Page ka format (aam tor par A4 use hota hai)
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          // Page ke andar ka design
          return pw.Center(
            child: pw.Text(
              transcribedText,
              style: const pw.TextStyle(fontSize: 18),
            ),
          );
        },
      ),
    );

    return pdf;
  }

  // 2. PDF ko screen par open (view) karne ka function
  static Future<void> viewPdf(String text, String title) async {
    try {
      // Pehle PDF generate karo
      final pdf = await generatePdf(text);
      
      // Printing package ka use karke PDF ko screen par show karo
      // Yeh automatically print aur share ke options bhi de deta hai
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '$title.pdf', // File ka naam jo print ya save karte waqt aayega
      );
    } catch (e) {
      print("PDF open karne mein error: $e");
    }
  }

  // 3. Agar humein PDF file ko physically save karke kisi aur app par share karna ho
  // (Yeh zaroorat parne par use karenge, filhal Printing.layoutPdf kaafi hai)
  static Future<void> sharePdf(String text, String title) async {
    try {
      final pdf = await generatePdf(text);
      final bytes = await pdf.save();
      
      // Share karne ka logic printing package mein bhi hota hai,
      // Ya hum share_plus package use karke physically is file ko Whatsapp par bhej sakte hain.
      await Printing.sharePdf(bytes: bytes, filename: '$title.pdf');
    } catch (e) {
      print("PDF share karne mein error: $e");
    }
  }
}
