package com.bf.dsi.controller;

import com.bf.dsi.entity.Utilisateur;
import com.bf.dsi.services.UtilisateurService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/utilisateurs")
@CrossOrigin(origins = "*") // Pour éviter les blocages CORS sur Flutter Web
public class UtilisateurController {

    private final UtilisateurService utilisateurService;

    public UtilisateurController(UtilisateurService utilisateurService) {
        this.utilisateurService = utilisateurService;
    }

    @GetMapping("/agents")
    public ResponseEntity<List<Utilisateur>> getAgents() {
        List<Utilisateur> agents = utilisateurService.getAgentsDSIDisponibles();
        return ResponseEntity.ok(agents);
    }
}