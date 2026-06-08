package com.bf.dsi.repository;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import com.bf.dsi.entity.Utilisateur;

import java.util.List;
import java.util.Optional;

public interface UtilisateurRepository extends JpaRepository<Utilisateur, Long> {

    @EntityGraph(attributePaths = {"roles"})
    Optional<Utilisateur> findByEmail(String email);
    
    boolean existsByEmail(String email);

    /**
     * Récupère tous les utilisateurs par le nom de leur rôle.
     * Correction effectuée : r.nom au lieu de r.name et changement de nom de méthode.
     */
    @EntityGraph(attributePaths = {"roles"})
    @Query("SELECT u FROM Utilisateur u JOIN u.roles r WHERE r.nom = :nom")
    List<Utilisateur> findByRoles_Nom(@Param("nom") String nom);
}