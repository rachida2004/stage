// Implémentation Web réelle, compilée uniquement quand la cible
// supporte dart:html/dart:ui_web (voir l'import conditionnel dans
// pdf_viewer_page.dart : `if (dart.library.html)`).

import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

void registerWebPdfView(String viewId, String pdfUrl) {
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) {
    final element = web.HTMLIFrameElement()
      ..src = pdfUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    return element;
  });
}