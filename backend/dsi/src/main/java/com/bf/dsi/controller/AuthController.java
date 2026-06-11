package com.bf.dsi.controller;

import com.bf.dsi.dto.*;
import com.bf.dsi.entity.*;
import com.bf.dsi.repository.*;
import com.bf.dsi.security.JwtUtil;
import lombok.*;
import org.springframework.http.*;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.authentication.*;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    private final UtilisateurRepository utilisateurRepo;
    private final RoleRepository roleRepo;
    private final AuthenticationManager authManager;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder encoder;
    private final JavaMailSender mailSender;

    // Stockage en mémoire des tokens de reset (en prod : table reset_token en base)
    // token → { email, expiry }
    private final Map<String, Object[]> resetTokens = new ConcurrentHashMap<>();

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {
        try {
            authManager.authenticate(
                new UsernamePasswordAuthenticationToken(req.getEmail(), req.getPassword()));
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("error", "Email ou mot de passe incorrect"));
        }
        Utilisateur u = utilisateurRepo.findByEmail(req.getEmail())
            .orElseThrow(() -> new UsernameNotFoundException("Not found"));
        String token = jwtUtil.generate(u.getEmail(), u.getPrimaryRole().name());
        return ResponseEntity.ok(Map.of(
            "token", token,
            "type", "Bearer",
            "id", u.getUserId(),
            "nom", u.getNom(),
            "prenom", u.getPrenom() != null ? u.getPrenom() : "",
            "email", u.getEmail(),
            "role", u.getPrimaryRole().name(),
            "initiales", u.getInitiales()
        ));
    }

    @SuppressWarnings("null")
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest req) {
        if (utilisateurRepo.existsByEmail(req.getEmail()))
            return ResponseEntity.badRequest().body(Map.of("error", "Email déjà utilisé"));

        Role role = roleRepo.findByNom(req.getRole() != null ? req.getRole() : "USAGER")
            .orElseGet(() -> roleRepo.findByNom("USAGER").orElseThrow());

        Utilisateur u = Utilisateur.builder()
            .nom(req.getNom())
            .prenom(req.getPrenom())
            .email(req.getEmail())
            .motDePasse(encoder.encode(req.getPassword()))
            .telephone(req.getTelephone())
            .iu(req.getIdentifiantUnique())
            .actif(true)
            .roles(new HashSet<>(Set.of(role)))
            .build();
        utilisateurRepo.save(u);

        String token = jwtUtil.generate(u.getEmail(), role.getNom());
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
            "token", token,
            "type", "Bearer",
            "id", u.getUserId(),
            "nom", u.getNom(),
            "prenom", u.getPrenom() != null ? u.getPrenom() : "",
            "email", u.getEmail(),
            "role", role.getNom(),
            "initiales", u.getInitiales()
        ));
    }

    /**
     * Étape 1 — L'utilisateur soumet son email.
     * On génère un token à 6 chiffres valable 15 minutes et on l'envoie par email.
     * POST /api/auth/mot-de-passe-oublie   body: { "email": "..." }
     */
    @PostMapping("/mot-de-passe-oublie")
    public ResponseEntity<?> forgotPassword(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        if (email == null || email.isBlank())
            return ResponseEntity.badRequest().body(Map.of("error", "Email requis"));

        // Réponse identique qu'il existe ou non (sécurité anti-énumération)
        Optional<Utilisateur> opt = utilisateurRepo.findByEmail(email.trim());
        if (opt.isEmpty())
            return ResponseEntity.ok(Map.of("message", "Si le compte existe, un code a été envoyé."));

        // Générer un code à 6 chiffres
        String code = String.format("%06d", new Random().nextInt(999999));
        LocalDateTime expiry = LocalDateTime.now().plusMinutes(15);
        resetTokens.put(code, new Object[]{email.trim(), expiry});

        // Envoyer l'email
        try {
            SimpleMailMessage msg = new SimpleMailMessage();
            msg.setFrom("noreply@dsi.gov.bf");
            msg.setTo(email.trim());
            msg.setSubject("DSI Connect — Réinitialisation de mot de passe");
            msg.setText(
                "Bonjour " + opt.get().getNom() + ",\n\n" +
                "Votre code de réinitialisation est : " + code + "\n\n" +
                "Ce code est valable 15 minutes.\n" +
                "Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.\n\n" +
                "— DSI Ministère, Burkina Faso"
            );
            mailSender.send(msg);
        } catch (Exception e) {
            // Log l'erreur mais ne pas exposer les détails au client
            return ResponseEntity.status(500)
                .body(Map.of("error", "Erreur lors de l'envoi de l'email. Contactez l'administrateur."));
        }

        return ResponseEntity.ok(Map.of("message", "Si le compte existe, un code a été envoyé."));
    }

    /**
     * Étape 2 — L'utilisateur soumet le code reçu + son nouveau mot de passe.
     * POST /api/auth/reinitialiser-mot-de-passe   body: { "code": "123456", "nouveauMotDePasse": "..." }
     */
    @PostMapping("/reinitialiser-mot-de-passe")
    public ResponseEntity<?> resetPassword(@RequestBody Map<String, String> body) {
        String code = body.get("code");
        String nouveauMdp = body.get("nouveauMotDePasse");

        if (code == null || nouveauMdp == null || nouveauMdp.length() < 8)
            return ResponseEntity.badRequest()
                .body(Map.of("error", "Code et nouveau mot de passe (8 caractères min) requis"));

        Object[] entry = resetTokens.get(code);
        if (entry == null)
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("error", "Code invalide ou déjà utilisé"));

        LocalDateTime expiry = (LocalDateTime) entry[1];
        if (LocalDateTime.now().isAfter(expiry)) {
            resetTokens.remove(code);
            return ResponseEntity.status(HttpStatus.GONE)
                .body(Map.of("error", "Code expiré. Recommencez la procédure."));
        }

        String email = (String) entry[0];
        Optional<Utilisateur> opt = utilisateurRepo.findByEmail(email);
        if (opt.isEmpty())
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", "Utilisateur introuvable"));

        Utilisateur u = opt.get();
        u.setMotDePasse(encoder.encode(nouveauMdp));
        utilisateurRepo.save(u);
        resetTokens.remove(code); // token à usage unique

        return ResponseEntity.ok(Map.of("message", "Mot de passe réinitialisé avec succès."));
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout() {
        return ResponseEntity.ok(Map.of("message", "Déconnecté"));
    }
}