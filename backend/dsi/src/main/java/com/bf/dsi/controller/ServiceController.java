package com.bf.dsi.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.bf.dsi.entity.Service;
import com.bf.dsi.entity.Structure;
import com.bf.dsi.repository.ServiceRepository;
import com.bf.dsi.repository.StructureRepository;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/services")
public class ServiceController {
    
    @Autowired
    private ServiceRepository repository;

    @Autowired
    private StructureRepository structureRepository;

    @GetMapping
    public List<Service> listerServices(@RequestParam(required = false) Long structureId) {
        if (structureId != null) {
            return repository.findByStructureId(structureId);
        }
        return repository.findAll();
    }

    // ════════════════════════════════════════════════════════════════════
    // 🎯 CRÉATION AUTOMATIQUE
    // ════════════════════════════════════════════════════════════════════
    @PostMapping
    public Service ajouterService(@RequestBody Map<String, Object> payload) {
        String nom = payload.get("nom").toString();
        String description = payload.get("description") != null ? payload.get("description").toString() : "";
        
        Long structureId = Long.valueOf(payload.get("structureId").toString());

        Structure structureParente = structureRepository.findById(structureId)
                .orElseThrow(() -> new RuntimeException("Structure introuvable avec l'ID: " + structureId));

        Service nouveauService = Service.builder()
                .nom(nom)
                .description(description)
                .structure(structureParente)
                .build();

        return repository.save(nouveauService);
    }

    // ════════════════════════════════════════════════════════════════════
    // 🎯 MODIFICATION HARMONISÉE ET SÉCURISÉE
    // ════════════════════════════════════════════════════════════════════
    @PutMapping("/{id}")
    public Service modifierService(@PathVariable Long id, @RequestBody Map<String, Object> payload) {
        // 1. Charger le service existant depuis la base de données
        Service serviceExistant = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Service introuvable avec l'ID: " + id));

        // 2. Mettre à jour les champs simples
        serviceExistant.setNom(payload.get("nom").toString());
        serviceExistant.setDescription(payload.get("description") != null ? payload.get("description").toString() : "");

        // 3. Mettre à jour dynamiquement la structure si un identifiant est fourni
        if (payload.get("structureId") != null) {
            Long structureId = Long.valueOf(payload.get("structureId").toString());
            Structure nouvelleStructure = structureRepository.findById(structureId)
                    .orElseThrow(() -> new RuntimeException("Structure introuvable avec l'ID: " + structureId));
            serviceExistant.setStructure(nouvelleStructure);
        }

        // 4. Sauvegarder l'instance mise à jour
        return repository.save(serviceExistant);
    }

    @DeleteMapping("/{id}")
    public boolean supprimerService(@PathVariable Long id) {
        if (repository.existsById(id)) {
            repository.deleteById(id);
            return true;
        }
        return false;
    }
}