package com.bf.dsi.entity;

    

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name = "notification")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Notification {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false)
    private String message;
    @Column(name = "date_envoi")
    private LocalDateTime dateEnvoi;
    @Builder.Default
    private String canal = "INTERNE";
    @Builder.Default
    private Boolean statut = false; // false = non lu
    @Builder.Default
    private String categorie = "INVITATION";
    @Column(name = "resource_id")
    private String resourceId;
    @Column(name = "action_label")
    private String actionLabel;
    @ManyToOne @JoinColumn(name = "utilisateur_id", nullable = false)
    private Utilisateur utilisateur;
    @PrePersist
    protected void onCreate() { if (dateEnvoi == null) dateEnvoi = LocalDateTime.now(); }
}
