package com.bf.dsi.controller;

import com.bf.dsi.services.FileStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class FileController {

    private final FileStorageService fileStorageService;

    // 🎯 Cet endpoint intercepte l'URL construite par ton Flutter : /api/files/download/invitations/17/nom_fichier.pdf
    @GetMapping("/api/files/download/{type}/{id}/{filename}")
    public ResponseEntity<byte[]> downloadFile(
            @PathVariable String type,
            @PathVariable String id,
            @PathVariable String filename) {
        
        // On reconstruit le chemin relatif attendu par ton service : "invitations/17/nom_fichier.pdf"
        String relativePath = type + "/" + id + "/" + filename;
        
        try {
            // Utilisation de ta méthode load() existante
            byte[] fileData = fileStorageService.load(relativePath);

            // Détermination du Content-Type (Optionnel mais propre pour les navigateurs)
            MediaType contentType = MediaType.APPLICATION_OCTET_STREAM;
            if (filename.toLowerCase().endsWith(".pdf")) {
                contentType = MediaType.APPLICATION_PDF;
            } else if (filename.toLowerCase().endsWith(".docx")) {
                contentType = MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document");
            }

            return ResponseEntity.ok()
                    .contentType(contentType)
                    // "inline" permet au navigateur d'ouvrir le PDF directement s'il le souhaite, ou de forcer le téléchargement
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                    .body(fileData);

        } catch (RuntimeException e) {
            // Si ton service lève une exception "Fichier introuvable", on renvoie un vrai 404
            return ResponseEntity.notFound().build();
        }
    }
}