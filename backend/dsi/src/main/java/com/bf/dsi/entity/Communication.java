package com.bf.dsi.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity @Table(name = "communication")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Communication {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false)
    private String message;
    private LocalDateTime date;
    @ManyToOne @JoinColumn(name = "auteur_id", nullable = false)
    private Utilisateur auteur;
    @ManyToOne @JoinColumn(name = "ticket_id", nullable = false)
    private Ticket ticket;
    @PrePersist
    protected void onCreate() { if (date == null) date = LocalDateTime.now(); }
}
