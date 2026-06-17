package com.bf.dsi.controller;

import com.bf.dsi.dto.InvitationRequest;
import com.bf.dsi.entity.*;
import com.bf.dsi.enums.*;
import com.bf.dsi.repository.*;
import com.bf.dsi.services.FileStorageService;
import com.bf.dsi.services.InvitationService;
import com.bf.dsi.services.PdfService;
import com.bf.dsi.services.WordService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.time.LocalDate;
import java.util.*;

@RestController
@RequestMapping("/api/invitations")
@RequiredArgsConstructor
@Transactional 
public class InvitationController {

    private final InvitationRepository invitationRepo;
    private final StructureRepository structureRepo;
    private final FileStorageService fileStorage;
    private final PdfService pdfService;
    private final WordService wordService;
    private final InvitationService invitationService;
    private final UtilisateurRepository utilisateurRepo;

    @lombok.Data
    public static class AffectationRequest {
        private List<Long> agentIds;
        private Long responsableId;
    }

    @GetMapping
    public ResponseEntity<?> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String statut) {
        Page<Invitation> result = invitationRepo.findAllFiltered(search, statut, PageRequest.of(page, size));
        return ResponseEntity.ok(toPageResponse(result));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return invitationRepo.findById(id)
            .map(inv -> ResponseEntity.ok(toDto(inv)))
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> createJson(@RequestBody InvitationRequest req) {
        Invitation inv = Invitation.builder()
            .objet(req.getObjet())
            .dateDebut(req.getDateDebut())
            .dateFin(req.getDateFin())
            .nombreParticipant(req.getNombreParticipants() != null ? req.getNombreParticipants() : 0)
            .visibilite(req.getVisibilite() != null ? req.getVisibilite() : "PUBLIC")
            .lieu(req.getLieu()) // Ajout du lieu si présent dans le JSON
            .statut(StatutInvitation.EN_ATTENTE)
            .build();
            
        // Alignement avec le champ String du DTO
        if (req.getStructureEmettrice() != null && !req.getStructureEmettrice().trim().isEmpty()) {
            structureRepo.findByNom(req.getStructureEmettrice()).ifPresent(inv::setStructureEmettrice);
        }
            
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(invitationRepo.save(inv)));
    }

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
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(saved));
    }

    // ════════════════════════════════════════════════════════════════════
    // MÉTHODE DE MODIFICATION REVOUE ET ALIGNÉE
    // ════════════════════════════════════════════════════════════════════
    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody InvitationRequest req) {
        return invitationRepo.findById(id).map(inv -> {
            if (req.getObjet() != null) inv.setObjet(req.getObjet());
            if (req.getDateDebut() != null) inv.setDateDebut(req.getDateDebut());
            if (req.getDateFin() != null) inv.setDateFin(req.getDateFin());
            if (req.getNombreParticipants() != null) inv.setNombreParticipant(req.getNombreParticipants());
            if (req.getVisibilite() != null) inv.setVisibilite(req.getVisibilite());
            if (req.getLieu() != null) inv.setLieu(req.getLieu());
            
            if (req.getStatut() != null) {
                try { inv.setStatut(StatutInvitation.valueOf(req.getStatut())); } catch (Exception ignored) {}
            }
            
            // Récupère et associe l'entité Structure sur la base du nom textuel reçu du DTO
            if (req.getStructureEmettrice() != null && !req.getStructureEmettrice().trim().isEmpty()) {
                structureRepo.findByNom(req.getStructureEmettrice()).ifPresent(inv::setStructureEmettrice);
            }
            
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

    @PostMapping("/{invId}/affecter")
    public ResponseEntity<?> affecterMembres(@PathVariable Long invId, @RequestBody AffectationRequest req) {
        Invitation invMiseAJour = invitationService.affecterMembres(invId, req.getAgentIds(), req.getResponsableId());
        return ResponseEntity.ok(toDto(invMiseAJour));
    }

    @GetMapping("/{id}/export/pdf")
    public ResponseEntity<byte[]> exportPdf(@PathVariable Long id) {
        Invitation inv = invitationRepo.findById(id).orElseThrow();
        byte[] pdf = pdfService.generateInvitationLetter(inv);
        return ResponseEntity.ok().header("Content-Disposition", "attachment; filename=\"invitation_" + id + ".pdf\"").contentType(MediaType.APPLICATION_PDF).body(pdf);
    }

    @GetMapping("/{id}/export/word")
    public ResponseEntity<byte[]> exportWord(@PathVariable Long id) {
        Invitation inv = invitationRepo.findById(id).orElseThrow();
        byte[] wordDocument = wordService.generateInvitationWord(inv); 
        return ResponseEntity.ok().header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"invitation_" + id + ".docx\"").contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document")).body(wordDocument);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
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
        m.put("dateCreation", i.getDateCreation());
        
        m.put("structureEmettrice", (i.getStructureEmettrice() != null && i.getStructureEmettrice().getNom() != null) 
                                     ? i.getStructureEmettrice().getNom() 
                                     : "Non spécifiée");
        
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
}