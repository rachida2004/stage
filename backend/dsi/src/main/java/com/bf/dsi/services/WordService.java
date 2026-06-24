package com.bf.dsi.services;

import com.bf.dsi.entity.Invitation;
import com.bf.dsi.entity.StructureInvitee;
import org.apache.poi.util.Units;
import org.apache.poi.xwpf.usermodel.*;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTBorder;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTTblBorders;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.STBorder;
import org.springframework.stereotype.Service;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Génère la lettre officielle d'invitation au format Word (.docx),
 * sur le même modèle que la version PDF (en-tête, objet, corps, pièce jointe, ampliation, signature).
 */
@Service
public class WordService {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    public byte[] generateInvitationWord(Invitation inv) {
        try (XWPFDocument document = new XWPFDocument();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {

            // ── En-tête : structure émettrice / logo / Burkina Faso ──
            XWPFTable enteteTable = document.createTable(1, 3);
            enteteTable.setWidth("100%");
            supprimerBordures(enteteTable);

            XWPFTableCell celluleGauche = enteteTable.getRow(0).getCell(0);
            celluleGauche.removeParagraph(0);
            XWPFParagraph pGauche = celluleGauche.addParagraph();
            String nomEmetteur = inv.getStructureEmettrice() != null && inv.getStructureEmettrice().getNom() != null
                ? inv.getStructureEmettrice().getNom().toUpperCase()
                : "MINISTÈRE — DIRECTION DES SYSTÈMES D'INFORMATION";

            XWPFRun ligne1 = pGauche.createRun();
            ligne1.setText(nomEmetteur);
            ligne1.setBold(true);
            ligne1.setFontSize(11);
            ligne1.addBreak();
            ligne1.addBreak();

            XWPFRun separateur1 = pGauche.createRun();
            separateur1.setText("--------------");
            separateur1.setFontSize(10);
            separateur1.addBreak();
            separateur1.addBreak();

            XWPFRun ligne2 = pGauche.createRun();
            ligne2.setText("SECRETARIAT GENERAL");
            ligne2.setBold(true);
            ligne2.setFontSize(11);
            ligne2.addBreak();
            ligne2.addBreak();

            XWPFRun separateur2 = pGauche.createRun();
            separateur2.setText("--------------");
            separateur2.setFontSize(10);
            separateur2.addBreak();
            separateur2.addBreak();

            XWPFRun ligne3 = pGauche.createRun();
            ligne3.setText("DIRECTION GENERALE DES SYSTEMES");
            ligne3.setBold(true);
            ligne3.setFontSize(11);
            ligne3.addBreak();

            XWPFRun ligne3b = pGauche.createRun();
            ligne3b.setText("D'INFORMATION");
            ligne3b.setBold(true);
            ligne3b.setFontSize(11);

            XWPFTableCell celluleLogo = enteteTable.getRow(0).getCell(1);
            celluleLogo.removeParagraph(0);
            XWPFParagraph pLogo = celluleLogo.addParagraph();
            pLogo.setAlignment(ParagraphAlignment.CENTER);
            XWPFRun runLogo = pLogo.createRun();
            try (InputStream is = getClass().getResourceAsStream("/images/logo.jpg")) {
                if (is != null) {
                    runLogo.addPicture(is, XWPFDocument.PICTURE_TYPE_JPEG, "logo.jpg",
                        Units.toEMU(45), Units.toEMU(38));
                }
            } catch (Exception ignored) {
                // si le logo est introuvable, on n'interrompt pas la génération du document
            }

            XWPFTableCell celluleDroite = enteteTable.getRow(0).getCell(2);
            celluleDroite.removeParagraph(0);
            XWPFParagraph burkina = celluleDroite.addParagraph();
            burkina.setAlignment(ParagraphAlignment.RIGHT);
            XWPFRun burkinaRun = burkina.createRun();
            burkinaRun.setText("BURKINA FASO");
            burkinaRun.setBold(true);
            burkinaRun.addBreak();
            XWPFRun motto = burkina.createRun();
            motto.setText("La Patrie ou la Mort, Nous vaincrons");
            motto.setItalic(true);
            motto.setFontSize(9);

            document.createParagraph(); // espace

            // ── Référence / date ──
            XWPFParagraph refP = document.createParagraph();
            XWPFRun refRun = refP.createRun();
            String reference = (inv.getNumeroReference() != null && !inv.getNumeroReference().isBlank())
                ? "N°" + inv.getNumeroReference() : "";
            refRun.setText(reference);

            XWPFParagraph dateP = document.createParagraph();
            dateP.setAlignment(ParagraphAlignment.RIGHT);
            XWPFRun dateRun = dateP.createRun();
            String ville = (inv.getVille() != null && !inv.getVille().isBlank()) ? inv.getVille() : "Ouagadougou";
            dateRun.setText(ville + ", le " + java.time.LocalDate.now().format(FMT));

            document.createParagraph();

            // ── Qualité du signataire / destinataire ──
            String qualite = (inv.getSignataireQualite() != null && !inv.getSignataireQualite().isBlank())
                ? inv.getSignataireQualite() : "Le Secrétaire général";

            XWPFParagraph qualiteP = document.createParagraph();
            qualiteP.setAlignment(ParagraphAlignment.CENTER);
            XWPFRun qualiteRun = qualiteP.createRun();
            qualiteRun.setText(qualite);
            qualiteRun.setBold(true);

            XWPFParagraph aP = document.createParagraph();
            aP.setAlignment(ParagraphAlignment.CENTER);
            aP.createRun().setText("À");

            XWPFParagraph destP = document.createParagraph();
            destP.setAlignment(ParagraphAlignment.CENTER);
            XWPFRun destRun = destP.createRun();
            destRun.setText(libelleDestinataire(inv));
            destRun.setBold(true);

            document.createParagraph();

            // ── Objet ──
            XWPFParagraph objetP = document.createParagraph();
            XWPFRun objetLabel = objetP.createRun();
            objetLabel.setText("Objet : ");
            objetLabel.setBold(true);
            objetP.createRun().setText(inv.getObjet() != null ? inv.getObjet() : "");

            document.createParagraph();

            // ── Corps ──
            String corps = (inv.getContenu() != null && !inv.getContenu().isBlank())
                ? inv.getContenu()
                : corpsParDefaut(inv);
            for (String ligne : corps.split("\\R")) {
                XWPFParagraph p = document.createParagraph();
                p.setAlignment(ParagraphAlignment.BOTH);
                p.createRun().setText(ligne);
            }

            document.createParagraph();

            // ── Pièce(s) jointe(s) ──
            if (inv.getPiecesJointes() != null && !inv.getPiecesJointes().isEmpty()) {
                String noms = inv.getPiecesJointes().stream()
                    .map(pj -> pj.getNom())
                    .reduce((a, b) -> a + ", " + b).orElse("");
                XWPFParagraph pjP = document.createParagraph();
                XWPFRun pjLabel = pjP.createRun();
                pjLabel.setText("Pièce jointe : ");
                pjLabel.setBold(true);
                pjP.createRun().setText(noms);
                document.createParagraph();
            }

            // ── Ampliation ──
            XWPFParagraph ampliationLabel = document.createParagraph();
            XWPFRun ampRun = ampliationLabel.createRun();
            ampRun.setText("Ampliation");
            ampRun.setBold(true);
            XWPFParagraph ampliationValeur = document.createParagraph();
            ampliationValeur.createRun().setText(inv.getAmpliation() != null ? inv.getAmpliation() : "—");

            // ── Signature ──
            XWPFParagraph signatureP = document.createParagraph();
            signatureP.setAlignment(ParagraphAlignment.CENTER);
            XWPFRun signatureRun = signatureP.createRun();
            signatureRun.addBreak();
            signatureRun.addBreak();
            if (inv.getSignataireNom() != null && !inv.getSignataireNom().isBlank()) {
                signatureRun.setText(inv.getSignataireNom());
                signatureRun.setBold(true);
                signatureRun.addBreak();
            }
            XWPFRun signatureQualiteRun = signatureP.createRun();
            signatureQualiteRun.setText(qualite);
            signatureQualiteRun.setFontSize(9);

            document.write(out);
            return out.toByteArray();

        } catch (IOException e) {
            throw new RuntimeException("Erreur lors de la génération du document Word", e);
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
            "- Intitulé : %s%n" +
            "- Date de début : %s%n" +
            "- Date de fin : %s%n" +
            "- Lieu : %s%n" +
            "- Nombre de participants attendus : %d%n%n" +
            "Votre présence nous serait particulièrement précieuse.%n%n" +
            "Veuillez agréer, Madame, Monsieur, l'expression de nos salutations distinguées.",
            inv.getObjet() != null ? inv.getObjet() : "",
            inv.getDateDebut() != null ? inv.getDateDebut().format(FMT) : "Non précisée",
            inv.getDateFin() != null ? inv.getDateFin().format(FMT) : "Non précisée",
            inv.getLieu() != null ? inv.getLieu() : "Non précisé",
            inv.getNombreParticipant() != null ? inv.getNombreParticipant() : 0
        );
    }

    /** Rend les bordures d'un tableau invisibles (utilisé pour l'en-tête type "lettre officielle"). */
    private void supprimerBordures(XWPFTable table) {
        var ctTbl = table.getCTTbl();
        var tblPr = ctTbl.getTblPr() != null ? ctTbl.getTblPr() : ctTbl.addNewTblPr();
        CTTblBorders borders = tblPr.isSetTblBorders() ? tblPr.getTblBorders() : tblPr.addNewTblBorders();

        CTBorder none1 = CTBorder.Factory.newInstance(); none1.setVal(STBorder.NONE);
        CTBorder none2 = CTBorder.Factory.newInstance(); none2.setVal(STBorder.NONE);
        CTBorder none3 = CTBorder.Factory.newInstance(); none3.setVal(STBorder.NONE);
        CTBorder none4 = CTBorder.Factory.newInstance(); none4.setVal(STBorder.NONE);
        CTBorder none5 = CTBorder.Factory.newInstance(); none5.setVal(STBorder.NONE);
        CTBorder none6 = CTBorder.Factory.newInstance(); none6.setVal(STBorder.NONE);

        borders.setTop(none1);
        borders.setLeft(none2);
        borders.setBottom(none3);
        borders.setRight(none4);
        borders.setInsideH(none5);
        borders.setInsideV(none6);
    }
}