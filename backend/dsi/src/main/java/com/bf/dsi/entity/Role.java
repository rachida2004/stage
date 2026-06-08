package com.bf.dsi.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "role")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Role {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true)
    private String nom;
    private String description;
}
