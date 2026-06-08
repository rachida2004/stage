package com.bf.dsi.config;

import com.bf.dsi.entity.*;
import com.bf.dsi.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.util.Set;

@Configuration
@RequiredArgsConstructor
public class DataInitializer {

    private final UtilisateurRepository utilisateurRepo;
    private final RoleRepository roleRepo;
    private final PasswordEncoder encoder;

    @Bean
    public CommandLineRunner initData() {
        return args -> {
            // Créer l'admin par défaut si absent
            if (!utilisateurRepo.existsByEmail("admin@dsi.gov.bf")) {
                Role adminRole = roleRepo.findByNom("ADMIN")
                    .orElseThrow(() -> new RuntimeException(
                        "Role ADMIN absent — vérifiez que gestion.sql a bien été importé"));

                Utilisateur admin = Utilisateur.builder()
                    .nom("Administrateur")
                    .prenom("Système")
                    .email("admin@dsi.gov.bf")
                    .motDePasse(encoder.encode("Admin123!"))
                    .iu("ADM-001")
                    .actif(true)
                    .roles(new java.util.HashSet<>(Set.of(adminRole)))
                    .build();
                utilisateurRepo.save(admin);
                System.out.println("✅ Admin créé → admin@dsi.gov.bf / Admin123!");
            }

            // Agent DSI de démonstration
            if (!utilisateurRepo.existsByEmail("agent@dsi.gov.bf")) {
                Role agentRole = roleRepo.findByNom("AGENT_DSI")
                    .orElseThrow(() -> new RuntimeException("Role AGENT_DSI absent"));

                Utilisateur agent = Utilisateur.builder()
                    .nom("Traoré")
                    .prenom("Sali")
                    .email("agent@dsi.gov.bf")
                    .motDePasse(encoder.encode("Agent123!"))
                    .iu("AGT-001")
                    .actif(true)
                    .roles(new java.util.HashSet<>(Set.of(agentRole)))
                    .build();
                utilisateurRepo.save(agent);
                System.out.println("✅ Agent créé → agent@dsi.gov.bf / Agent123!");
            }
        };
    }
}