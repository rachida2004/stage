package com.bf.dsi.entity;
import com.bf.dsi.enums.UserRole;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.*;

@Entity @Table(name = "utilisateur")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class Utilisateur {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long userId;

    @Column(nullable = false)
    private String nom;
    @Column(nullable = false)
    private String prenom;
    @Column(nullable = false, unique = true)
    private String email;
    private String telephone;
    @Column(name = "mot_de_passe", nullable = false)
    private String motDePasse;
    @Column(name = "date_creation")
    private LocalDateTime dateCreation;
    private String iu;
    @Builder.Default
    private Boolean actif = true;

    @ManyToOne @JoinColumn(name = "service_id")
    private Service service;

    @ManyToOne @JoinColumn(name = "structure_id")
    private Structure structure;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(name = "utilisateur_role",
        joinColumns = @JoinColumn(name = "user_id"),
        inverseJoinColumns = @JoinColumn(name = "role_id"))
    @Builder.Default
    private Set<Role> roles = new HashSet<>();

    @PrePersist
    protected void onCreate() { if (dateCreation == null) dateCreation = LocalDateTime.now(); }

    public String getInitiales() {
        String n = (nom != null && !nom.isEmpty()) ? String.valueOf(nom.charAt(0)).toUpperCase() : "";
        String p = (prenom != null && !prenom.isEmpty()) ? String.valueOf(prenom.charAt(0)).toUpperCase() : "";
        return n + p;
    }

    public UserRole getPrimaryRole() {
        if (roles == null || roles.isEmpty()) return UserRole.USAGER;
        try {
            return roles.stream()
                .map(r -> UserRole.valueOf(r.getNom()))
                .findFirst().orElse(UserRole.USAGER);
        } catch (Exception e) { return UserRole.USAGER; }
    }
}
