package com.bf.dsi.entity;

import com.bf.dsi.enums.StatutInvitation;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;


@Entity @Table(name = "invitation")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Invitation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "objet", columnDefinition = "TEXT")
    private String objet;
    
@Column(name = "lieu")
    private String lieu;

    @Column(name = "date_debut", nullable = false)
    private LocalDate dateDebut;

    @Column(name = "date_fin", nullable = false)
    private LocalDate dateFin;

    @Column(name = "nombre_participant")
    @Builder.Default
    private Integer nombreParticipant = 0;

    @Enumerated(EnumType.STRING)
    @Column(name = "statut")
    @Builder.Default
    private StatutInvitation statut = StatutInvitation.EN_ATTENTE;

    @Builder.Default
    private String visibilite = "PUBLIC";

    // 🎯 Détermine sur quelle page (Reçu / Envoyer) l'invitation doit s'afficher :
    // "CREER"      -> formulaire "Créer" (lettre officielle)      -> page "Reçu"
    // "ENREGISTRER" -> formulaire rapide "Enregistrer"             -> page "Envoyer"
    @Column(name = "mode_creation")
    @Builder.Default
    private String modeCreation = "ENREGISTRER";

    @Column(name = "date_creation")
    private LocalDateTime dateCreation;

    // 🎯 Passe à true dès qu'une alerte "délai max sans affectation" a été
    // envoyée pour cette invitation, afin de ne pas la renvoyer à chaque
    // exécution de la tâche planifiée.
    @Builder.Default
    @Column(name = "alerte_delai_envoyee")
    private Boolean alerteDelaiEnvoyee = false;

    // ── Champs spécifiques à la lettre officielle (format ministère) ──────
    @Column(name = "numero_reference")
    private String numeroReference;

    @Column(name = "ville")
    @Builder.Default
    private String ville = "Ouagadougou";

    @Column(name = "contenu", columnDefinition = "TEXT")
    private String contenu;

    // 🎯 JSON du Delta flutter_quill (gras, italique, souligné, listes...)
    // du corps de la lettre. `contenu` reste le texte brut (compat/recherche/
    // fallback) ; `contenuDelta`, quand présent, est LA source de vérité
    // pour le rendu enrichi dans les exports PDF/Word.
    @Column(name = "contenu_delta", columnDefinition = "TEXT")
    private String contenuDelta;

    @Column(name = "ampliation")
    private String ampliation;

    @Column(name = "signataire_nom")
    private String signataireNom;

    @Column(name = "signataire_qualite")
    private String signataireQualite;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "structure_emettrice")
    private Structure structureEmettrice;

    // EAGER pour éviter LazyInitializationException
    @OneToMany(mappedBy = "invitation", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @Builder.Default
    private List<AffectationInvitation> affectations = new ArrayList<>();

    @OneToMany(mappedBy = "invitation", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @Builder.Default
    private List<PieceJointeInvitation> piecesJointes = new ArrayList<>();

    @OneToMany(mappedBy = "invitation", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @Builder.Default
    private List<StructureInvitee> structuresInvitees = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        if (dateCreation == null) dateCreation = LocalDateTime.now();
    }
    public StatutInvitation calculerStatutAutomatique() {
    // 🎯 Cette formule (En attente / Planifiée / En cours / Terminée / Non traitée)
    // ne s'applique qu'aux invitations en mode "ENREGISTRER" (formulaire rapide).
    // Les invitations "CREER" (lettre officielle) suivent leur propre statut,
    // piloté par les réponses de chaque structure invitée (Excusée/Confirmée/En attente),
    // donc on ne le recalcule pas ici pour ne pas l'écraser.
    if (!"ENREGISTRER".equalsIgnoreCase(this.getModeCreation())) {
        return this.getStatut();
    }

    LocalDate aujourdhui = LocalDate.now();
    boolean aDesAgents = this.getAffectations() != null && !this.getAffectations().isEmpty();
    
    // Cas 1 : La date de fin est dépassée (priorité la plus haute)
    if (aujourdhui.isAfter(this.getDateFin())) {
        return aDesAgents ? StatutInvitation.TERMINEE : StatutInvitation.NON_TRAITEE;
    }

    // Cas 2 : Tant qu'aucun agent n'est affecté, l'invitation reste "En attente" —
    // même si la date de début est déjà aujourd'hui ou dans l'intervalle.
    // (Sans ça, une invitation tout juste créée avec une date de début = aujourd'hui
    // passait directement en "En cours" sans jamais avoir été "En attente".)
    if (!aDesAgents) {
        return StatutInvitation.EN_ATTENTE;
    }

    // À partir d'ici, un ou plusieurs agents sont affectés et la date de fin
    // n'est pas dépassée.

    // Cas 3 : La date actuelle est dans l'intervalle [dateDebut, dateFin]
    if (!aujourdhui.isBefore(this.getDateDebut()) && !aujourdhui.isAfter(this.getDateFin())) {
        return StatutInvitation.EN_COURS;
    }

    // Cas 4 : La date actuelle est avant la date de début (agent déjà affecté,
    // événement futur)
    if (aujourdhui.isBefore(this.getDateDebut())) {
        return StatutInvitation.PLANIFIEE;
    }

    // Par sécurité, on retourne le statut actuel par défaut
    return this.getStatut();
}
}