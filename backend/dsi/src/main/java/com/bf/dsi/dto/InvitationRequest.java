package com.bf.dsi.dto;

import lombok.Data;
import java.time.LocalDate;
import java.util.List;

@Data
public class InvitationRequest {
    private String objet;
    private LocalDate dateDebut;
    private LocalDate dateFin;
    private Integer nombreParticipants;
    private String lieu;
    private String visibilite;
    private String structureEmettrice;
    private Long structureEmettriceId;
    private String statut;
    private String modeCreation;

    // ── Champs de la lettre officielle ─────────────────────────────────
    private String numeroReference;
    private String ville;
    private String contenu;
    private String contenuDelta; // JSON Delta flutter_quill (mise en forme du corps de la lettre)
    private String ampliation;
    private String signataireNom;
    private String signataireQualite;

    // ── Structures destinataires (table structure_invitee) ──────────────
    private List<Long> structureIds;
}