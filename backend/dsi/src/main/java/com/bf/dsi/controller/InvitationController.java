package com.bf.dsi.controller;

import com.bf.dsi.dto.InvitationRequest;
import com.bf.dsi.entity.*;
import com.bf.dsi.enums.*;
import org.springframework.transaction.annotation.Transactional;
import com.bf.dsi.repository.*;
import com.bf.dsi.services.FileStorageService;
import com.bf.dsi.services.PdfService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.*;
import com.bf.dsi.services.WordService;

@RestController
@RequestMapping("/api/invitations")
@RequiredArgsConstructor
@Transactional 
public class InvitationController {
    private final InvitationRepository invitationRepo;
    private final UtilisateurRepository utilisateurRepo;
    private final StructureRepository structureRepo;
    private final AffectationInvitationRepository affectationRepo;
    private final NotificationRepository notificationRepo;
    private final FileStorageService fileStorage;
    private final PdfService pdfService;
    private final WordService wordService;
  @GetMapping
public ResponseEntity<?> getAll(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String search,
        @RequestParam(required = false) String statut) {
    Page<Invitation> result = invitationRepo.findAllFiltered(
        search, statut,
        PageRequest.of(page, size)); // ← SANS Sort
    return ResponseEntity.ok(toPageResponse(result));
}

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return invitationRepo.findById(id)
            .map(inv -> ResponseEntity.ok(toDto(inv)))
            .orElse(ResponseEntity.notFound().build());
    }

    // ── Création via JSON (Flutter) ─────────────────────────────────
    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> createJson(@RequestBody InvitationRequest req) {
        Invitation inv = Invitation.builder()
            .objet(req.getObjet())
            .dateDebut(req.getDateDebut())
            .dateFin(req.getDateFin())
            .nombreParticipant(req.getNombreParticipants() != null ? req.getNombreParticipants() : 0)
            .visibilite(req.getVisibilite() != null ? req.getVisibilite() : "PUBLIC")
            .statut(StatutInvitation.EN_ATTENTE)
            .build();
        if (req.getStructureEmettriceId() != null)
            structureRepo.findById(req.getStructureEmettriceId()).ifPresent(inv::setStructureEmettrice);
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(invitationRepo.save(inv)));
    }

    // ── Création via multipart (avec fichiers) ─────────────────────
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> createMultipart(
            @RequestParam String objet,
            @RequestParam String dateDebut,
            @RequestParam String dateFin,
            @RequestParam(required = false, defaultValue = "0") int nombreParticipants,
            @RequestParam(required = false) String visibilite,
            @RequestParam(required = false) Long structureEmettriceId,
            @RequestParam(required = false) List<MultipartFile> files) {

        Invitation inv = Invitation.builder()
            .objet(objet)
            .dateDebut(java.time.LocalDate.parse(dateDebut))
            .dateFin(java.time.LocalDate.parse(dateFin))
            .nombreParticipant(nombreParticipants)
            .visibilite(visibilite != null ? visibilite : "PUBLIC")
            .statut(StatutInvitation.EN_ATTENTE)
            .build();

        if (structureEmettriceId != null)
            structureRepo.findById(structureEmettriceId).ifPresent(inv::setStructureEmettrice);

        Invitation saved = invitationRepo.save(inv);

        if (files != null) {
            for (MultipartFile file : files) {
                if (!file.isEmpty()) {
                    String path = fileStorage.store(file, "invitations/" + saved.getId());
                    PieceJointeInvitation pj = PieceJointeInvitation.builder()
                        .nom(file.getOriginalFilename()).type(file.getContentType())
                        .chemin(path).invitation(saved).build();
                    saved.getPiecesJointes().add(pj);
                }
            }
            invitationRepo.save(saved);
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(saved));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody InvitationRequest req) {
        return invitationRepo.findById(id).map(inv -> {
            if (req.getObjet() != null) inv.setObjet(req.getObjet());
            if (req.getDateDebut() != null) inv.setDateDebut(req.getDateDebut());
            if (req.getDateFin() != null) inv.setDateFin(req.getDateFin());
            if (req.getNombreParticipants() != null) inv.setNombreParticipant(req.getNombreParticipants());
            if (req.getVisibilite() != null) inv.setVisibilite(req.getVisibilite());
            if (req.getStatut() != null) {
                try { inv.setStatut(StatutInvitation.valueOf(req.getStatut())); } catch (Exception ignored) {}
            }
            if (req.getStructureEmettriceId() != null)
                structureRepo.findById(req.getStructureEmettriceId()).ifPresent(inv::setStructureEmettrice);
            return ResponseEntity.ok(toDto(invitationRepo.save(inv)));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}/statut")
    public ResponseEntity<?> changerStatut(@PathVariable Long id, @RequestBody Map<String, String> body) {
        return invitationRepo.findById(id).map(inv -> {
            try { inv.setStatut(StatutInvitation.valueOf(body.get("statut"))); } catch (Exception ignored) {}
            return ResponseEntity.ok(toDto(invitationRepo.save(inv)));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/{invId}/affecter/{agentId}")
    public ResponseEntity<?> affecterAgent(@PathVariable Long invId,
                                            @PathVariable Long agentId,
                                            @RequestParam(defaultValue = "false") boolean responsable) {
        Invitation inv = invitationRepo.findById(invId).orElseThrow();
        Utilisateur agent = utilisateurRepo.findById(agentId).orElseThrow();

        // Éviter les doublons
        boolean dejAffecte = inv.getAffectations().stream()
            .anyMatch(a -> a.getAgent().getUserId().equals(agentId));
        if (!dejAffecte) {
            AffectationInvitation aff = AffectationInvitation.builder()
                .invitation(inv).agent(agent).responsablePrincipal(responsable).build();
            affectationRepo.save(aff);
        }

        Notification notif = Notification.builder()
            .message("Vous avez été affecté à l'invitation : " + inv.getObjet())
            .categorie("INVITATION").actionLabel("Voir").resourceId(invId.toString())
            .utilisateur(agent).build();
        notificationRepo.save(notif);

        if (inv.getStatut() == StatutInvitation.EN_ATTENTE)
            inv.setStatut(StatutInvitation.PLANIFIEE);
        invitationRepo.save(inv);
        return ResponseEntity.ok(toDto(invitationRepo.findById(invId).orElseThrow()));
    }

    @GetMapping("/{id}/export/pdf")
    public ResponseEntity<byte[]> exportPdf(@PathVariable Long id) {
        Invitation inv = invitationRepo.findById(id).orElseThrow();
        byte[] pdf = pdfService.generateInvitationLetter(inv);
        return ResponseEntity.ok()
            .header("Content-Disposition", "attachment; filename=\"invitation_" + id + ".pdf\"")
            .contentType(MediaType.APPLICATION_PDF).body(pdf);
    }
    @GetMapping("/{id}/export/word")
public ResponseEntity<byte[]> exportWord(@PathVariable Long id) {
    // 1. Récupération de l'invitation depuis PostgreSQL
    Invitation inv = invitationRepo.findById(id)
            .orElseThrow(() -> new RuntimeException("Invitation introuvable avec l'ID : " + id));
    
    // 2. Appel de ton service pour générer les octets du fichier Word (.docx)
    // (Assure-toi d'avoir une méthode équivalente dans ton WordService)
    byte[] wordDocument = wordService.generateInvitationWord(inv); 
    
    // 3. Retour du fichier vers le navigateur (Flutter)
    return ResponseEntity.ok()
        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"invitation_" + id + ".docx\"")
        .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
        .body(wordDocument);
}

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        invitationRepo.deleteById(id);
        return ResponseEntity.ok(Map.of("message", "Invitation supprimée"));
    }

    // ── Structures invitées ─────────────────────────────────────────
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

    // ── Mapping ─────────────────────────────────────────────────────
   // ── Mapping avec calcul dynamique du statut ──────────────────────
    private Map<String, Object> toDto(Invitation i) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", i.getId());
        m.put("objet", i.getObjet());
        m.put("dateDebut", i.getDateDebut());
        m.put("dateFin", i.getDateFin());
        m.put("nombreParticipants", i.getNombreParticipant());

        // 🎯 ÉTAPE 1 : Détermination dynamique du statut selon tes règles métiers
        StatutInvitation statutCalcule = i.getStatut(); // Valeur de repli par défaut
        
        java.time.LocalDate aujourdhui = java.time.LocalDate.now();
        boolean aDesAgents = i.getAffectations() != null && !i.getAffectations().isEmpty();

        // Règle : Date de fin dépassée
        if (aujourdhui.isAfter(i.getDateFin())) {
            if (aDesAgents) {
                statutCalcule = StatutInvitation.TERMINEE;    // Agent(s) affecté(s) et date de fin dépassée
            } else {
                statutCalcule = StatutInvitation.NON_TRAITEE; // Aucun agent affecté et date de fin dépassée
            }
        } 
        // Règle : Période en cours [dateDebut <= aujourdhui <= dateFin]
        else if (!aujourdhui.isBefore(i.getDateDebut()) && !aujourdhui.isAfter(i.getDateFin())) {
            statutCalcule = StatutInvitation.EN_COURS;
        } 
        // Règle : Événement futur (avant la date de début)
        else if (aujourdhui.isBefore(i.getDateDebut())) {
            if (aDesAgents) {
                statutCalcule = StatutInvitation.PLANIFIEE;   // Au moins un agent affecté
            } else {
                statutCalcule = StatutInvitation.EN_ATTENTE;  // Aucun agent affecté
            }
        }

        // 🎯 ÉTAPE 2 : On envoie le statut calculé en temps réel à Flutter
        m.put("status", statutCalcule);

        m.put("visibilite", i.getVisibilite());
        m.put("dateCreation", i.getDateCreation());
        m.put("structureEmettrice", i.getStructureEmettrice() != null ? i.getStructureEmettrice().getNom() : "");
        m.put("agentsAffectes", i.getAffectations().stream().map(a -> Map.of(
            "id", a.getAgent().getUserId(),
            "nom", a.getAgent().getNom(),
            "prenom", a.getAgent().getPrenom() != null ? a.getAgent().getPrenom() : "",
            "email", a.getAgent().getEmail(),
            "initiales", a.getAgent().getInitiales(),
            "responsable", a.getResponsablePrincipal()
        )).toList());
        m.put("piecesJointes", i.getPiecesJointes().stream().map(pj -> Map.of(
            "id", pj.getId(), "nom", pj.getNom(),
            "type", pj.getType() != null ? pj.getType() : "",
            "url", "/uploads/" + pj.getChemin()
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
}