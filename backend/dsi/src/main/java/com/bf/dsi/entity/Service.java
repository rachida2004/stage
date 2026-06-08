package com.bf.dsi.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "service")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Service {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false)
    private String nom;
    private String description;

    // Colonne présente dans le SQL : structure_id
    @ManyToOne @JoinColumn(name = "structure_id")
    private Structure structure;
}