import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Import VRAIMENT conditionnel : sur Web -> web_pdf_view_web.dart
// (qui importe dart:ui_web + package:web), sur mobile/desktop ->
// web_pdf_view_stub.dart (aucune dépendance web). Le choix se fait
// à la COMPILATION, donc ça ne casse jamais le build Android/iOS.
import 'web_pdf_view_stub.dart'
    if (dart.library.html) 'web_pdf_view_web.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerPage({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localPath;
  bool isLoading = true;
  String errorMessage = '';
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'pdf-view-${DateTime.now().millisecondsSinceEpoch}';

    if (kIsWeb) {
      // Enregistrement de l'IFrame HTML pour le Web
      registerWebPdfView(_viewId, widget.pdfUrl);
      setState(() {
        isLoading = false;
      });
    } else {
      _loadPdf();
    }
  }

  Future<void> _loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File("${dir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.pdf");
        
        await file.writeAsBytes(bytes, flush: true);
        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Impossible de charger le fichier (Code: ${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Erreur lors de la récupération de la pièce jointe : $e";
        isLoading = false;
      });
    }
  }

  Future<void> _openInNewTab() async {
    final Uri url = Uri.parse(widget.pdfUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 14)),
        backgroundColor: const Color(0xFF004D20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: "Ouvrir dans un nouvel onglet externe",
            onPressed: _openInNewTab,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF004D20)))
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
              : kIsWeb
                  ? HtmlElementView(viewType: _viewId) // Intègre le PDF directement dans l'interface
                  : PDFView(
                      filePath: localPath,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                      onError: (error) {
                        setState(() {
                          errorMessage = error.toString();
                        });
                      },
                    ),
    );
  }
}