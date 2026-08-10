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
    // 🎯 Un ticket n'a qu'UN SEUL agent affecté à la fois. Affecter un
    // nouvel agent REMPLACE l'ancien (au lieu de s'accumuler), ce qui
    // permet de "changer l'agent affecté" comme demandé.
    @Transactional
    public Ticket affecterAgent(Long ticketId, Long agentId) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> new RuntimeException("Ticket introuvable"));
                
        Utilisateur agent = utilisateurRepository.findById(agentId)
                .orElseThrow(() -> new RuntimeException("Agent introuvable"));

        boolean dejaAffecteAuMemeAgent = ticket.getAffectations().stream()
                .anyMatch(a -> a.getAgent().getUserId().equals(agentId));
        if (dejaAffecteAuMemeAgent) {
            throw new RuntimeException("Cet agent est déjà affecté à ce ticket.");
        }

        // On retire l'ancienne affectation (orphanRemoval=true sur la
        // collection la supprimera bien de la base à la sauvegarde).
        ticket.getAffectations().clear();

        AffectationTicket affectation = AffectationTicket.builder()
                .ticket(ticket)
                .agent(agent)
                .responsablePrincipal(true)
                .build();
        ticket.getAffectations().add(affectation);
        
        // Règle métier : Si le ticket était "EN_ATTENTE", il passe "EN_COURS"
        if (ticket.getStatut() == StatutTicket.EN_ATTENTE) {
            ticket.setStatut(StatutTicket.EN_COURS);
        }

        return ticketRepository.save(ticket);
    }

    // CHANGEMENT DE STATUT MANUEL
    @Transactional
    public Ticket modifierStatut(Long ticketId, StatutTicket nouveauStatut, String solution) {
        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> new RuntimeException("Ticket introuvable"));

        // Règles métiers
        if (nouveauStatut == StatutTicket.RESOLU) {
            if (solution != null && !solution.trim().isEmpty()) {
                ticket.setSolution(solution);
            } else {
                throw new RuntimeException("Une solution est requise pour clore le ticket.");
            }
        }
        
        ticket.setStatut(nouveauStatut);
        return ticketRepository.save(ticket);
    }
}