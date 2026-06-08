package com.bf.dsi.entity;

import com.bf.dsi.enums.*;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;

@Entity 
@Table(name = "ticket")
@Data 
@NoArgsConstructor 
@AllArgsConstructor 
@Builder
public class Ticket {

    @Id 
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(name = "date_creation")
    private LocalDateTime dateCreation;

    @Enumerated(EnumType.STRING)
    @Column(name = "statut")
    @Builder.Default
    private StatutTicket statut = StatutTicket.EN_ATTENTE;

    @Enumerated(EnumType.STRING)
    @Column(name = "priorite")
    @Builder.Default
    private Priorite priorite = Priorite.MOYENNE;

    @Column(columnDefinition = "TEXT")
    private String solution;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "structure_id")
    private Structure structure;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "createur_id")
    private Utilisateur createur;

    // Exclusion de ToString et EqualsAndHashCode pour éviter les boucles infinies (StackOverflowError)
    @OneToMany(mappedBy = "ticket", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @Builder.Default
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Set<AffectationTicket> affectations = new LinkedHashSet<>();

    @OneToMany(mappedBy = "ticket", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @Builder.Default
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Set<Communication> communications = new LinkedHashSet<>();

    @OneToMany(mappedBy = "ticket", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @Builder.Default
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Set<PieceJointeTicket> piecesJointes = new LinkedHashSet<>();

    @PrePersist
    protected void onCreate() {
        if (dateCreation == null) {
            dateCreation = LocalDateTime.now();
        }
    }
}