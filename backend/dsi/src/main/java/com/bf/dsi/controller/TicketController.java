package com.bf.dsi.controller;

import com.bf.dsi.dto.TicketRequest;
import com.bf.dsi.dto.MessageRequest;
import com.bf.dsi.entity.*;
import com.bf.dsi.enums.*;
import com.bf.dsi.repository.*;
import com.bf.dsi.services.FileStorageService;
import com.bf.dsi.services.TicketService;
import com.bf.dsi.services.AppSettingService; // 🎯 1. Importation de ton nouveau service de configuration
import com.bf.dsi.services.EmailService;
import com.bf.dsi.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.transaction.annotation.Transactional;
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
    private final EmailService emailService;
    private final JwtUtil jwtUtil;

    @GetMapping
    public ResponseEntity<?> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String statut,
            @RequestParam(required = false) String priorite) {
            
        StatutTicket statutEnum = (statut != null && !statut.trim().isEmpty()) ? StatutTicket.valueOf(statut.toUpperCase()) : null;
        Priorite prioriteEnum = (priorite != null && !priorite.trim().isEmpty()) ? parsePriorite(priorite) : null;

        // 🎯 Un USAGER voit désormais TOUS les tickets (les siens + ceux des
        // autres), au même titre que les autres rôles — il ne peut simplement
        // pas les affecter ni changer leur statut (restrictions déjà en place
        // plus bas et dans SecurityConfig).
        Long createurId = null;

        Page<Ticket> result = ticketRepo.findAllFiltered(
            search, statutEnum, prioriteEnum, createurId,
            PageRequest.of(page, size)
        );
        return ResponseEntity.ok(toPageResponse(result));
    }

    private Utilisateur utilisateurConnecte(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) return null;
        try {
            String email = jwtUtil.extractEmail(authHeader.replace("Bearer ", ""));
            return utilisateurRepo.findByEmail(email).orElse(null);
        } catch (Exception e) { return null; }
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

        Ticket saved = ticketRepo.save(ticket);
        notifierNouveauTicket(saved);
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(saved));
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> createMultipart(
            @RequestParam String description,
            @RequestParam(required = false) String structure,
            @RequestParam(defaultValue = "MOYENNE") String priority,
            @RequestParam(required = false) List<MultipartFile> file,
            @RequestParam(required = false) Long createurId,
            @RequestParam(required = false) String whatsapp) {

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

        if (whatsapp != null && !whatsapp.isBlank())
            ticket.setWhatsapp(whatsapp);

        Ticket saved = ticketRepo.save(ticket);

        // Enregistrement de TOUTES les pièces jointes
        if (file != null) {
            for (MultipartFile f : file) {
                if (f != null && !f.isEmpty()) {
                    String path = fileStorage.store(f, "tickets/" + saved.getId());
                    PieceJointeTicket pj = PieceJointeTicket.builder()
                            .nom(f.getOriginalFilename()).type(f.getContentType())
                            .chemin(path).ticket(saved).build();
                    saved.getPiecesJointes().add(pj);
                }
            }
            ticketRepo.save(saved);
        }
        notifierNouveauTicket(saved);
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(saved));
    }

    // 🎯 Modification d'un ticket : réservée à son créateur (ex: USAGER qui
    // veut corriger une erreur — description ou image envoyée par erreur)
    // ou à un ADMIN. Permet de changer la description/priorité/whatsapp,
    // de retirer d'anciennes pièces jointes et d'en ajouter de nouvelles.
    @PutMapping(value = "/{id}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> modifier(
            @PathVariable Long id,
            @RequestParam(required = false) String description,
            @RequestParam(required = false) String priority,
            @RequestParam(required = false) String whatsapp,
            @RequestParam(required = false) List<MultipartFile> file,
            @RequestParam(required = false) List<Long> removeAttachmentIds,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {

        Ticket ticket = ticketRepo.findById(id).orElse(null);
        if (ticket == null) return ResponseEntity.notFound().build();

        Utilisateur connecte = utilisateurConnecte(authHeader);
        boolean estCreateur = connecte != null && ticket.getCreateur() != null
                && connecte.getUserId().equals(ticket.getCreateur().getUserId());
        boolean estAdmin = connecte != null && connecte.getRoles().stream()
                .anyMatch(r -> "ADMIN".equals(r.getNom()));
        if (!estCreateur && !estAdmin) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("message", "Seul le créateur du ticket (ou un admin) peut le modifier."));
        }

        if (description != null && !description.isBlank()) ticket.setDescription(description);
        if (priority != null && !priority.isBlank()) ticket.setPriorite(parsePriorite(priority));
        if (whatsapp != null) ticket.setWhatsapp(whatsapp.isBlank() ? null : whatsapp);

        // Retrait des pièces jointes demandées (ex: image envoyée par erreur)
        if (removeAttachmentIds != null && !removeAttachmentIds.isEmpty()) {
            ticket.getPiecesJointes().removeIf(pj -> removeAttachmentIds.contains(pj.getId()));
        }

        // Ajout des nouvelles pièces jointes
        if (file != null) {
            for (MultipartFile f : file) {
                if (f != null && !f.isEmpty()) {
                    String path = fileStorage.store(f, "tickets/" + ticket.getId());
                    PieceJointeTicket pj = PieceJointeTicket.builder()
                            .nom(f.getOriginalFilename()).type(f.getContentType())
                            .chemin(path).ticket(ticket).build();
                    ticket.getPiecesJointes().add(pj);
                }
            }
        }

        Ticket saved = ticketRepo.save(ticket);
        return ResponseEntity.ok(toDto(saved));
    }

    @PutMapping("/{id}/statut")
    public ResponseEntity<?> changerStatut(@PathVariable Long id, @RequestBody Map<String, String> body,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        try {
            // 🎯 Seul l'agent affecté à CE ticket peut changer son statut — un
            // autre AGENT_DSI, même habilité par son rôle en général, n'y est
            // pas autorisé. ADMIN et SUPERVISEUR passent outre cette restriction
            // (supervision globale).
            Ticket cible = ticketRepo.findById(id).orElseThrow();
            Utilisateur demandeur = utilisateurConnecte(authHeader);
            if (demandeur != null) {
                UserRole role = demandeur.getPrimaryRole();
                boolean superviseurOuAdmin = role == UserRole.ADMIN || role == UserRole.SUPERVISEUR;
                boolean estAgentAffecte = cible.getAffectations() != null && cible.getAffectations().stream()
                    .anyMatch(a -> a.getAgent() != null && a.getAgent().getUserId().equals(demandeur.getUserId()));
                if (!superviseurOuAdmin && !estAgentAffecte) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("error", "Seul l'agent affecté à ce ticket peut changer son statut"));
                }
            }

            StatutTicket nouveauStatut = StatutTicket.valueOf(body.get("statut"));
            String solution = body.get("solution");
            
            Ticket saved = ticketService.modifierStatut(id, nouveauStatut, solution);
            
            // 🎯 Le créateur doit être notifié à CHAQUE changement de statut de
            // son ticket (pas seulement quand il passe à RESOLU).
            if (saved.getCreateur() != null) {
                String libelleStatut = switch (saved.getStatut()) {
                    case EN_ATTENTE -> "est en attente";
                    case EN_COURS   -> "est en cours de traitement";
                    case EN_PAUSE   -> "a été mis en pause";
                    case RESOLU     -> "a été résolu";
                    case FERME      -> "a été fermé";
                };
                String message = "Votre ticket #" + id + " " + libelleStatut + ".";

                if (appSettingService.isInternalNotificationEnabled()) {
                    notificationRepo.save(Notification.builder()
                        .message(message)
                        .categorie("TICKET").actionLabel("Voir").resourceId(id.toString())
                        .utilisateur(saved.getCreateur()).build());
                }

                if (appSettingService.isEmailNotificationEnabled() && saved.getCreateur().getEmail() != null) {
                    emailService.envoyerNotification(
                        saved.getCreateur().getEmail(),
                        "DSI Connect — Mise à jour de votre ticket",
                        message + "\n\nConnectez-vous à DSI Connect pour plus de détails."
                    );
                }
            }
            return ResponseEntity.ok(toDto(saved));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Statut ou traitement invalide"));
        }
    }

    @PostMapping("/{ticketId}/affecter/{agentId}")
    public ResponseEntity<?> affecterAgent(
            @PathVariable Long ticketId,
            @PathVariable Long agentId,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {

        // 🎯 Affectation réservée à ADMIN et SECRETAIRE — un agent n'a pas le
        // droit d'affecter (ni lui-même ni un collègue) un ticket. Sans ce
        // contrôle, l'endpoint était appelable par n'importe qui.
        Utilisateur demandeur = utilisateurConnecte(authHeader);
        boolean autorise = demandeur != null && demandeur.getRoles().stream()
                .anyMatch(r -> "ADMIN".equals(r.getNom()) || "SECRETAIRE".equals(r.getNom()));
        if (!autorise) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("message", "Seuls un administrateur ou un secrétaire peuvent affecter un agent."));
        }

        Ticket ticket = ticketService.affecterAgent(ticketId, agentId);

        Utilisateur agent = utilisateurRepo.findById(agentId).orElseThrow();
        
        // 🎯 4. Condition sur l'option "Notifications internes" lors de l'affectation
        if (appSettingService.isInternalNotificationEnabled()) {
            notificationRepo.save(Notification.builder()
                .message("Vous avez été affecté au ticket #" + ticketId)
                .categorie("TICKET").actionLabel("Voir").resourceId(ticketId.toString())
                .utilisateur(agent).build());
        }

        if (appSettingService.isEmailNotificationEnabled() && agent.getEmail() != null) {
            emailService.envoyerNotification(
                agent.getEmail(),
                "DSI Connect — Nouvelle affectation de ticket",
                "Vous avez été affecté au ticket #" + ticketId + ".\n\nConnectez-vous à DSI Connect pour plus de détails."
            );
        }

        // 🎯 Le créateur du ticket doit aussi être notifié que son ticket a
        // été pris en charge par un agent (pas seulement l'agent lui-même).
        Utilisateur createur = ticket.getCreateur();
        if (createur != null && !createur.getUserId().equals(agent.getUserId())) {
            if (appSettingService.isInternalNotificationEnabled()) {
                notificationRepo.save(Notification.builder()
                    .message("Votre ticket #" + ticketId + " a été affecté à un agent")
                    .categorie("TICKET").actionLabel("Voir").resourceId(ticketId.toString())
                    .utilisateur(createur).build());
            }
            if (appSettingService.isEmailNotificationEnabled() && createur.getEmail() != null) {
                emailService.envoyerNotification(
                    createur.getEmail(),
                    "DSI Connect — Votre ticket a été affecté",
                    "Votre ticket #" + ticketId + " a été affecté à un agent et va être traité.\n\nConnectez-vous à DSI Connect pour plus de détails."
                );
            }
        }

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
            if (appSettingService.isEmailNotificationEnabled() && dest.getEmail() != null) {
                emailService.envoyerNotification(
                    dest.getEmail(),
                    "DSI Connect — Nouveau message",
                    "Vous avez reçu un nouveau message sur le ticket #" + ticketId + ".\n\nConnectez-vous à DSI Connect pour le consulter."
                );
            }
        }

        return ResponseEntity.ok(toDto(ticketRepo.findById(ticketId).orElseThrow()));
    }

    // 🎯 @Transactional est OBLIGATOIRE ici : deleteByCategorieAndResourceId
    // est une requête de suppression personnalisée (pas deleteById), et
    // Hibernate refuse de faire un "remove" en dehors d'une transaction
    // explicite (TransactionRequiredException sinon).
    @Transactional
    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(
            @PathVariable Long id,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {

        Ticket ticket = ticketRepo.findById(id).orElse(null);
        if (ticket == null) return ResponseEntity.notFound().build();

        // 🎯 Suppression autorisée pour : ADMIN, l'agent affecté à CE ticket
        // précis (pas n'importe quel agent), ou le créateur (usager) de son
        // propre ticket. Un SECRETAIRE ou un agent non affecté ne peut pas.
        Utilisateur demandeur = utilisateurConnecte(authHeader);
        boolean estAdmin = demandeur != null && demandeur.getRoles().stream()
                .anyMatch(r -> "ADMIN".equals(r.getNom()));
        Utilisateur agentAffecte = ticket.getAffectations().stream()
                .filter(a -> Boolean.TRUE.equals(a.getResponsablePrincipal()))
                .map(AffectationTicket::getAgent).findFirst().orElse(null);
        boolean estAgentAffecte = demandeur != null && agentAffecte != null
                && demandeur.getUserId().equals(agentAffecte.getUserId());
        boolean estCreateur = demandeur != null && ticket.getCreateur() != null
                && demandeur.getUserId().equals(ticket.getCreateur().getUserId());
        if (!estAdmin && !estAgentAffecte && !estCreateur) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("message", "Vous n'avez pas le droit de supprimer ce ticket."));
        }

        // 🎯 On purge d'abord les notifications liées à ce ticket (catégorie
        // "TICKET", resourceId = id du ticket), sinon elles restent "fantômes"
        // en base et pointent vers une ressource qui n'existe plus.
        notificationRepo.deleteByCategorieAndResourceId("TICKET", id.toString());
        ticketRepo.deleteById(id);
        return ResponseEntity.ok(Map.of("message", "Ticket supprimé"));
    }

    // ── Notifications ────────────────────────────────────────────────

    /** Notifie les ADMIN et AGENT_DSI dès qu'un nouveau ticket est créé. */
    private void notifierNouveauTicket(Ticket ticket) {
        boolean interneOn = appSettingService.isInternalNotificationEnabled();
        boolean emailOn   = appSettingService.isEmailNotificationEnabled();
        if (!interneOn && !emailOn) return;

        // Notification interne (cloche) : ADMIN + AGENT_DSI, pour qu'ils voient
        // le nouveau ticket et puissent s'en occuper.
        Map<Long, Utilisateur> destinatairesInterne = new LinkedHashMap<>();
        utilisateurRepo.findByRoles_Nom("ADMIN").forEach(u -> destinatairesInterne.put(u.getUserId(), u));
        utilisateurRepo.findByRoles_Nom("AGENT_DSI").forEach(u -> destinatairesInterne.put(u.getUserId(), u));

        // Email : uniquement ADMIN + SECRETAIRE.
        Map<Long, Utilisateur> destinatairesEmail = new LinkedHashMap<>();
        utilisateurRepo.findByRoles_Nom("ADMIN").forEach(u -> destinatairesEmail.put(u.getUserId(), u));
        utilisateurRepo.findByRoles_Nom("SECRETAIRE").forEach(u -> destinatairesEmail.put(u.getUserId(), u));

        String desc = ticket.getDescription();
        String resume = (desc != null && desc.length() > 60) ? desc.substring(0, 60) + "…" : desc;

        if (interneOn) {
            destinatairesInterne.values().forEach(u -> notificationRepo.save(Notification.builder()
                .message("🆕 Nouveau ticket créé : " + resume)
                .categorie("TICKET").actionLabel("Voir").resourceId(ticket.getId().toString())
                .utilisateur(u).build()));
        }

        if (emailOn) {
            destinatairesEmail.values().forEach(u -> {
                if (u.getEmail() != null) {
                    emailService.envoyerNotification(
                        u.getEmail(),
                        "DSI Connect — Nouveau ticket",
                        "Un nouveau ticket a été créé : " + resume + "\n\nConnectez-vous à DSI Connect pour le consulter."
                    );
                }
            });
        }
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
        if (t.getWhatsapp() != null) m.put("whatsapp", t.getWhatsapp());
        
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
            
             // Toutes les PJ avec URL relative (le frontend préfixe avec la bonne
             // base URL selon la plateforme : web/émulateur/téléphone physique).
             // ⚠️ Ne JAMAIS coder "http://localhost:8085" en dur ici : ça casse
             // l'affichage sur tout appareil qui n'est pas la machine du serveur.
        List<Map<String, String>> pjs = t.getPiecesJointes().stream()
            .map(pj -> Map.of("id", pj.getId().toString(), "url", "/uploads/" + pj.getChemin(), "nom", pj.getChemin()))
            .collect(java.util.stream.Collectors.toList());
        if (!pjs.isEmpty()) {
            m.put("attachments", pjs);
            m.put("attachmentUrl", pjs.get(0).get("url"));
        }
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