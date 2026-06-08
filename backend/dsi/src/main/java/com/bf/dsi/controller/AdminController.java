package com.bf.dsi.controller;

import com.bf.dsi.dto.RegisterRequest;
import com.bf.dsi.entity.*;
import com.bf.dsi.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {
    private final UtilisateurRepository utilisateurRepo;
    private final RoleRepository roleRepo;
    private final PasswordEncoder encoder;

    @GetMapping("/users")
    public ResponseEntity<?> getUsers() {
        return ResponseEntity.ok(utilisateurRepo.findAll().stream().map(this::toDto).toList());
    }
@SuppressWarnings("null")
    @PostMapping("/users")
    public ResponseEntity<?> createUser(@RequestBody RegisterRequest req) {
        if (utilisateurRepo.existsByEmail(req.getEmail()))
            return ResponseEntity.badRequest().body(Map.of("error", "Email déjà utilisé"));

        Role role = roleRepo.findByNom(req.getRole() != null ? req.getRole() : "USAGER")
            .orElseGet(() -> roleRepo.findByNom("USAGER").orElseThrow());

        Utilisateur u = Utilisateur.builder()
            .nom(req.getNom()).prenom(req.getPrenom()).email(req.getEmail())
            .motDePasse(encoder.encode(req.getPassword() != null ? req.getPassword() : "Password123!"))
            .telephone(req.getTelephone()).iu(req.getIdentifiantUnique()).actif(true)
            .roles(new HashSet<>(Set.of(role))).build();
        utilisateurRepo.save(u);
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(u));
    }
@SuppressWarnings("null")
    @PutMapping("/users/{id}")
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        return utilisateurRepo.findById(id).map(u -> {
            if (body.containsKey("nom")) u.setNom(body.get("nom").toString());
            if (body.containsKey("prenom")) u.setPrenom(body.get("prenom").toString());
            if (body.containsKey("telephone")) u.setTelephone(body.get("telephone").toString());
            if (body.containsKey("role")) {
                roleRepo.findByNom(body.get("role").toString()).ifPresent(r -> {
                    u.getRoles().clear();
                    u.getRoles().add(r);
                });
            }
            return ResponseEntity.ok(toDto(utilisateurRepo.save(u)));
        }).orElse(ResponseEntity.notFound().build());
    }
@SuppressWarnings("null")
    @PatchMapping("/users/{id}/toggle")
    public ResponseEntity<?> toggleUser(@PathVariable Long id) {
        return utilisateurRepo.findById(id).map(u -> {
            u.setActif(!Boolean.TRUE.equals(u.getActif()));
            return ResponseEntity.ok(toDto(utilisateurRepo.save(u)));
        }).orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/settings")
    public ResponseEntity<?> getSettings() {
        return ResponseEntity.ok(Map.of(
            "delaiMaxSansAffectation", "48h",
            "langue", "Français",
            "notificationsEmail", true,
            "notificationsInternes", true
        ));
    }

    @PostMapping("/settings")
    public ResponseEntity<?> saveSettings(@RequestBody Map<String, Object> settings) {
        // Sauvegarder en base ou fichier properties selon les besoins
        return ResponseEntity.ok(Map.of("message", "Paramètres sauvegardés"));
    }

    private Map<String, Object> toDto(Utilisateur u) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.getUserId());
        m.put("nom", u.getNom());
        m.put("prenom", u.getPrenom() != null ? u.getPrenom() : "");
        m.put("email", u.getEmail());
        m.put("telephone", u.getTelephone());
        m.put("role", u.getPrimaryRole().name());
        m.put("initiales", u.getInitiales());
        m.put("active", u.getActif());
        m.put("isActive", u.getActif());
        m.put("structure", u.getStructure() != null ? u.getStructure().getNom() : null);
        m.put("service", u.getService() != null ? u.getService().getNom() : null);
        return m;
    }
}
