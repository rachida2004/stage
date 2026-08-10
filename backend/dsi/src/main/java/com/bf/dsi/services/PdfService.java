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

            // ── Qualité du signataire (calculée ici pour être réutilisée dans l'en-tête et la signature) ──
            String qualite = (inv.getSignataireQualite() != null && !inv.getSignataireQualite().isBlank())
                ? inv.getSignataireQualite() : "Le Secrétaire général";
            String ville = (inv.getVille() != null && !inv.getVille().isBlank()) ? inv.getVille() : "Ouagadougou";

            // ── En-tête : structure émettrice (gauche) / logo (centre) / Burkina Faso + date + qualité (droite) ──
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
            String reference = (inv.getNumeroReference() != null && !inv.getNumeroReference().isBlank())
                ? "N°" + inv.getNumeroReference() : "";
            if (!reference.isBlank()) {
                gaucheP.add(new Chunk("\n\n" + reference, SMALL));
            }

            PdfPCell gauche = new PdfPCell(gaucheP);
            gauche.setBorder(Rectangle.NO_BORDER);
            gauche.setVerticalAlignment(Element.ALIGN_TOP);
            entete.addCell(gauche);

            PdfPCell celluleLogo = new PdfPCell();
            celluleLogo.setBorder(Rectangle.NO_BORDER);
            celluleLogo.setHorizontalAlignment(Element.ALIGN_CENTER);
            celluleLogo.setVerticalAlignment(Element.ALIGN_TOP);
            celluleLogo.setPaddingTop(28f); // 🎯 fait descendre le logo pour l'aligner visuellement avec le texte
            try {
                Image logo = Image.getInstance(
                    getClass().getResourceAsStream("/images/logo.jpg").readAllBytes());
                logo.scaleToFit(48f, 40f);
                celluleLogo.addElement(logo);
            } catch (Exception ignored) {
                // si le logo est introuvable, on laisse la cellule vide plutôt que d'échouer la génération
            }
            entete.addCell(celluleLogo);

            // 🎯 "BURKINA FASO", "Ouagadougou, le ..." et la qualité du signataire
            // sont maintenant regroupés dans le MÊME bloc droit, aligné avec le
            // bloc ministère de gauche (même ligne de départ, pas de tableau
            // séparé plus bas qui désalignait tout).
            // 🎯 "BURKINA FASO", "Ouagadougou, le ...", la qualité du signataire,
            // "À" et le destinataire sont regroupés dans le MÊME bloc droit,
            // aligné avec le bloc ministère de gauche. Chaque ligne est un
            // paragraphe séparé pour contrôler finement l'espacement, et "À"
            // est légèrement décalé vers la gauche par rapport au reste.
            PdfPCell celluleDroite = new PdfPCell();
            celluleDroite.setBorder(Rectangle.NO_BORDER);
            celluleDroite.setVerticalAlignment(Element.ALIGN_TOP);

            Paragraph pBurkina = new Paragraph();
            pBurkina.setAlignment(Element.ALIGN_RIGHT);
            pBurkina.add(new Chunk("BURKINA FASO\n", SMALL_B));
            pBurkina.add(new Chunk("La Patrie ou la Mort, Nous vaincrons", ITALIC_SM));
            pBurkina.setSpacingAfter(10f);
            celluleDroite.addElement(pBurkina);

            Paragraph pDate = new Paragraph(ville + ", le " + java.time.LocalDate.now().format(FMT), NORMAL);
            pDate.setAlignment(Element.ALIGN_RIGHT);
            pDate.setSpacingAfter(10f);
            celluleDroite.addElement(pDate);

            Paragraph pQualite = new Paragraph(qualite, TITLE);
            pQualite.setAlignment(Element.ALIGN_RIGHT);
            pQualite.setSpacingAfter(2f);
            celluleDroite.addElement(pQualite);

            Paragraph pA = new Paragraph("À", NORMAL);
            pA.setAlignment(Element.ALIGN_RIGHT);
            pA.setIndentationRight(22f); // léger décalage vers la gauche
            celluleDroite.addElement(pA);

            Paragraph pDestinataire = new Paragraph(libelleDestinataire(inv), TITLE);
            pDestinataire.setAlignment(Element.ALIGN_RIGHT);
            celluleDroite.addElement(pDestinataire);

            entete.addCell(celluleDroite);
            doc.add(entete);
            doc.add(Chunk.NEWLINE);
            doc.add(Chunk.NEWLINE);
            doc.add(Chunk.NEWLINE); // 🎯 espace supplémentaire pour faire descendre "Objet"

            // ── Objet ──
            Paragraph objet = new Paragraph();
            objet.add(new Chunk("Objet : ", HEADING));
            objet.add(new Chunk(inv.getObjet() != null ? inv.getObjet() : "", NORMAL));
            doc.add(objet);
            doc.add(Chunk.NEWLINE);

            // ── Corps de la lettre ──
            // 🎯 Si un Delta Quill (mise en forme) est disponible, on le rend
            // fidèlement (gras/italique/souligné/titres/listes/alignement).
            // Sinon on retombe sur le texte brut comme avant.
            List<QuillDeltaParser.Block> blocsCorps = QuillDeltaParser.parse(inv.getContenuDelta());
            if (!blocsCorps.isEmpty()) {
                ajouterCorpsEnrichi(doc, blocsCorps);
            } else {
                String corps = (inv.getContenu() != null && !inv.getContenu().isBlank())
                    ? inv.getContenu()
                    : corpsParDefaut(inv);
                Paragraph body = new Paragraph(corps, NORMAL);
                body.setAlignment(Element.ALIGN_JUSTIFIED);
                body.setLeading(18);
                doc.add(body);
            }
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

            // 1. Colonne de Gauche : AMPLIATION (Vert)
            Paragraph ampliationP = new Paragraph();
            ampliationP.add(new Chunk("Ampliation\n", HEADING));
            String ampliationBrute = inv.getAmpliation();
            if (ampliationBrute != null && !ampliationBrute.isBlank()) {
                String[] destinatairesAmpliation = ampliationBrute.split(";");
                for (String dest : destinatairesAmpliation) {
                    String d = dest.trim();
                    if (!d.isEmpty()) {
                        ampliationP.add(new Chunk("- " + d + "\n", SMALL));
                    }
                }
            } else {
                ampliationP.add(new Chunk("—\n", SMALL));
            }
            PdfPCell celluleAmpliation = new PdfPCell(ampliationP);
            celluleAmpliation.setBorder(Rectangle.NO_BORDER);
            celluleAmpliation.setVerticalAlignment(Element.ALIGN_TOP);
            bas.addCell(celluleAmpliation);

            // 2. Colonne de Droite : SIGNATURE ET QUALITÉ (Rose)
            Paragraph signature = new Paragraph();
            signature.setAlignment(Element.ALIGN_CENTER);
            
            // Qualité (ex: "Le Secrétaire général") au même niveau qu'Ampliation
            signature.add(new Chunk(qualite + "\n", HEADING));
            
            // Espace réservé pour la signature manuscrite / tampon
            signature.add(new Chunk("\n\n\n\n")); 
            
            // Nom du signataire (ex: "rachid barro") sous la signature
            if (inv.getSignataireNom() != null && !inv.getSignataireNom().isBlank()) {
                signature.add(new Chunk(inv.getSignataireNom(), NORMAL));
            }

            PdfPCell celluleSignature = new PdfPCell(signature);
            celluleSignature.setBorder(Rectangle.NO_BORDER);
            celluleSignature.setVerticalAlignment(Element.ALIGN_TOP); // Aligne le haut avec Ampliation
            bas.addCell(celluleSignature);

            doc.add(bas);

            doc.close();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Erreur génération PDF: " + e.getMessage(), e);
        }
    }

    /**
     * Rend une liste de blocs (issus du Delta Quill) dans le document PDF,
     * en respectant gras/italique/souligné/alignement/titres/listes.
     */
    private void ajouterCorpsEnrichi(Document doc, List<QuillDeltaParser.Block> blocs) throws DocumentException {
        int compteurOrdonne = 0;
        for (QuillDeltaParser.Block bloc : blocs) {
            if (!"ordered".equals(bloc.listType)) compteurOrdonne = 0;

            Paragraph p = new Paragraph();
            p.setLeading(18);
            p.setSpacingAfter(4f);

            // Puce / numéro en préfixe du premier chunk du bloc
            if ("bullet".equals(bloc.listType)) {
                p.add(new Chunk("•  ", NORMAL));
            } else if ("ordered".equals(bloc.listType)) {
                compteurOrdonne++;
                p.add(new Chunk(compteurOrdonne + ".  ", NORMAL));
            }

            for (QuillDeltaParser.Run run : bloc.runs) {
                Font f = policePour(bloc.header, run.bold, run.italic, run.underline);
                p.add(new Chunk(run.text, f));
            }

            switch (bloc.align) {
                case "center":  p.setAlignment(Element.ALIGN_CENTER); break;
                case "right":   p.setAlignment(Element.ALIGN_RIGHT); break;
                case "justify": p.setAlignment(Element.ALIGN_JUSTIFIED); break;
                default:        p.setAlignment(Element.ALIGN_LEFT);
            }

            doc.add(p);
        }
    }

    /** Choisit la police iText en fonction du titre (header 1-3) et des styles inline. */
    private Font policePour(Integer header, boolean bold, boolean italic, boolean underline) {
        float taille = 11f;
        int style = Font.NORMAL;
        if (header != null) {
            bold = true; // les titres sont toujours en gras
            taille = header == 1 ? 16f : header == 2 ? 14f : 12.5f;
        }
        if (bold) style |= Font.BOLD;
        if (italic) style |= Font.ITALIC;
        if (underline) style |= Font.UNDERLINE;
        return new Font(Font.FontFamily.HELVETICA, taille, style);
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