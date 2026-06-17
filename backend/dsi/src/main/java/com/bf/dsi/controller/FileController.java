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
            if (filename.toLowerCase().endsWith(".pdf")) {
                contentType = MediaType.APPLICATION_PDF;
            } else if (filename.toLowerCase().endsWith(".docx")) {
                contentType = MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document");
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