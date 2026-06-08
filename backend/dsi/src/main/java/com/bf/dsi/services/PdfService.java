package com.bf.dsi.services;

import com.bf.dsi.entity.Invitation;
import com.itextpdf.text.*;
import com.itextpdf.text.pdf.*;
import org.springframework.stereotype.Service;
import java.io.ByteArrayOutputStream;
import java.time.format.DateTimeFormatter;
import com.itextpdf.text.pdf.draw.LineSeparator;

@Service
public class PdfService {
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final Font TITLE   = new Font(Font.FontFamily.HELVETICA, 14, Font.BOLD);
    private static final Font HEADING = new Font(Font.FontFamily.HELVETICA, 11, Font.BOLD);
    private static final Font NORMAL  = new Font(Font.FontFamily.HELVETICA, 10, Font.NORMAL);
    private static final Font SMALL   = new Font(Font.FontFamily.HELVETICA,  9, Font.ITALIC);

    public byte[] generateInvitationLetter(Invitation inv) {
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            Document doc = new Document(PageSize.A4, 72, 72, 72, 72);
            PdfWriter.getInstance(doc, out);
            doc.open();

            // En-tête
            Paragraph entete = new Paragraph("MINISTÈRE — DIRECTION DES SYSTÈMES D'INFORMATION\nOuagadougou, Burkina Faso", SMALL);
            entete.setAlignment(Element.ALIGN_LEFT);
            doc.add(entete);
            doc.add(Chunk.NEWLINE);

            // Date et référence
            String dateNow = java.time.LocalDate.now().format(FMT);
            Paragraph ref = new Paragraph("Ouagadougou, le " + dateNow, NORMAL);
            ref.setAlignment(Element.ALIGN_RIGHT);
            doc.add(ref);
            doc.add(Chunk.NEWLINE);

            // Destinataire
            String dest = inv.getStructureEmettrice() != null ? inv.getStructureEmettrice().getNom() : "Destinataire";
            Paragraph destinataire = new Paragraph("À l'attention de : " + dest, NORMAL);
            doc.add(destinataire);
            doc.add(Chunk.NEWLINE);

            // Objet
Paragraph objet = new Paragraph("Objet : " + inv.getObjet(), HEADING);
            doc.add(objet);
            doc.add(Chunk.NEWLINE);
            doc.add(new LineSeparator());
            doc.add(Chunk.NEWLINE);

            // Corps
            String corps = String.format(
                "Monsieur/Madame,%n%n" +
                "Nous avons l'honneur de vous inviter à participer à l'événement suivant :%n%n" +
                "  • Intitulé : %s%n" +
                "  • Date de début : %s%n" +
                "  • Date de fin : %s%n" +
                "  • Nombre de participants attendus : %d%n%n" +
                "Votre présence nous serait particulièrement précieuse.%n%n" +
                "Veuillez agréer, Monsieur/Madame, l'expression de nos salutations distinguées.",
                inv.getObjet(),
                inv.getDateDebut().format(FMT),
                inv.getDateFin().format(FMT),
                inv.getNombreParticipant() != null ? inv.getNombreParticipant() : 0
            );
            Paragraph body = new Paragraph(corps, NORMAL);
            body.setLeading(16);
            doc.add(body);
            doc.add(Chunk.NEWLINE);
            doc.add(Chunk.NEWLINE);

            // Signature
            Paragraph signature = new Paragraph("Le Directeur des Systèmes d'Information\n\n\n________________________", NORMAL);
            signature.setAlignment(Element.ALIGN_RIGHT);
            doc.add(signature);

            doc.close();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Erreur génération PDF: " + e.getMessage(), e);
        }
    }
}
