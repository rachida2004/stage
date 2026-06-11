package com.bf.dsi.controller;

import com.bf.dsi.entity.Communication;
import com.bf.dsi.entity.Ticket;
import com.bf.dsi.entity.Utilisateur;
import com.bf.dsi.repository.CommunicationRepository;
import com.bf.dsi.repository.TicketRepository;
import com.bf.dsi.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/tickets/{ticketId}/communications")
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // Permet à Flutter Web/Desktop/Mobile d'interagir sans blocage CORS
public class CommunicationController {

    private final CommunicationRepository communicationRepository;
    private final TicketRepository ticketRepository;
    private final UtilisateurRepository utilisateurRepository;

    // 1. GET : Récupérer tous les messages d'un ticket
    @GetMapping
    public ResponseEntity<List<Communication>> getMessagesByTicket(@PathVariable Long ticketId) {
        return ResponseEntity.ok(communicationRepository.findByTicketIdOrderByDateAsc(ticketId));
    }

    // 2. POST : Envoyer un nouveau message
    @PostMapping
    public ResponseEntity<Communication> envoyerMessage(
            @PathVariable Long ticketId,
            @RequestBody Map<String, Object> body) {

        Ticket ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> new RuntimeException("Ticket introuvable"));

        Long auteurId = Long.valueOf(body.get("auteurId").toString());
        String texteMessage = body.get("message").toString();

        Utilisateur auteur = utilisateurRepository.findById(auteurId)
                .orElseThrow(() -> new RuntimeException("Utilisateur introuvable"));

        Communication communication = Communication.builder()
                .message(texteMessage)
                .ticket(ticket)
                .auteur(auteur)
                .build(); // La date sera générée par votre @PrePersist

        return ResponseEntity.ok(communicationRepository.save(communication));
    }
}