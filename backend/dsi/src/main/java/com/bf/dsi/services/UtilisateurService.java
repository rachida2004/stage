package com.bf.dsi.services;

import com.bf.dsi.entity.Utilisateur;
import com.bf.dsi.enums.UserRole;
import com.bf.dsi.repository.UtilisateurRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UtilisateurService {

    private final UtilisateurRepository utilisateurRepository;

    public UtilisateurService(UtilisateurRepository utilisateurRepository) {
        this.utilisateurRepository = utilisateurRepository;
    }

    public List<Utilisateur> getAgentsDSIDisponibles() {
        return utilisateurRepository.findByRoles_Nom(UserRole.AGENT_DSI.name());
    }
}