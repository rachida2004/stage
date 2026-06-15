package com.bf.dsi.controller;

import com.bf.dsi.dto.TicketRequest;
import com.bf.dsi.dto.MessageRequest;
import com.bf.dsi.entity.*;
import com.bf.dsi.enums.*;
import com.bf.dsi.repository.*;
import com.bf.dsi.services.FileStorageService;
import com.bf.dsi.services.TicketService;
import com.bf.dsi.services.AppSettingService; // 🎯 1. Importation de ton nouveau service de configuration
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.*;

@RestController
@RequestMapping("/api/tickets")
@RequiredArgsConstructor
public class TicketController {

    private final TicketRepository ticketRepo;
    private final UtilisateurRepository utilisateurRepo;
    private final StructureRepository structureRepo;
    private final CommunicationRepository communicationRepo;
    private final NotificationRepository notificationRepo;
    private final FileStorageService fileStorage;
    private final TicketService ticketService;
    private final AppSettingService appSettingService; // 🎯 2. Injection automatique via @RequiredArgsConstructor

    @GetMapping
    public ResponseEntity<?> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String statut,
            @RequestParam(required = false) String priorite) {
            
        StatutTicket statutEnum = (statut != null && !statut.trim().isEmpty()) ? StatutTicket.valueOf(statut.toUpperCase()) : null;
        Priorite prioriteEnum = (priorite != null && !priorite.trim().isEmpty()) ? parsePriorite(priorite) : null;

        Page<Ticket> result = ticketRepo.findAllFiltered(
            search, statutEnum, prioriteEnum,
            PageRequest.of(page, size)
        );
        return ResponseEntity.ok(toPageResponse(result));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return ticketRepo.findById(id)
            .map(t -> ResponseEntity.ok(toDto(t)))
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> createJson(@RequestBody TicketRequest req) {
        Ticket ticket = Ticket.builder()
            .description(req.getDescription())
            .statut(StatutTicket.EN_ATTENTE)
            .priorite(parsePriorite(req.getPriority() != null ? req.getPriority() : "MOYENNE"))
            .build();

        if (req.getStructure() != null)
            structureRepo.findAll().stream()
                .filter(s -> s.getNom().equalsIgnoreCase(req.getStructure()))
                .findFirst().ifPresent(ticket::setStructure);

        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(ticketRepo.save(ticket)));
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> createMultipart(
            @RequestParam String description,
            @RequestParam(required = false) String structure,
            @RequestParam(defaultValue = "MOYENNE") String priority,
            @RequestParam(required = false) MultipartFile file,
            @RequestParam(required = false) Long createurId) {

        Ticket ticket = Ticket.builder()
            .description(description)
            .statut(StatutTicket.EN_ATTENTE)
            .priorite(parsePriorite(priority))
            .build();

        if (structure != null)
            structureRepo.findAll().stream()
                .filter(s -> s.getNom().equalsIgnoreCase(structure))
                .findFirst().ifPresent(ticket::setStructure);

        if (createurId != null)
            utilisateurRepo.findById(createurId).ifPresent(ticket::setCreateur);

        Ticket saved = ticketRepo.save(ticket);

        if (file != null && !file.isEmpty()) {
            String path = fileStorage.store(file, "tickets/" + saved.getId());
            PieceJointeTicket pj = PieceJointeTicket.builder()
                .nom(file.getOriginalFilename()).type(file.getContentType())
                .chemin(path).ticket(saved).build();
            saved.getPiecesJointes().add(pj);
            ticketRepo.save(saved);
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(saved));
    }

    @PutMapping("/{id}/statut")
    public ResponseEntity<?> changerStatut(@PathVariable Long id, @RequestBody Map<String, String> body) {
        try {
            StatutTicket nouveauStatut = StatutTicket.valueOf(body.get("statut"));
            String solution = body.get("solution");
            
            Ticket saved = ticketService.modifierStatut(id, nouveauStatut, solution);
            
            // 🎯 3. Condition sur l'option "Notifications internes" gérée par l'admin
            if (saved.getStatut() == StatutTicket.RESOLU && saved.getCreateur() != null) {
                if (appSettingService.isInternalNotificationEnabled()) {
                    notificationRepo.save(Notification.builder()
                        .message("Votre ticket #" + id + " a été résolu.")
                        .categorie("TICKET").actionLabel("Voir").resourceId(id.toString())
                        .utilisateur(saved.getCreateur()).build());
                }
                
                // Optionnel : si tu as un service mail, tu ajoutes la même vérification pour l'email
                // if (appSettingService.isEmailNotificationEnabled()) { emailService.send(...) }
            }
            return ResponseEntity.ok(toDto(saved));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Statut ou traitement invalide"));
        }
    }

    @PostMapping("/{ticketId}/affecter/{agentId}")
    public ResponseEntity<?> affecterAgent(@PathVariable Long ticketId, @PathVariable Long agentId) {
        Ticket ticket = ticketService.affecterAgent(ticketId, agentId);

        Utilisateur agent = utilisateurRepo.findById(agentId).orElseThrow();
        
        // 🎯 4. Condition sur l'option "Notifications internes" lors de l'affectation
        if (appSettingService.isInternalNotificationEnabled()) {
            notificationRepo.save(Notification.builder()
                .message("Vous avez été affecté au ticket #" + ticketId)
                .categorie("TICKET").actionLabel("Voir").resourceId(ticketId.toString())
                .utilisateur(agent).build());
        }

        // Si tu as configuré un service d'envoi de mail, tu peux greffer la vérification ici
        // if (appSettingService.isEmailNotificationEnabled()) { ... }

        return ResponseEntity.ok(toDto(ticket));
    }

    @PostMapping("/{ticketId}/messages")
    public ResponseEntity<?> envoyerMessage(@PathVariable Long ticketId, @RequestBody MessageRequest req) { 
        Ticket ticket = ticketRepo.findById(ticketId).orElseThrow();
        Long auteurId = req.getAuteurId(); 
        Utilisateur auteur = utilisateurRepo.findById(auteurId).orElseThrow();
        
        Communication comm = Communication.builder()
            .message(req.getMessage())
            .ticket(ticket)
            .auteur(auteur)
            .build();
        communicationRepo.save(comm);

        Utilisateur dest = auteurId.equals(
            ticket.getAffectations().stream()
                .filter(a -> Boolean.TRUE.equals(a.getResponsablePrincipal()))
                .map(a -> a.getAgent().getUserId()).findFirst().orElse(null))
            ? ticket.getCreateur()
            : ticket.getAffectations().stream()
                .filter(a -> Boolean.TRUE.equals(a.getResponsablePrincipal()))
                .map(AffectationTicket::getAgent).findFirst().orElse(null);

        // 🎯 5. Condition sur l'option "Notifications internes" pour les nouveaux messages du chat
        if (dest != null && !dest.getUserId().equals(auteurId)) {
            if (appSettingService.isInternalNotificationEnabled()) {
                notificationRepo.save(Notification.builder()
                    .message("Nouveau message sur le ticket #" + ticketId)
                    .categorie("TICKET").actionLabel("Voir").resourceId(ticketId.toString())
                    .utilisateur(dest).build());
            }
        }

        return ResponseEntity.ok(toDto(ticketRepo.findById(ticketId).orElseThrow()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        ticketRepo.deleteById(id);
        return ResponseEntity.ok(Map.of("message", "Ticket supprimé"));
    }

    // ── Mapping DTO ──────────────────────────────────────────────────
    private Map<String, Object> toDto(Ticket t) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", t.getId());
        m.put("description", t.getDescription());
        m.put("structure", t.getStructure() != null ? t.getStructure().getNom() : "");
        m.put("status", t.getStatut());
        m.put("priority", t.getPriorite());
        m.put("createdAt", t.getDateCreation());
        m.put("solution", t.getSolution());
        
        if (t.getCreateur() != null) m.put("createur", userMap(t.getCreateur()));
        
        t.getAffectations().stream()
            .filter(a -> Boolean.TRUE.equals(a.getResponsablePrincipal())).findFirst()
            .ifPresent(a -> m.put("agentAssigne", userMap(a.getAgent())));
            
        m.put("messages", communicationRepo.findByTicketIdOrderByDateAsc(t.getId())
            .stream().map(c -> Map.of(
                "auteurId", c.getAuteur().getUserId(),
                "auteurNom", c.getAuteur().getNom() + " " + (c.getAuteur().getPrenom() != null ? c.getAuteur().getPrenom() : ""),
                "auteurInitiales", c.getAuteur().getInitiales(),
                "message", c.getMessage(),
                "createdAt", c.getDate() != null ? c.getDate() : ""
            )).toList());
            
        t.getPiecesJointes().stream().findFirst()
            .ifPresent(pj -> m.put("attachmentUrl", "/uploads/" + pj.getChemin()));
        return m;
    }

    private Map<String, Object> userMap(Utilisateur u) {
        return Map.of(
            "id", u.getUserId(),
            "nom", u.getNom(),
            "prenom", u.getPrenom() != null ? u.getPrenom() : "",
            "email", u.getEmail(), 
            "initiales", u.getInitiales()
        );
    }

    private Map<String, Object> toPageResponse(Page<Ticket> page) {
        return Map.of(
            "content", page.getContent().stream().map(this::toDto).toList(),
            "totalElements", page.getTotalElements(),
            "totalPages", page.getTotalPages(),
            "number", page.getNumber()
        );
    }

    private Priorite parsePriorite(String s) {
        try { return Priorite.valueOf(s.toUpperCase()); }
        catch (Exception e) {
            return switch (s.toUpperCase()) {
                case "HAUTE", "ELEVEE" -> Priorite.ELEVEE;
                case "BASSE", "FAIBLE" -> Priorite.FAIBLE;
                default -> Priorite.MOYENNE;
            };
        }
    }
}