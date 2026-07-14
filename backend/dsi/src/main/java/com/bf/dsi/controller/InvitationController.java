package com.bf.dsi.controller;

import com.bf.dsi.dto.InvitationRequest;
import com.bf.dsi.entity.*;
import com.bf.dsi.enums.*;
import com.bf.dsi.repository.*;
import com.bf.dsi.services.FileStorageService;
import com.bf.dsi.services.InvitationService;
import com.bf.dsi.services.PdfService;
import com.bf.dsi.services.WordService;
import com.bf.dsi.services.AppSettingService;
import com.bf.dsi.services.EmailService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.time.LocalDate;
import java.util.*;

@RestController
@RequestMapping("/api/invitations")
@RequiredArgsConstructor
@Transactional
@Tag(name = "Invitations", description = "Gestion des invitations (création, lettre officielle, reçues / envoyées)")
public class InvitationController {

    private final InvitationRepository invitationRepo;
    private final StructureRepository structureRepo;
    private final StructureInviteeRepository structureInviteeRepo;
    private final FileStorageService fileStorage;
    private final PdfService pdfService;
    private final WordService wordService;
    private final InvitationService invitationService;
    private final UtilisateurRepository utilisateurRepo;
    private final NotificationRepository notificationRepo;
    private final AppSettingService appSettingService;
    private final EmailService emailService;

    @lombok.Data
    public static class AffectationRequest {
        private List<Long> agentIds;
        private Long responsableId;
    }

    // ════════════════════════════════════════════════════════════════
    // LISTES
    // ════════════════════════════════════════════════════════════════

    @Operation(summary = "Liste paginée de toutes les invitations (avec recherche/filtre statut)")
    @GetMapping
    public ResponseEntity<?> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String statut) {
        Page<Invitation> result = invitationRepo.findAllFiltered(search, statut, PageRequest.of(page, size));
        return ResponseEntity.ok(toPageResponse(result));
    }

    @Operation(summary = "Invitations affichées sur la page REÇU",
        description = "Retourne les invitations créées via le formulaire 'Créer' (lettre officielle, modeCreation = CREER).")
    @GetMapping("/recues")
    public ResponseEntity<?> getInvitationsRecues(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        Page<Invitation> result = invitationRepo.findByModeCreationOrderByIdDesc("CREER", PageRequest.of(page, size));
        return ResponseEntity.ok(toPageResponse(result));
    }

    @Operation(summary = "Invitations affichées sur la page ENVOYER",
        description = "Retourne les invitations créées via le formulaire rapide 'Enregistrer' (modeCreation = ENREGISTRER).")
    @GetMapping("/envoyees")
    public ResponseEntity<?> getInvitationsEnvoyees(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String statut) {
        Page<Invitation> result = invitationRepo.findByModeCreationOrderByIdDesc("ENREGISTRER", PageRequest.of(page, size));
        return ResponseEntity.ok(toPageResponse(result));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return invitationRepo.findById(id)
            .map(inv -> ResponseEntity.ok(toDto(inv)))
            .orElse(ResponseEntity.notFound().build());
    }

    // ════════════════════════════════════════════════════════════════
    // CRÉATION
    // ════════════════════════════════════════════════════════════════

    @Operation(summary = "Créer une invitation (JSON) — incluant la lettre officielle et les structures destinataires")
    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> createJson(@RequestBody InvitationRequest req) {
        Invitation inv = Invitation.builder()
            .objet(req.getObjet())
            .dateDebut(req.getDateDebut())
            .dateFin(req.getDateFin())
            .nombreParticipant(req.getNombreParticipants() != null ? req.getNombreParticipants() : 0)
            .visibilite(req.getVisibilite() != null ? req.getVisibilite() : "PUBLIC")
            .lieu(req.getLieu())
            .statut(StatutInvitation.EN_ATTENTE)
            .numeroReference(req.getNumeroReference())
            .ville(req.getVille() != null ? req.getVille() : "Ouagadougou")
            .contenu(req.getContenu())
            .contenuDelta(req.getContenuDelta())
            .ampliation(req.getAmpliation())
            .signataireNom(req.getSignataireNom())
            .signataireQualite(req.getSignataireQualite())
            .modeCreation(req.getModeCreation() != null && !req.getModeCreation().isBlank()
                ? req.getModeCreation() : "ENREGISTRER")
            .build();

        appliquerStructureEmettrice(inv, req.getStructureEmettriceId(), req.getStructureEmettrice());

        Invitation saved = invitationRepo.save(inv);
        appliquerStructuresInvitees(saved, req.getStructureIds());

        notifierInvitationEnregistree(saved);
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(saved));
    }

    @Operation(summary = "Créer une invitation (multipart) — avec pièces jointes et structures destinataires")
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> createMultipart(
            @RequestParam String objet,
            @RequestParam(required = false) String dateDebut,
            @RequestParam(required = false) String dateFin,
            @RequestParam(required = false, defaultValue = "0") int nombreParticipants,
            @RequestParam(required = false) String visibilite,
            @RequestParam(required = false) Long structureEmettriceId,
            @RequestParam(required = false) String nomStructure,
            @RequestParam(required = false) String lieu,
            @RequestParam(required = false) String numeroReference,
            @RequestParam(required = false) String ville,
            @RequestParam(required = false) String contenu,
            @RequestParam(required = false) String contenuDelta,
            @RequestParam(required = false) String ampliation,
            @RequestParam(required = false) String signataireNom,
            @RequestParam(required = false) String signataireQualite,
            @RequestParam(required = false, defaultValue = "ENREGISTRER") String modeCreation,
            @RequestParam(required = false) List<Long> structureIds,
            @RequestParam(required = false) List<MultipartFile> files) {

        LocalDate parsedDateDebut = null;
        if (dateDebut != null && !dateDebut.trim().isEmpty()) {
            parsedDateDebut = LocalDate.parse(dateDebut.trim());
        }

        LocalDate parsedDateFin = null;
        if (dateFin != null && !dateFin.trim().isEmpty()) {
            parsedDateFin = LocalDate.parse(dateFin.trim());
        }

        Invitation inv = Invitation.builder()
            .objet(objet)
            .dateDebut(parsedDateDebut)
            .dateFin(parsedDateFin)
            .nombreParticipant(nombreParticipants)
            .visibilite(visibilite != null ? visibilite : "PUBLIC")
            .lieu(lieu)
            .statut(StatutInvitation.EN_ATTENTE)
            .numeroReference(numeroReference)
            .ville(ville != null && !ville.trim().isEmpty() ? ville : "Ouagadougou")
            .contenu(contenu)
            .contenuDelta(contenuDelta)
            .ampliation(ampliation)
            .signataireNom(signataireNom)
            .signataireQualite(signataireQualite)
            .modeCreation(modeCreation != null && !modeCreation.isBlank() ? modeCreation : "ENREGISTRER")
            .build();

        if (structureEmettriceId != null) {
            structureRepo.findById(structureEmettriceId).ifPresent(inv::setStructureEmettrice);
        } else if (nomStructure != null && !nomStructure.trim().isEmpty()) {
            Structure structure = structureRepo.findByNom(nomStructure)
                .orElseGet(() -> {
                    Structure s = new Structure();
                    s.setNom(nomStructure);
                    return structureRepo.save(s);
                });
            inv.setStructureEmettrice(structure);
        }

        Invitation saved = invitationRepo.save(inv);

        appliquerStructuresInvitees(saved, structureIds);

        if (files != null) {
            for (MultipartFile file : files) {
                if (!file.isEmpty()) {
                    String path = fileStorage.store(file, "invitations/" + saved.getId());
                    PieceJointeInvitation pj = PieceJointeInvitation.builder()
                        .nom(file.getOriginalFilename())
                        .type(file.getContentType())
                        .chemin(path)
                        .invitation(saved)
                        .build();
                    saved.getPiecesJointes().add(pj);
                }
            }
            invitationRepo.save(saved);
        }
        notifierInvitationEnregistree(saved);
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(saved));
    }

    // ════════════════════════════════════════════════════════════════
    // MODIFICATION
    // ════════════════════════════════════════════════════════════════

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody InvitationRequest req) {
        return invitationRepo.findById(id).map(inv -> {
            if (req.getObjet() != null) inv.setObjet(req.getObjet());
            if (req.getDateDebut() != null) inv.setDateDebut(req.getDateDebut());
            if (req.getDateFin() != null) inv.setDateFin(req.getDateFin());
            if (req.getNombreParticipants() != null) inv.setNombreParticipant(req.getNombreParticipants());
            if (req.getVisibilite() != null) inv.setVisibilite(req.getVisibilite());
            if (req.getLieu() != null) inv.setLieu(req.getLieu());
            if (req.getNumeroReference() != null) inv.setNumeroReference(req.getNumeroReference());
            if (req.getVille() != null) inv.setVille(req.getVille());
            if (req.getContenu() != null) inv.setContenu(req.getContenu());
            if (req.getContenuDelta() != null) inv.setContenuDelta(req.getContenuDelta());
            if (req.getAmpliation() != null) inv.setAmpliation(req.getAmpliation());
            if (req.getSignataireNom() != null) inv.setSignataireNom(req.getSignataireNom());
            if (req.getSignataireQualite() != null) inv.setSignataireQualite(req.getSignataireQualite());

            if (req.getStatut() != null) {
                try { inv.setStatut(StatutInvitation.valueOf(req.getStatut())); } catch (Exception ignored) {}
            }

            if (req.getStructureEmettriceId() != null || (req.getStructureEmettrice() != null && !req.getStructureEmettrice().trim().isEmpty())) {
                appliquerStructureEmettrice(inv, req.getStructureEmettriceId(), req.getStructureEmettrice());
            }

            Invitation saved = invitationRepo.save(inv);

            if (req.getStructureIds() != null) {
                appliquerStructuresInvitees(saved, req.getStructureIds());
            }

            return ResponseEntity.ok(toDto(saved));
        }).orElse(ResponseEntity.notFound().build());
    }

    // 🎯 Ajoute une ou plusieurs pièces jointes à une invitation déjà existante
    // (utilisé par l'écran "Modifier l'invitation") — vient compléter les pièces
    // jointes déjà présentes, qu'il y en ait zéro ou plusieurs.
    @PostMapping("/{id}/attachments")
    public ResponseEntity<?> ajouterPiecesJointes(
            @PathVariable Long id,
            @RequestParam(required = false) List<MultipartFile> files) {
        return invitationRepo.findById(id).map(inv -> {
            if (files != null) {
                for (MultipartFile file : files) {
                    if (!file.isEmpty()) {
                        String path = fileStorage.store(file, "invitations/" + inv.getId());
                        PieceJointeInvitation pj = PieceJointeInvitation.builder()
                            .nom(file.getOriginalFilename())
                            .type(file.getContentType())
                            .chemin(path)
                            .invitation(inv)
                            .build();
                        inv.getPiecesJointes().add(pj);
                    }
                }
                invitationRepo.save(inv);
            }
            return ResponseEntity.ok(toDto(inv));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}/statut")
    public ResponseEntity<?> changerStatut(@PathVariable Long id, @RequestBody Map<String, String> body) {
        return invitationRepo.findById(id).map(inv -> {
            try { inv.setStatut(StatutInvitation.valueOf(body.get("statut"))); } catch (Exception ignored) {}
            return ResponseEntity.ok(toDto(invitationRepo.save(inv)));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/{invId}/affecter")
    public ResponseEntity<?> affecterMembres(
            @PathVariable Long invId,
            @RequestBody AffectationRequest req,
            Authentication authentication) {

        // 🎯 Affectation réservée à ADMIN et SECRETAIRE — un agent n'a pas le
        // droit d'affecter (ni lui-même ni un collègue) une invitation.
        Utilisateur demandeur = currentUser(authentication);
        boolean autorise = demandeur != null && demandeur.getRoles().stream()
                .anyMatch(r -> "ADMIN".equals(r.getNom()) || "SECRETAIRE".equals(r.getNom()));
        if (!autorise) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("message", "Seuls un administrateur ou un secrétaire peuvent affecter un agent."));
        }

        Invitation invMiseAJour = invitationService.affecterMembres(invId, req.getAgentIds(), req.getResponsableId());
        return ResponseEntity.ok(toDto(invMiseAJour));
    }

    @Operation(summary = "Générer/télécharger la lettre d'invitation au format PDF")
    @GetMapping("/{id}/export/pdf")
    public ResponseEntity<byte[]> exportPdf(@PathVariable Long id) {
        Invitation inv = invitationRepo.findById(id).orElseThrow();
        byte[] pdf = pdfService.generateInvitationLetter(inv);
        return ResponseEntity.ok().header("Content-Disposition", "attachment; filename=\"invitation_" + id + ".pdf\"").contentType(MediaType.APPLICATION_PDF).body(pdf);
    }

    @Operation(summary = "Générer/télécharger la lettre d'invitation au format Word")
    @GetMapping("/{id}/export/word")
    public ResponseEntity<byte[]> exportWord(@PathVariable Long id) {
        Invitation inv = invitationRepo.findById(id).orElseThrow();
        byte[] wordDocument = wordService.generateInvitationWord(inv);
        return ResponseEntity.ok().header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"invitation_" + id + ".docx\"").contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document")).body(wordDocument);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        // 🎯 On purge d'abord les notifications liées à cette invitation
        // (catégorie "INVITATION", resourceId = id), sinon elles restent
        // "fantômes" dans les Alertes et pointent vers une ressource qui
        // n'existe plus. @Transactional est déjà présent au niveau classe.
        notificationRepo.deleteByCategorieAndResourceId("INVITATION", id.toString());
        invitationRepo.deleteById(id);
        return ResponseEntity.ok(Map.of("message", "Invitation supprimée"));
    }

    @GetMapping("/{id}/structures-invitees")
    public ResponseEntity<?> getStructuresInvitees(@PathVariable Long id) {
        Invitation inv = invitationRepo.findById(id).orElseThrow();
        return ResponseEntity.ok(inv.getStructuresInvitees().stream().map(si -> Map.of(
            "id", si.getId(),
            "structure", Map.of("id", si.getStructure().getId(), "nom", si.getStructure().getNom()),
            "statutReponse", si.getStatutReponse(),
            "lettreGeneree", si.getLettreGeneree()
        )).toList());
    }

    @Operation(summary = "Ajouter une structure destinataire à une invitation (CRUD structure_invitee)")
    @PostMapping("/{id}/structures-invitees")
    public ResponseEntity<?> ajouterStructureInvitee(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Invitation inv = invitationRepo.findById(id).orElseThrow();
        Long structureId = body.get("structureId") != null ? Long.valueOf(body.get("structureId").toString()) : null;
        if (structureId == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "structureId requis"));
        }
        boolean dejaLiee = structureInviteeRepo.findByInvitationId(id).stream()
            .anyMatch(si -> si.getStructure() != null && structureId.equals(si.getStructure().getId()));
        if (dejaLiee) {
            return ResponseEntity.badRequest().body(Map.of("message", "Cette structure est déjà destinataire de cette invitation"));
        }
        Structure structure = structureRepo.findById(structureId).orElseThrow();
        StructureInvitee si = StructureInvitee.builder()
            .invitation(inv)
            .structure(structure)
            .statutReponse(StatutReponse.EN_ATTENTE)
            .build();
        structureInviteeRepo.save(si);
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(invitationRepo.findById(id).orElseThrow()));
    }

    @Operation(summary = "Modifier le statut de réponse d'une structure destinataire (CRUD structure_invitee)")
    @PutMapping("/structures-invitees/{structureInviteeId}")
    public ResponseEntity<?> modifierStructureInvitee(@PathVariable Long structureInviteeId, @RequestBody Map<String, String> body) {
        StructureInvitee si = structureInviteeRepo.findById(structureInviteeId).orElseThrow();
        if (body.get("statutReponse") != null) {
            try { si.setStatutReponse(StatutReponse.valueOf(body.get("statutReponse"))); } catch (Exception ignored) {}
        }
        structureInviteeRepo.save(si);
        return ResponseEntity.ok(toDto(invitationRepo.findById(si.getInvitation().getId()).orElseThrow()));
    }

    @Operation(summary = "Retirer une structure destinataire d'une invitation (CRUD structure_invitee)")
    @DeleteMapping("/structures-invitees/{structureInviteeId}")
    public ResponseEntity<?> supprimerStructureInvitee(@PathVariable Long structureInviteeId) {
        StructureInvitee si = structureInviteeRepo.findById(structureInviteeId).orElseThrow();
        Long invId = si.getInvitation().getId();
        structureInviteeRepo.deleteById(structureInviteeId);

        // 🎯 Le DELETE s'exécute bien en base, MAIS l'entité Invitation déjà
        // chargée dans la session JPA garde en mémoire son ancienne collection
        // structuresInvitees (chargée avant la suppression). Sans ce retrait
        // manuel, le JSON renvoyé au frontend montrait encore la structure
        // "retirée" malgré une suppression réussie en base — exactement le
        // symptôme observé ("Retirer ne marche pas").
        Invitation inv = invitationRepo.findById(invId).orElseThrow();
        inv.getStructuresInvitees().removeIf(s -> s.getId().equals(structureInviteeId));

        return ResponseEntity.ok(toDto(inv));
    }

    // ════════════════════════════════════════════════════════════════
    // OUTILS PRIVÉS
    // ════════════════════════════════════════════════════════════════

    /** Résout l'utilisateur authentifié (par email du token JWT). */
    private Utilisateur currentUser(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) return null;
        return utilisateurRepo.findByEmail(authentication.getName()).orElse(null);
    }

    private void appliquerStructureEmettrice(Invitation inv, Long structureEmettriceId, String structureEmettriceNom) {
        if (structureEmettriceId != null) {
            structureRepo.findById(structureEmettriceId).ifPresent(inv::setStructureEmettrice);
        } else if (structureEmettriceNom != null && !structureEmettriceNom.trim().isEmpty()) {
            structureRepo.findByNom(structureEmettriceNom).ifPresent(inv::setStructureEmettrice);
        }
    }

    /** Remplace la liste des structures invitées (destinataires) de l'invitation. */
    private void appliquerStructuresInvitees(Invitation inv, List<Long> structureIds) {
        if (structureIds == null) return;

        // On supprime les anciennes associations avant de reconstruire la liste
        List<StructureInvitee> anciennes = structureInviteeRepo.findByInvitationId(inv.getId());
        if (!anciennes.isEmpty()) {
            structureInviteeRepo.deleteAll(anciennes);
        }

        for (Long structureId : structureIds) {
            structureRepo.findById(structureId).ifPresent(structure -> {
                StructureInvitee si = StructureInvitee.builder()
                    .invitation(inv)
                    .structure(structure)
                    .statutReponse(StatutReponse.EN_ATTENTE)
                    .build();
                structureInviteeRepo.save(si);
            });
        }
    }

    /** Notifie les ADMIN et AGENT_DSI quand une invitation est enregistrée (mode rapide ENREGISTRER). */
    private void notifierInvitationEnregistree(Invitation inv) {
        if (!"ENREGISTRER".equalsIgnoreCase(inv.getModeCreation())) return;

        boolean interneOn = appSettingService.isInternalNotificationEnabled();
        boolean emailOn   = appSettingService.isEmailNotificationEnabled();
        if (!interneOn && !emailOn) return;

        // Notification interne (cloche) : ADMIN uniquement (pas les agents,
        // qui n'ont pas à être notifiés d'une invitation tant qu'ils n'y
        // sont pas affectés).
        Map<Long, Utilisateur> destinatairesInterne = new LinkedHashMap<>();
        utilisateurRepo.findByRoles_Nom("ADMIN").forEach(u -> destinatairesInterne.put(u.getUserId(), u));

        // Email : ADMIN + SECRETAIRE, cohérent avec le comportement des tickets.
        Map<Long, Utilisateur> destinatairesEmail = new LinkedHashMap<>();
        utilisateurRepo.findByRoles_Nom("ADMIN").forEach(u -> destinatairesEmail.put(u.getUserId(), u));
        utilisateurRepo.findByRoles_Nom("SECRETAIRE").forEach(u -> destinatairesEmail.put(u.getUserId(), u));

        if (interneOn) {
            destinatairesInterne.values().forEach(u -> notificationRepo.save(Notification.builder()
                .message("Nouvelle invitation enregistrée : " + inv.getObjet())
                .categorie("INVITATION").actionLabel("Voir").resourceId(inv.getId().toString())
                .utilisateur(u).build()));
        }

        if (emailOn) {
            destinatairesEmail.values().forEach(u -> {
                if (u.getEmail() != null) {
                    emailService.envoyerNotification(
                        u.getEmail(),
                        "DSI Connect — Nouvelle invitation",
                        "Une nouvelle invitation a été enregistrée : " + inv.getObjet()
                            + "\n\nConnectez-vous à DSI Connect pour la consulter."
                    );
                }
            });
        }
    }

    private Map<String, Object> toDto(Invitation i) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", i.getId());
        m.put("objet", i.getObjet());
        m.put("lieu", i.getLieu() != null ? i.getLieu() : "Non précisé");
        m.put("dateDebut", i.getDateDebut());
        m.put("dateFin", i.getDateFin());
        m.put("nombreParticipants", i.getNombreParticipant());
        m.put("status", i.calculerStatutAutomatique() != null ? i.calculerStatutAutomatique().name() : "EN_ATTENTE");
        m.put("visibilite", i.getVisibilite());
        m.put("modeCreation", i.getModeCreation());
        m.put("dateCreation", i.getDateCreation());

        m.put("numeroReference", i.getNumeroReference());
        m.put("ville", i.getVille());
        m.put("contenu", i.getContenu());
        m.put("contenuDelta", i.getContenuDelta());
        m.put("ampliation", i.getAmpliation());
        m.put("signataireNom", i.getSignataireNom());
        m.put("signataireQualite", i.getSignataireQualite());

        m.put("structureEmettriceId", i.getStructureEmettrice() != null ? i.getStructureEmettrice().getId() : null);
        m.put("structureEmettrice", (i.getStructureEmettrice() != null && i.getStructureEmettrice().getNom() != null)
                                     ? i.getStructureEmettrice().getNom()
                                     : "Non spécifiée");

        m.put("structuresInvitees", i.getStructuresInvitees().stream().map(si -> Map.of(
            "structureInviteeId", si.getId(),
            "id", si.getStructure().getId(),
            "nom", si.getStructure().getNom(),
            "statutReponse", si.getStatutReponse() != null ? si.getStatutReponse().name() : "EN_ATTENTE"
        )).toList());

        m.put("agentsAffectes", i.getAffectations().stream().map(a -> Map.of(
            "id", a.getAgent().getUserId(),
            "nom", a.getAgent().getNom(),
            "prenom", a.getAgent().getPrenom() != null ? a.getAgent().getPrenom() : "",
            "email", a.getAgent().getEmail(),
            "initiales", a.getAgent().getInitiales(),
            "responsable", a.getResponsablePrincipal()
        )).toList());

        m.put("piecesJointes", i.getPiecesJointes().stream().map(pj -> Map.of(
            "id", pj.getId(),
            "nom", pj.getNom(),
            "type", pj.getType() != null ? pj.getType() : "",
            "url", pj.getChemin() != null && pj.getChemin().startsWith("/") ? pj.getChemin() : "/" + (pj.getChemin() != null ? pj.getChemin() : "")
        )).toList());

        return m;
    }

    private Map<String, Object> toPageResponse(Page<Invitation> page) {
        return Map.of(
            "content", page.getContent().stream().map(this::toDto).toList(),
            "totalElements", page.getTotalElements(),
            "totalPages", page.getTotalPages(),
            "number", page.getNumber()
        );
    }

    private Map<String, Object> toListResponse(List<Invitation> liste) {
        return Map.of(
            "content", liste.stream().map(this::toDto).toList(),
            "totalElements", liste.size(),
            "totalPages", 1,
            "number", 0
        );
    }
}