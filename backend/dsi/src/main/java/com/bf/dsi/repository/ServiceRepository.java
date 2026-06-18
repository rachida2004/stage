package com.bf.dsi.repository;

import com.bf.dsi.entity.Service;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List; // 🎯 Ne pas oublier l'importation de la liste

public interface ServiceRepository extends JpaRepository<Service, Long> {
    
    // 🎯 C'est cette ligne magique qui règle tout côté Base de données !
    List<Service> findByStructureId(Long structureId);
}