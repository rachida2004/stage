// Implémentation par défaut utilisée sur mobile/desktop (non-web).
// Ce fichier ne doit JAMAIS importer dart:ui_web ni package:web,
// sinon la compilation Android/iOS/Windows plante.

void registerWebPdfView(String viewId, String pdfUrl) {
  // Ne devrait jamais être appelée hors web : sur mobile/desktop,
  // pdf_viewer_page.dart utilise PDFView (flutter_pdfview) à la place.
  throw UnsupportedError(
    'registerWebPdfView ne doit être appelée que sur le Web.',
  );
}