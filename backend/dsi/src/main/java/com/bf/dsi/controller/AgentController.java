package com.bf.dsi.controller;

import com.bf.dsi.entity.Utilisateur;
import com.bf.dsi.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * Expose la liste des agents pour le modal d'affectation Flutter.
 * GET /api/agents            → tous les agents (rôle AGENT_DSI ou ADMIN)
 * GET /api/agents?role=ADMIN → filtrés par rôle spécifique
 */
@RestController
@RequestMapping("/api/agents")
@RequiredArgsConstructor
public class AgentController {

    private final UtilisateurRepository utilisateurRepo;

    @GetMapping
    public ResponseEntity<?> getAgents(
            @RequestParam(required = false) String role) {

        List<Utilisateur> agents;

        if (role != null && !role.isBlank()) {
            // Filtre par rôle spécifique (ex: ?role=AGENT_DSI)
            agents = utilisateurRepo.findByRoles_Nom(role);
        } else {
            // Alignement strict sur les noms de rôles présents dans la base PostgreSQL
            List<Utilisateur> agentsDsi = utilisateurRepo.findByRoles_Nom("AGENT_DSI");
            List<Utilisateur> admins    = utilisateurRepo.findByRoles_Nom("ADMIN");
            
            Set<Long> vus = new HashSet<>();
            agents = new ArrayList<>();
            
            for (Utilisateur u : agentsDsi) {
                if (vus.add(u.getUserId())) {
                    agents.add(u);
                }
            }
            for (Utilisateur u : admins) {
                if (vus.add(u.getUserId())) {
                    agents.add(u);
                }
            }
        }

        // CORRECTION : Suppression du .filter(...) sur le statut actif qui bloquait les résultats
        List<Map<String, Object>> result = agents.stream()
                .sorted(Comparator.comparing(Utilisateur::getNom, Comparator.nullsLast(String::compareToIgnoreCase)))
                .map(this::toDto)
                .toList();

        return ResponseEntity.ok(result);
    }

    private Map<String, Object> toDto(Utilisateur u) {
        Map<String, Object> m = new LinkedHashMap<>();
        
        m.put("id",          u.getUserId()); 
        m.put("nom",         u.getNom() != null ? u.getNom() : "");
        m.put("prenom",      u.getPrenom() != null ? u.getPrenom() : "");
        m.put("email",       u.getEmail() != null ? u.getEmail() : "");
        m.put("initiales",   u.getInitiales() != null ? u.getInitiales() : "");
        m.put("role",        u.getPrimaryRole() != null ? u.getPrimaryRole().name() : "");
        m.put("structure",   u.getStructure() != null ? u.getStructure().getNom() : null);
        m.put("service",     u.getService() != null ? u.getService().getNom() : null);
        
        // Sécurisation du champ actif : renvoie true par défaut si la valeur en base est null
        m.put("active",      u.getActif() != null ? u.getActif() : true);
        
        return m;
    }
}