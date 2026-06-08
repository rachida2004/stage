package com.bf.dsi.services;

import com.bf.dsi.entity.AffectationTicket;
import com.bf.dsi.entity.Ticket;
import com.bf.dsi.entity.Utilisateur;
import com.bf.dsi.enums.StatutTicket;
import com.bf.dsi.repository.TicketRepository;
import com.bf.dsi.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TicketService {

    private final TicketRepository ticketRepository;
    private final UtilisateurRepository utilisateurRepository;

    // AFFECTATION D'UN AGENT -> PASSE AUTOMATIQUEMENT EN "EN_COURS"
    @Transactional
    public Ticket affecterAgent(Long ticketId, Long agentId) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> new RuntimeException("Ticket introuvable"));
                
        Utilisateur agent = utilisateurRepository.findById(agentId)
                .orElseThrow(() -> new RuntimeException("Agent introuvable"));

        // Création de l'association en utilisant 'responsablePrincipal' au lieu de 'actif'
        AffectationTicket affectation = AffectationTicket.builder()
                .ticket(ticket)
                .agent(agent)
                .responsablePrincipal(true) // L'agent assigné devient le responsable principal
                .build(); // L'attribut dateAffectation sera géré par le @PrePersist de l'entité

        // Ajout dans le Set du Ticket (géré par CascadeType.ALL)
        ticket.getAffectations().add(affectation);
        
        // Règle métier : Si le ticket était "EN_ATTENTE", il passe "EN_COURS"
        if (ticket.getStatut() == StatutTicket.EN_ATTENTE) {
            ticket.setStatut(StatutTicket.EN_COURS);
        }

        return ticketRepository.save(ticket);
    }

    // CHANGEMENT DE STATUT MANUEL (En pause, Résolu, Fermé)
    @Transactional
    public Ticket modifierStatut(Long ticketId, StatutTicket nouveauStatut, String solution) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> new RuntimeException("Ticket introuvable"));

        // Règles métiers lors du changement de statut
        if (nouveauStatut == StatutTicket.RESOLU) {
            if (solution != null && !solution.trim().isEmpty()) {
                ticket.setSolution(solution);
            }
        }
        
        ticket.setStatut(nouveauStatut);
        return ticketRepository.save(ticket);
    }
}