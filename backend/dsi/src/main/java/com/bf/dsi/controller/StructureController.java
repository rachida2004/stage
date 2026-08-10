package com.bf.dsi.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.bf.dsi.entity.Structure;
import com.bf.dsi.entity.Service; // 🎯 Utilise votre entité Service
import com.bf.dsi.repository.StructureRepository;
import com.bf.dsi.repository.ServiceRepository; // 🎯 Utilise votre repository
import java.util.List;
import java.util.Map;
import java.util.Optional;

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
    public ResponseEntity<?> ajouterStructure(@RequestBody Structure structure) {
        // 🎯 Deux structures ne doivent pas avoir le même nom (insensible à
        // la casse/aux espaces) : on vérifie AVANT de sauvegarder, plutôt que
        // de compter sur l'exception SQL de la contrainte unique (message
        // technique illisible pour l'utilisateur final).
        String nom = structure.getNom() == null ? null : structure.getNom().trim();
        if (nom == null || nom.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Le nom de la structure est obligatoire."));
        }
        if (repository.findByNomIgnoreCase(nom).isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("message", "Une structure nommée « " + nom + " » existe déjà."));
        }
        structure.setNom(nom);
        return ResponseEntity.ok(repository.save(structure));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> modifierStructure(@PathVariable Long id, @RequestBody Structure structure) {
        String nom = structure.getNom() == null ? null : structure.getNom().trim();
        if (nom == null || nom.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Le nom de la structure est obligatoire."));
        }
        // 🎯 On exclut la structure elle-même de la vérification (sinon on ne
        // pourrait jamais enregistrer une modification sans changer le nom).
        Optional<Structure> existante = repository.findByNomIgnoreCase(nom);
        if (existante.isPresent() && !existante.get().getId().equals(id)) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("message", "Une structure nommée « " + nom + " » existe déjà."));
        }
        structure.setId(id);
        structure.setNom(nom);
        return ResponseEntity.ok(repository.save(structure));
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