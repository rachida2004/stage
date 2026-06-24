package com.bf.dsi.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.bf.dsi.entity.Structure;
import com.bf.dsi.entity.Service; // 🎯 Utilise votre entité Service
import com.bf.dsi.repository.StructureRepository;
import com.bf.dsi.repository.ServiceRepository; // 🎯 Utilise votre repository
import java.util.List;

@RestController
@RequestMapping("/api/structures")
public class StructureController {
    
    @Autowired
    private StructureRepository repository;

    @Autowired
    private ServiceRepository serviceRepository; // Injection du repository des services

    @GetMapping
    public List<Structure> listerStructure() {
        return repository.findAll();
    }

    // ════════════════════════════════════════════════════════════════════
    // 💡 ENDPOINT DE FILTRAGE DYNAMIQUE
    // Récupère uniquement les services d'une structure (ex: SEST, SRS pour la DSI)
    // ════════════════════════════════════════════════════════════════════
    @GetMapping("/{id}/services")
    public List<Service> listerServicesParStructure(@PathVariable Long id) {
        return serviceRepository.findByStructureId(id);
    }

    @PostMapping
    public Structure ajouterStructure(@RequestBody Structure structure) {
        return repository.save(structure);
    }

    @PutMapping("/{id}")
    public Structure modifierStructure(@PathVariable Long id, @RequestBody Structure structure) {
        structure.setId(id);
        return repository.save(structure);
    }

    @DeleteMapping("/{id}")
    public boolean supprimerStructure(@PathVariable Long id) {
        if (repository.existsById(id)) {
            repository.deleteById(id);
            return true;
        }
        return false;
    }
}