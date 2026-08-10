package com.bf.dsi.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "structure")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Structure {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    // 🎯 Deux structures ne peuvent pas porter le même nom (filet de
    // sécurité au niveau base de données, en complément du contrôle
    // applicatif fait dans StructureController).
    @Column(nullable = false, unique = true)
    private String nom;
    private String adresse;
    private String telephone;
    private String email;
}