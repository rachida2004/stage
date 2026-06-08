package com.bf.dsi.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name = "affectation_invitation")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class AffectationInvitation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne @JoinColumn(name = "invitation_id", nullable = false)
    private Invitation invitation;
    @ManyToOne @JoinColumn(name = "agent_id", nullable = false)
    private Utilisateur agent;
    @Column(name = "responsable_principal")
    @Builder.Default
    private Boolean responsablePrincipal = false;
    @Column(name = "date_affectation")
    private LocalDateTime dateAffectation;
    @PrePersist
    protected void onCreate() { if (dateAffectation == null) dateAffectation = LocalDateTime.now(); }
}
