package com.bf.dsi.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name = "piece_jointe_invitation")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class PieceJointeInvitation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false)
    private String nom;
    private String type;
    @Column(nullable = false)
    private String chemin;
    @Column(name = "date_envoi")
    private LocalDateTime dateEnvoi;
    @ManyToOne @JoinColumn(name = "invitation_id", nullable = false)
    private Invitation invitation;
    @PrePersist
    protected void onCreate() { if (dateEnvoi == null) dateEnvoi = LocalDateTime.now(); }
}