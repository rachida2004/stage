package com.bf.dsi.controller;

import com.bf.dsi.enums.*;
import com.bf.dsi.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {
    private final InvitationRepository invitationRepo;
    private final TicketRepository ticketRepo;
    private final UtilisateurRepository utilisateurRepo;

    @GetMapping("/stats")
    public ResponseEntity<?> getStats() {
        try {
            Map<String, Object> stats = new LinkedHashMap<>();
            stats.put("totalInvitations",       invitationRepo.count());
            stats.put("invitationsEnAttente",   invitationRepo.countByStatut(StatutInvitation.EN_ATTENTE));
            stats.put("invitationsPlanifiees",  invitationRepo.countByStatut(StatutInvitation.PLANIFIEE));
            stats.put("invitationsEnCours",     invitationRepo.countByStatut(StatutInvitation.EN_COURS));
            stats.put("invitationsTerminees",   invitationRepo.countByStatut(StatutInvitation.TERMINEE));
            stats.put("invitationsNonTraitees", invitationRepo.countByStatut(StatutInvitation.NON_TRAITEE));
            stats.put("totalTickets",           ticketRepo.count());
            stats.put("ticketsOuverts",         ticketRepo.countByStatutNot(StatutTicket.FERME));
            stats.put("totalUsers",             utilisateurRepo.count());
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            // Retourner des zéros si erreur DB
            return ResponseEntity.ok(Map.of(
                "totalInvitations", 0, "invitationsEnAttente", 0,
                "invitationsPlanifiees", 0, "invitationsEnCours", 0,
                "invitationsTerminees", 0, "invitationsNonTraitees", 0,
                "totalTickets", 0, "ticketsOuverts", 0, "totalUsers", 0,
                "error", e.getMessage()
            ));
        }
    }

    @GetMapping("/invitations-recentes")
    public ResponseEntity<?> getRecentInvitations() {
        try {
            Page<com.bf.dsi.entity.Invitation> page = invitationRepo.findAllFiltered(
                null, null, PageRequest.of(0, 5, Sort.by("dateCreation").descending()));
            return ResponseEntity.ok(page.getContent().stream().map(i -> Map.of(
                "id", i.getId(),
                "objet", i.getObjet() != null ? i.getObjet() : "",
                "structureEmettrice", i.getStructureEmettrice() != null ? i.getStructureEmettrice().getNom() : "",
                "dateDebut", i.getDateDebut(),
                "dateFin", i.getDateFin(),
                "status", i.getStatut(),
                "nombreParticipants", i.getNombreParticipant() != null ? i.getNombreParticipant() : 0
            )).toList());
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }

    @GetMapping("/tickets-recents")
    public ResponseEntity<?> getRecentTickets() {
        try {
            Page<com.bf.dsi.entity.Ticket> page = ticketRepo.findAllFiltered(
                null, null, null, PageRequest.of(0, 5, Sort.by("dateCreation").descending()));
            return ResponseEntity.ok(page.getContent().stream().map(t -> Map.of(
                "id", t.getId(),
                "description", t.getDescription(),
                "structure", t.getStructure() != null ? t.getStructure().getNom() : "",
                "status", t.getStatut(),
                "priority", t.getPriorite(),
                "createdAt", t.getDateCreation()
            )).toList());
        } catch (Exception e) {
            return ResponseEntity.ok(List.of());
        }
    }
}