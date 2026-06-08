package com.bf.dsi.controller;

import com.bf.dsi.dto.*;
import com.bf.dsi.entity.*;
import com.bf.dsi.repository.*;
import com.bf.dsi.security.JwtUtil;
import lombok.*;
import org.springframework.http.*;
import org.springframework.security.authentication.*;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    private final UtilisateurRepository utilisateurRepo;
    private final RoleRepository roleRepo;
    private final AuthenticationManager authManager;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder encoder;

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

    @PostMapping("/mot-de-passe-oublie")
    public ResponseEntity<?> forgotPassword(@RequestBody Map<String, String> body) {
        // En production : envoyer un email avec lien de réinitialisation
        return ResponseEntity.ok(Map.of("message", "Si le compte existe, un email a été envoyé."));
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout() {
        return ResponseEntity.ok(Map.of("message", "Déconnecté"));
    }
}
