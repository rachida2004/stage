package com.bf.dsi.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "structure")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Structure {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false)
    private String nom;
    private String adresse;
    private String telephone;
    private String email;
}