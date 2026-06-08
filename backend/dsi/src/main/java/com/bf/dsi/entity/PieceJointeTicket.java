package com.bf.dsi.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity 
@Table(name = "piece_jointe_ticket")
@Data 
@NoArgsConstructor 
@AllArgsConstructor 
@Builder
public class PieceJointeTicket {

    @Id 
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nom;
    
    private String type;

    @Column(nullable = false)
    private String chemin;

    @Column(name = "date_envoi")
    private LocalDateTime dateEnvoi;

    // Exclusion de ToString et EqualsAndHashCode pour rompre la boucle infinie avec Ticket
    @ManyToOne 
    @JoinColumn(name = "ticket_id", nullable = false)
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Ticket ticket;

    @PrePersist
    protected void onCreate() { 
        if (dateEnvoi == null) {
            dateEnvoi = LocalDateTime.now(); 
        }
    }
}