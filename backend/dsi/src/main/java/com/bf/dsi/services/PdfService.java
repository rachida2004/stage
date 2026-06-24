package com.bf.dsi.services;

import com.bf.dsi.entity.Invitation;
import com.bf.dsi.entity.StructureInvitee;
import com.itextpdf.text.*;
import com.itextpdf.text.pdf.*;
import org.springframework.stereotype.Service;
import java.io.ByteArrayOutputStream;
import java.time.format.DateTimeFormatter;
import java.util.List;
import com.itextpdf.text.pdf.draw.LineSeparator;

/**
 * Génère la lettre officielle d'invitation au format du Secrétariat général
 * (en-tête ministère / Burkina Faso, objet, corps, pièce jointe, ampliation, signature).
 */
@Service
public class PdfService {
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final Font TITLE     = new Font(Font.FontFamily.HELVETICA, 11, Font.BOLD);
    private static final Font HEADING   = new Font(Font.FontFamily.HELVETICA, 11, Font.BOLD);
    private static final Font NORMAL    = new Font(Font.FontFamily.HELVETICA, 11, Font.NORMAL);
    private static final Font SMALL     = new Font(Font.FontFamily.HELVETICA, 9, Font.NORMAL);
    private static final Font SMALL_B   = new Font(Font.FontFamily.HELVETICA, 9, Font.BOLD);
    private static final Font ITALIC_SM = new Font(Font.FontFamily.HELVETICA, 9, Font.ITALIC);

    public byte[] generateInvitationLetter(Invitation inv) {
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            Document doc = new Document(PageSize.A4, 56, 56, 50, 50);
            PdfWriter.getInstance(doc, out);
            doc.open();

            // ── En-tête : structure émettrice (gauche) / logo (centre) / Burkina Faso (droite) ──
            PdfPTable entete = new PdfPTable(3);
            entete.setWidthPercentage(100);
            entete.setWidths(new float[]{3f, 1.3f, 2f});

            String nomEmetteur = inv.getStructureEmettrice() != null && inv.getStructureEmettrice().getNom() != null
                ? inv.getStructureEmettrice().getNom().toUpperCase()
                : "MINISTÈRE — DIRECTION DES SYSTÈMES D'INFORMATION";

            Paragraph gaucheP = new Paragraph();
            gaucheP.setLeading(19f);
            gaucheP.add(new Chunk(nomEmetteur + "\n\n", SMALL_B));
            gaucheP.add(new Chunk("--------------\n\n", SMALL));
            gaucheP.add(new Chunk("SECRETARIAT GENERAL\n\n", SMALL_B));
            gaucheP.add(new Chunk("--------------\n\n", SMALL));
            gaucheP.add(new Chunk("DIRECTION GENERALE DES SYSTEMES\nD'INFORMATION", SMALL_B));

            PdfPCell gauche = new PdfPCell(gaucheP);
            gauche.setBorder(Rectangle.NO_BORDER);
            gauche.setVerticalAlignment(Element.ALIGN_TOP);
            entete.addCell(gauche);

            PdfPCell celluleLogo = new PdfPCell();
            celluleLogo.setBorder(Rectangle.NO_BORDER);
            celluleLogo.setHorizontalAlignment(Element.ALIGN_CENTER);
            celluleLogo.setVerticalAlignment(Element.ALIGN_TOP);
            try {
                Image logo = Image.getInstance(
                    getClass().getResourceAsStream("/images/logo.jpg").readAllBytes());
                logo.scaleToFit(48f, 40f);
                celluleLogo.addElement(logo);
            } catch (Exception ignored) {
                // si le logo est introuvable, on laisse la cellule vide plutôt que d'échouer la génération
            }
            entete.addCell(celluleLogo);

            Paragraph droite = new Paragraph();
            droite.add(new Chunk("BURKINA FASO\n", SMALL_B));
            droite.add(new Chunk("La Patrie ou la Mort, Nous vaincrons", ITALIC_SM));
            droite.setAlignment(Element.ALIGN_RIGHT);
            PdfPCell celluleDroite = new PdfPCell(droite);
            celluleDroite.setBorder(Rectangle.NO_BORDER);
            celluleDroite.setVerticalAlignment(Element.ALIGN_TOP);
            entete.addCell(celluleDroite);
            doc.add(entete);
            doc.add(Chunk.NEWLINE);

            // ── Référence (gauche) / Ville, date (droite) ──
            PdfPTable refTable = new PdfPTable(2);
            refTable.setWidthPercentage(100);
            refTable.setWidths(new float[]{3f, 2f});

            String reference = (inv.getNumeroReference() != null && !inv.getNumeroReference().isBlank())
                ? "N°" + inv.getNumeroReference() : "";
            PdfPCell celluleRef = new PdfPCell(new Phrase(reference, NORMAL));
            celluleRef.setBorder(Rectangle.NO_BORDER);
            refTable.addCell(celluleRef);

            String ville = (inv.getVille() != null && !inv.getVille().isBlank()) ? inv.getVille() : "Ouagadougou";
            Paragraph dateP = new Paragraph(ville + ", le " + java.time.LocalDate.now().format(FMT), NORMAL);
            dateP.setAlignment(Element.ALIGN_RIGHT);
            PdfPCell celluleDate = new PdfPCell(dateP);
            celluleDate.setBorder(Rectangle.NO_BORDER);
            refTable.addCell(celluleDate);
            doc.add(refTable);
            doc.add(Chunk.NEWLINE);
            doc.add(Chunk.NEWLINE);

            // ── Qualité du signataire ──
            String qualite = (inv.getSignataireQualite() != null && !inv.getSignataireQualite().isBlank())
                ? inv.getSignataireQualite() : "Le Secrétaire général";
            Paragraph pQualite = new Paragraph(qualite, TITLE);
            pQualite.setAlignment(Element.ALIGN_CENTER);
            doc.add(pQualite);

            Paragraph aLabel = new Paragraph("À", NORMAL);
            aLabel.setAlignment(Element.ALIGN_CENTER);
            doc.add(aLabel);

            Paragraph destinataire = new Paragraph(libelleDestinataire(inv), TITLE);
            destinataire.setAlignment(Element.ALIGN_CENTER);
            doc.add(destinataire);
            doc.add(Chunk.NEWLINE);

            // ── Objet ──
            Paragraph objet = new Paragraph();
            objet.add(new Chunk("Objet : ", HEADING));
            objet.add(new Chunk(inv.getObjet() != null ? inv.getObjet() : "", NORMAL));
            doc.add(objet);
            doc.add(Chunk.NEWLINE);

            // ── Corps de la lettre ──
            String corps = (inv.getContenu() != null && !inv.getContenu().isBlank())
                ? inv.getContenu()
                : corpsParDefaut(inv);
            Paragraph body = new Paragraph(corps, NORMAL);
            body.setAlignment(Element.ALIGN_JUSTIFIED);
            body.setLeading(18);
            doc.add(body);
            doc.add(Chunk.NEWLINE);
            doc.add(Chunk.NEWLINE);

            // ── Pièce(s) jointe(s) ──
            if (inv.getPiecesJointes() != null && !inv.getPiecesJointes().isEmpty()) {
                String noms = inv.getPiecesJointes().stream()
                    .map(pj -> pj.getNom())
                    .reduce((a, b) -> a + ", " + b).orElse("");
                Paragraph pj = new Paragraph();
                pj.add(new Chunk("Pièce jointe : ", HEADING));
                pj.add(new Chunk(noms, NORMAL));
                doc.add(pj);
                doc.add(Chunk.NEWLINE);
            }

            // ── Ampliation (gauche) / Signature (droite) ──
            PdfPTable bas = new PdfPTable(2);
            bas.setWidthPercentage(100);
            bas.setWidths(new float[]{2f, 3f});
            bas.setSpacingBefore(20f);

            Paragraph ampliationP = new Paragraph();
            ampliationP.add(new Chunk("Ampliation\n", HEADING));
            ampliationP.add(new Chunk(inv.getAmpliation() != null ? inv.getAmpliation() : "—", SMALL));
            PdfPCell celluleAmpliation = new PdfPCell(ampliationP);
            celluleAmpliation.setBorder(Rectangle.NO_BORDER);
            celluleAmpliation.setVerticalAlignment(Element.ALIGN_TOP);
            bas.addCell(celluleAmpliation);

            Paragraph signature = new Paragraph();
            signature.setAlignment(Element.ALIGN_CENTER);
            signature.add(new Chunk("\n\n\n"));
            signature.add(new Chunk(
                inv.getSignataireNom() != null && !inv.getSignataireNom().isBlank() ? inv.getSignataireNom() + "\n" : "", HEADING));
            signature.add(new Chunk(qualite, SMALL));
            PdfPCell celluleSignature = new PdfPCell(signature);
            celluleSignature.setBorder(Rectangle.NO_BORDER);
            bas.addCell(celluleSignature);

            doc.add(bas);

            doc.close();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Erreur génération PDF: " + e.getMessage(), e);
        }
    }

    private String libelleDestinataire(Invitation inv) {
        List<StructureInvitee> structures = inv.getStructuresInvitees();
        if (structures == null || structures.isEmpty()) {
            return "Tout-e Responsable de structure concernée";
        }
        if (structures.size() == 1) {
            String nom = structures.get(0).getStructure() != null ? structures.get(0).getStructure().getNom() : "";
            return "Monsieur/Madame le Responsable de " + nom;
        }
        return "Tout-e Responsable de structure concernée";
    }

    private String corpsParDefaut(Invitation inv) {
        return String.format(
            "Madame, Monsieur,%n%n" +
            "Nous avons l'honneur de vous inviter à participer à l'événement suivant :%n%n" +
            "  - Intitulé : %s%n" +
            "  - Date de début : %s%n" +
            "  - Date de fin : %s%n" +
            "  - Lieu : %s%n" +
            "  - Nombre de participants attendus : %d%n%n" +
            "Votre présence nous serait particulièrement précieuse.%n%n" +
            "Veuillez agréer, Madame, Monsieur, l'expression de nos salutations distinguées.",
            inv.getObjet() != null ? inv.getObjet() : "",
            inv.getDateDebut() != null ? inv.getDateDebut().format(FMT) : "Non précisée",
            inv.getDateFin() != null ? inv.getDateFin().format(FMT) : "Non précisée",
            inv.getLieu() != null ? inv.getLieu() : "Non précisé",
            inv.getNombreParticipant() != null ? inv.getNombreParticipant() : 0
        );
    }
}