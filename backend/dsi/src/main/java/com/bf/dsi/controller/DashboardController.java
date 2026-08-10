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
            // 🎯 Les invitations créées via "Créer" (lettres officielles) ne sont
            // pas comptabilisées sur le tableau de bord — seules celles créées
            // via "Enregistrer" entrent dans ces statistiques.
            final String mode = "ENREGISTRER";

            // 🎯 On recalcule le statut de chaque invitation à la volée
            // (calculerStatutAutomatique()) au lieu de compter sur la colonne
            // "statut" stockée en base, qui ne se met à jour qu'au moment d'une
            // affectation d'agent et peut devenir obsolète (ex: date de fin
            // dépassée depuis sans nouvelle affectation) — pour que les
            // compteurs du tableau de bord correspondent toujours à ce qui est
            // affiché dans la liste des invitations.
            List<com.bf.dsi.entity.Invitation> toutes = invitationRepo.findByModeCreation(mode);
            Map<StatutInvitation, Long> parStatut = toutes.stream()
                .collect(java.util.stream.Collectors.groupingBy(
                    com.bf.dsi.entity.Invitation::calculerStatutAutomatique,
                    java.util.stream.Collectors.counting()));

            Map<String, Object> stats = new LinkedHashMap<>();
            stats.put("totalInvitations",       toutes.size());
            stats.put("invitationsEnAttente",   parStatut.getOrDefault(StatutInvitation.EN_ATTENTE, 0L));
            stats.put("invitationsPlanifiees",  parStatut.getOrDefault(StatutInvitation.PLANIFIEE, 0L));
            stats.put("invitationsEnCours",     parStatut.getOrDefault(StatutInvitation.EN_COURS, 0L));
            stats.put("invitationsTerminees",   parStatut.getOrDefault(StatutInvitation.TERMINEE, 0L));
            stats.put("invitationsNonTraitees", parStatut.getOrDefault(StatutInvitation.NON_TRAITEE, 0L));
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
            // 🎯 Idem : on n'affiche que les invitations "Enregistrer" sur le tableau de bord
            Page<com.bf.dsi.entity.Invitation> page = invitationRepo.findByModeCreationOrderByIdDesc(
                "ENREGISTRER", PageRequest.of(0, 5));
            return ResponseEntity.ok(page.getContent().stream().map(i -> Map.of(
                "id", i.getId(),
                "objet", i.getObjet() != null ? i.getObjet() : "",
                "structureEmettrice", i.getStructureEmettrice() != null ? i.getStructureEmettrice().getNom() : "",
                "dateDebut", i.getDateDebut(),
                "dateFin", i.getDateFin(),
                "status", i.calculerStatutAutomatique(),
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
                null, null, null, null, null, PageRequest.of(0, 5, Sort.by("dateCreation").descending()));
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