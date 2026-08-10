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
    private final StructureRepository structureRepo;
    private final ServiceRepository serviceRepo;

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
            "initiales", u.getInitiales(),
            // 🎯 Permissions agrégées de TOUS les rôles de l'utilisateur — permet
            // au frontend d'afficher/cacher des actions sans connaître les noms
            // de rôle eux-mêmes (ex: bouton "Affecter" visible si AFFECTER_TICKET).
            "permissions", permissionsDe(u)
        ));
    }

    @SuppressWarnings("null")
    // 🎯 Profil de l'utilisateur connecté — accessible à TOUT rôle (contrairement
    // à /api/admin/users qui est réservé à ADMIN). Utilisé notamment pour
    // préremplir la structure/service lors de la création d'un ticket.
    @GetMapping("/me")
    public ResponseEntity<?> monProfil(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Non authentifié."));
        }
        Utilisateur u;
        try {
            String email = jwtUtil.extractEmail(authHeader.replace("Bearer ", ""));
            u = utilisateurRepo.findByEmail(email).orElse(null);
        } catch (Exception e) {
            u = null;
        }
        if (u == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Session invalide."));

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.getUserId());
        m.put("nom", u.getNom());
        m.put("prenom", u.getPrenom());
        m.put("email", u.getEmail());
        m.put("telephone", u.getTelephone());
        m.put("structure", u.getStructure() != null ? u.getStructure().getNom() : null);
        m.put("structureId", u.getStructure() != null ? u.getStructure().getId() : null);
        m.put("service", u.getService() != null ? u.getService().getNom() : null);
        m.put("serviceId", u.getService() != null ? u.getService().getId() : null);
        return ResponseEntity.ok(m);
    }

    // 🎯 Mot de passe aléatoire (10 caractères, lettres + chiffres) utilisé
    // quand un admin crée un compte sans en saisir un lui-même.
    private String genererMotDePasseAleatoire() {
        String caracteres = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";
        java.security.SecureRandom random = new java.security.SecureRandom();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 10; i++) {
            sb.append(caracteres.charAt(random.nextInt(caracteres.length())));
        }
        return sb.toString();
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest req) {
        if (req.getNom() == null || req.getNom().isBlank())
            return ResponseEntity.badRequest().body(Map.of("error", "Le nom est requis"));
        if (req.getPrenom() == null || req.getPrenom().isBlank())
            return ResponseEntity.badRequest().body(Map.of("error", "Le prénom est requis"));
        if (req.getEmail() == null || req.getEmail().isBlank())
            return ResponseEntity.badRequest().body(Map.of("error", "L'email est requis"));
        if (utilisateurRepo.existsByEmail(req.getEmail()))
            return ResponseEntity.badRequest().body(Map.of("error", "Email déjà utilisé"));

        Role role = roleRepo.findByNom(req.getRole() != null ? req.getRole() : "USAGER")
            .orElseGet(() -> roleRepo.findByNom("USAGER").orElseThrow());

        // 🎯 Quand un admin crée un utilisateur, il ne saisit plus de mot de
        // passe (formulaire simplifié) : on en génère un aléatoire ici, et
        // il est envoyé par email au nouvel utilisateur juste après.
        String motDePasseClair = (req.getPassword() != null && !req.getPassword().isBlank())
            ? req.getPassword()
            : genererMotDePasseAleatoire();

        Utilisateur u = Utilisateur.builder()
            .nom(req.getNom())
            .prenom(req.getPrenom())
            .email(req.getEmail())
            .motDePasse(encoder.encode(motDePasseClair))
            .telephone(req.getTelephone())
            .iu(req.getIdentifiantUnique())
            .actif(true)
            .roles(new HashSet<>(Set.of(role)))
            .build();
        // 🎯 La structure/service choisis à l'inscription n'étaient jusqu'ici
        // jamais sauvegardés, ce qui empêchait tout préremplissage ultérieur
        // (création de ticket, etc.) puisqu'ils restaient NULL en base.
        if (req.getStructure() != null && !req.getStructure().isBlank()) {
            structureRepo.findByNom(req.getStructure()).ifPresent(u::setStructure);
        }
        if (req.getService() != null && !req.getService().isBlank()) {
            serviceRepo.findByNom(req.getService()).ifPresent(u::setService);
        }
        utilisateurRepo.save(u);

        // 🎯 L'utilisateur nouvellement créé (par lui-même ou par un admin)
        // reçoit ses identifiants de connexion par email — utile surtout
        // quand un admin crée un compte pour quelqu'un d'autre (agent,
        // secrétaire, usager), qui n'a alors aucun autre moyen de connaître
        // son mot de passe.
        try {
            SimpleMailMessage msg = new SimpleMailMessage();
            msg.setFrom("noreply@dsi.gov.bf");
            msg.setTo(u.getEmail());
            msg.setSubject("DSI Connect — Votre compte a été créé");
            msg.setText(
                "Bonjour " + u.getNom() + ",\n\n" +
                "Votre compte DSI Connect a été créé avec succès. Voici vos identifiants de connexion :\n\n" +
                "Email : " + u.getEmail() + "\n" +
                "Mot de passe : " + motDePasseClair + "\n\n" +
                "Nous vous recommandons de changer ce mot de passe dès votre première connexion.\n\n" +
                "— DSI Ministère, Burkina Faso"
            );
            mailSender.send(msg);
        } catch (Exception e) {
            // On n'interrompt pas la création du compte si l'envoi échoue
            // (ex: SMTP indisponible) — l'utilisateur peut toujours se
            // connecter avec les identifiants qu'il/l'admin a saisis.
        }

        String token = jwtUtil.generate(u.getEmail(), role.getNom());
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
            "token", token,
            "type", "Bearer",
            "id", u.getUserId(),
            "nom", u.getNom(),
            "prenom", u.getPrenom() != null ? u.getPrenom() : "",
            "email", u.getEmail(),
            "role", role.getNom(),
            "initiales", u.getInitiales(),
            "permissions", permissionsDe(u)
        ));
    }

    /** Permissions agrégées de tous les rôles de l'utilisateur (noms bruts, ex: "AFFECTER_TICKET"). */
    private java.util.Set<String> permissionsDe(Utilisateur u) {
        if (u.getRoles() == null) return java.util.Set.of();
        return u.getRoles().stream()
            .filter(r -> r.getPermissions() != null)
            .flatMap(r -> r.getPermissions().stream())
            .map(Enum::name)
            .collect(java.util.stream.Collectors.toSet());
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