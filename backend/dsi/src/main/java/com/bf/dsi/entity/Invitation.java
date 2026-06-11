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

    @Column(name = "date_creation")
    private LocalDateTime dateCreation;

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
    LocalDate aujourdhui = LocalDate.now();
    boolean aDesAgents = this.getAffectations() != null && !this.getAffectations().isEmpty();
    
    // Cas 1 : La date de fin est dépassée
    if (aujourdhui.isAfter(this.getDateFin())) {
        if (aDesAgents) {
            return StatutInvitation.TERMINEE;
        } else {
            return StatutInvitation.NON_TRAITEE;
        }
    }
    
    // Cas 2 : La date actuelle est dans l'intervalle [dateDebut, dateFin]
    // (aujourdhui >= dateDebut ET aujourdhui <= dateFin)
    if (!aujourdhui.isBefore(this.getDateDebut()) && !aujourdhui.isAfter(this.getDateFin())) {
        return StatutInvitation.EN_COURS;
    }
    
    // Cas 3 : La date actuelle est avant la date de début (Événement futur)
    if (aujourdhui.isBefore(this.getDateDebut())) {
        if (aDesAgents) {
            return StatutInvitation.PLANIFIEE;
        } else {
            return StatutInvitation.EN_ATTENTE;
        }
    }
    
    // Par sécurité, on retourne le statut actuel par défaut
    return this.getStatut();
}
}