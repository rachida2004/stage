package com.bf.dsi.controller;

import com.bf.dsi.dto.NotificationSettingsDto;
import com.bf.dsi.dto.RegisterRequest;
import com.bf.dsi.entity.*;
import com.bf.dsi.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {
    private final UtilisateurRepository utilisateurRepo;
    private final RoleRepository roleRepo;
    private final PasswordEncoder encoder;
    private final AppSettingRepository settingRepo;

    // ════════════════════════════════════════════════════════════════════
    // GESTION DES UTILISATEURS
    // ════════════════════════════════════════════════════════════════════

    @GetMapping("/users")
    public ResponseEntity<?> getUsers() {
        return ResponseEntity.ok(utilisateurRepo.findAll().stream().map(this::toDto).toList());
    }

    @PostMapping("/users")
    @Transactional
    public ResponseEntity<?> createUser(@RequestBody RegisterRequest req) {
        if (utilisateurRepo.existsByEmail(req.getEmail())) {
            return ResponseEntity.badRequest().body(Map.of("error", "Email déjà utilisé"));
        }

        Role role = roleRepo.findByNom(req.getRole() != null ? req.getRole() : "USAGER")
            .orElseGet(() -> roleRepo.findByNom("USAGER")
            .orElseThrow(() -> new RuntimeException("Rôle par défaut introuvable")));

        Utilisateur u = Utilisateur.builder()
            .nom(req.getNom())
            .prenom(req.getPrenom())
            .email(req.getEmail())
            .motDePasse(encoder.encode(req.getPassword() != null ? req.getPassword() : "Password123!"))
            .telephone(req.getTelephone())
            .iu(req.getIdentifiantUnique())
            .actif(true)
            .roles(new HashSet<>(Set.of(role)))
            .build();

        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(utilisateurRepo.save(u)));
    }

    @PutMapping("/users/{id}")
    @Transactional 
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        return utilisateurRepo.findById(id).map(u -> {
            if (body.containsKey("nom") && body.get("nom") != null) u.setNom(body.get("nom").toString());
            if (body.containsKey("prenom") && body.get("prenom") != null) u.setPrenom(body.get("prenom").toString());
            if (body.containsKey("telephone") && body.get("telephone") != null) u.setTelephone(body.get("telephone").toString());
            
            if (body.containsKey("role") && body.get("role") != null) {
                roleRepo.findByNom(body.get("role").toString()).ifPresent(r -> {
                    u.getRoles().clear();
                    u.getRoles().add(r);
                });
            }
            return ResponseEntity.ok(toDto(utilisateurRepo.save(u)));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/users/{id}/toggle")
    @Transactional
    public ResponseEntity<?> toggleUser(@PathVariable Long id) {
        return utilisateurRepo.findById(id).map(u -> {
            u.setActif(!Boolean.TRUE.equals(u.getActif()));
            return ResponseEntity.ok(toDto(utilisateurRepo.save(u)));
        }).orElse(ResponseEntity.notFound().build());
    }

    // ════════════════════════════════════════════════════════════════════
    // PARAMÈTRES DYNAMIQUES
    // ════════════════════════════════════════════════════════════════════

    @GetMapping("/settings")
    public ResponseEntity<?> getSettings() {
        Map<String, Object> settingsMap = new LinkedHashMap<>();
        settingsMap.put("delaiMaxSansAffectation", getParam("delaiMaxSansAffectation", "48h"));
        settingsMap.put("langue", getParam("langue", "Français"));
        settingsMap.put("notificationsEmail", Boolean.parseBoolean(getParam("notificationsEmail", "true")));
        settingsMap.put("notificationsInternes", Boolean.parseBoolean(getParam("notificationsInternes", "true")));
        return ResponseEntity.ok(settingsMap);
    }

    @PostMapping("/settings")
    @Transactional
    public ResponseEntity<?> saveSettings(@RequestBody NotificationSettingsDto dto) {
        saveOrUpdateSetting("notificationsEmail", String.valueOf(dto.isNotificationsEmail()));
        saveOrUpdateSetting("notificationsInternes", String.valueOf(dto.isNotificationsInternes()));
        saveOrUpdateSetting("delaiMaxSansAffectation", dto.getDelaiMaxSansAffectation());
        if (dto.getLangue() != null) {
            saveOrUpdateSetting("langue", dto.getLangue());
        }
        return ResponseEntity.ok(Map.of("message", "Paramètres sauvegardés avec succès"));
    }

    // Méthode utilitaire pour éviter le rouge
    private void saveOrUpdateSetting(String cle, String valeur) {
        AppSetting setting = settingRepo.findById(cle).orElse(new AppSetting());
        if (setting.getCle() == null) {
            setting.setCle(cle);
        }
        setting.setValeur(valeur);
        settingRepo.save(setting);
    }

    private String getParam(String cle, String valeurParDefaut) {
        return settingRepo.findById(cle).map(AppSetting::getValeur).orElse(valeurParDefaut);
    }

    private Map<String, Object> toDto(Utilisateur u) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.getUserId() != null ? u.getUserId().toString() : null); 
        m.put("nom", u.getNom());
        m.put("prenom", u.getPrenom() != null ? u.getPrenom() : "");
        m.put("email", u.getEmail());
        m.put("telephone", u.getTelephone());
        m.put("role", u.getPrimaryRole() != null ? u.getPrimaryRole().name() : "USAGER");
        m.put("initiales", u.getInitiales());
        m.put("active", u.getActif());
        m.put("isActive", u.getActif());
        m.put("structure", u.getStructure() != null ? u.getStructure().getNom() : null);
        m.put("service", u.getService() != null ? u.getService().getNom() : null);
        return m;
    }
}