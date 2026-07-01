package com.bf.dsi.controller;

import com.bf.dsi.services.FileStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin; // 👈 AJOUTÉ
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // 👈 AJOUTÉ : Autorise Flutter Web à lire l'IFrame du PDF
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

            // Détermination du Content-Type
            MediaType contentType = MediaType.APPLICATION_OCTET_STREAM;
            String lower = filename.toLowerCase();
            if (lower.endsWith(".pdf")) {
                contentType = MediaType.APPLICATION_PDF;
            } else if (lower.endsWith(".docx")) {
                contentType = MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document");
            } else if (lower.endsWith(".doc")) {
                contentType = MediaType.parseMediaType("application/msword");
            } else if (lower.endsWith(".xlsx")) {
                contentType = MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            } else if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
                contentType = MediaType.IMAGE_JPEG;
            } else if (lower.endsWith(".png")) {
                contentType = MediaType.IMAGE_PNG;
            } else if (lower.endsWith(".gif")) {
                contentType = MediaType.IMAGE_GIF;
            } else if (lower.endsWith(".webp")) {
                contentType = MediaType.parseMediaType("image/webp");
            } else if (lower.endsWith(".bmp")) {
                contentType = MediaType.parseMediaType("image/bmp");
            }

            return ResponseEntity.ok()
                    .contentType(contentType)
                    // 🎯 MODIFIÉ : Remplacement de "attachment" par "inline" pour que le navigateur
                    // accepte d'afficher le PDF dans l'IFrame au lieu de lancer un téléchargement de fichier.
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + filename + "\"")
                    .body(fileData);

        } catch (RuntimeException e) {
            // Si ton service lève une exception "Fichier introuvable", on renvoie un vrai 404
            return ResponseEntity.notFound().build();
        }
    }
}