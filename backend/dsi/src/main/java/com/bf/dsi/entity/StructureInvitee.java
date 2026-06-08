package com.bf.dsi.entity;

import com.bf.dsi.enums.StatutReponse;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name = "structure_invitee")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class StructureInvitee {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne @JoinColumn(name = "invitation_id", nullable = false)
    private Invitation invitation;
    @ManyToOne @JoinColumn(name = "structure_id", nullable = false)
    private Structure structure;

    @Enumerated(EnumType.STRING)
    @Column(name = "statut_reponse")
    @Builder.Default
    private StatutReponse statutReponse = StatutReponse.EN_ATTENTE;

    @Column(name = "date_envoi")
    private LocalDateTime dateEnvoi;
    @Column(name = "date_reponse")
    private LocalDateTime dateReponse;
    @Column(name = "lettre_chemin")
    private String lettreChemin;
    @Column(name = "lettre_generee")
    @Builder.Default
    private Boolean lettreGeneree = false;
    private String commentaire;

    @PrePersist
    protected void onCreate() { if (dateEnvoi == null) dateEnvoi = LocalDateTime.now(); }
}
