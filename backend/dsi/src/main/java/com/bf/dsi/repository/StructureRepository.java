package com.bf.dsi.repository;

import com.bf.dsi.entity.Structure;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface StructureRepository extends JpaRepository<Structure, Long> {

    /**
     * Recherche une structure par son nom exact.
     * Cette méthode permet au service de vérifier si une structure existe 
     * avant de décider d'en créer une nouvelle ou d'utiliser celle existante.
     * * @param nom Le nom de la structure recherchée
     * @return Un Optional contenant la structure si elle existe
     */
    Optional<Structure> findByNom(String nom);
}