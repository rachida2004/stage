package com.bf.dsi.services;

import com.bf.dsi.entity.Invitation;
import org.apache.poi.xwpf.usermodel.*;
import org.springframework.stereotype.Service;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

@Service
public class WordService {

    public byte[] generateInvitationWord(Invitation invitation) {
        // L'utilisation du try-with-resources garantit la fermeture automatique du document et du flux
        try (XWPFDocument document = new XWPFDocument();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            
            // 1. Création d'un paragraphe de test (Mets ici ta logique de mise en page)
            XWPFParagraph paragraph = document.createParagraph();
            XWPFRun run = paragraph.createRun();
            run.setText("MINISTÈRE — DIRECTION DES SYSTÈMES D'INFORMATION");
            run.setBold(true);
            
            XWPFParagraph objParagraph = document.createParagraph();
            XWPFRun objRun = objParagraph.createRun();
            objRun.setText("Objet : " + invitation.getObjet());
            
            // 2. Écriture impérative des données du document dans le flux de sortie
            document.write(out);
            
            // 3. Récupération propre du tableau d'octets complet et valide
            return out.toByteArray();
            
        } catch (IOException e) {
            // Log l'erreur en cas de problème d'écriture binaire
            throw new RuntimeException("Erreur lors de la génération du document Word", e);
        }
    }
}