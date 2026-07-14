package com.bf.dsi.config;

import com.bf.dsi.security.JwtFilter;
import org.springframework.context.annotation.*;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.*;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.*;
import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration cfg) throws Exception {
        return cfg.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http,
                                            JwtFilter jwtFilter) throws Exception {
        http
            // 🎯 CORRECTION : frameOptions doit être imbriqué dans .headers()
            .headers(headers -> headers
                .frameOptions(frameOptions -> frameOptions.disable())
            )
            .cors(c -> c.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/uploads/**").permitAll()

                // 🎯 Swagger / OpenAPI — accès libre pour les tests manuels
                .requestMatchers(
                    "/swagger-ui/**", "/swagger-ui.html",
                    "/v3/api-docs/**", "/v3/api-docs.yaml"
                ).permitAll()

                // 🎯 Autorise le téléchargement des pièces jointes sans token JWT
                .requestMatchers("/api/files/download/**").permitAll()

                // 🎯 Permet l'ouverture directe des liens d'export PDF/Word dans un nouvel onglet
                // (navigation directe = pas d'en-tête Authorization possible)
                .requestMatchers("/api/invitations/*/export/**").permitAll()
                
                .requestMatchers("/api/invitations/*/export/**").hasAnyAuthority("ADMIN")
                .requestMatchers("/api/dashboard/**").permitAll()
                .requestMatchers("/error").permitAll()
                .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/agents").permitAll()
                
                // Admin uniquement (sauf paramètres, ouverts aussi à MODIFIER_PARAMETRE)
                // 🎯 La LECTURE des paramètres (ex: langue de l'interface) doit être
                // accessible à tout utilisateur connecté — c'est appelé au tout
                // lancement de l'app, avant même la connexion d'un Admin éventuel.
                // Seule l'ÉCRITURE reste réservée à l'ADMIN ou à MODIFIER_PARAMETRE.
                .requestMatchers(HttpMethod.GET, "/api/admin/settings").authenticated()
                .requestMatchers(HttpMethod.POST, "/api/admin/settings").hasAnyAuthority("ADMIN", "MODIFIER_PARAMETRE")
                .requestMatchers("/api/admin/**").hasAuthority("ADMIN")

                // Rôles — gestion réservée aux ADMIN (sensible : pilote les droits d'accès)
                .requestMatchers("/api/roles/**").hasAuthority("ADMIN")
                
                // 🎯 Affecter un agent à une INVITATION : ADMIN, ou tout rôle ayant
                // explicitement la permission AFFECTER_INVITATION (cochée depuis
                // Admin → Rôles → permissions — aucune modif de code nécessaire).
                // (placé AVANT la règle générale /api/invitations/** ci-dessous :
                // Spring Security retient le premier matcher qui correspond)
                .requestMatchers("/api/invitations/*/affecter").hasAnyAuthority("ADMIN","SECRETAIRE", "AFFECTER_INVITATION")

                // Liste des agents — accessible à tous les authentifiés (pour le modal d'affectation)
                .requestMatchers("/api/agents/**").hasAnyAuthority("ADMIN", "AGENT_DSI", "SUPERVISEUR")
                
                // 🎯 Un USAGER crée un ticket et le consulte, mais ne gère pas son
                // cycle de vie (changer le statut, affecter un agent, supprimer) —
                // c'est l'agent affecté ou un superviseur/admin qui s'en charge.
                // Le changement de STATUT est en plus restreint, au niveau applicatif
                // (TicketController.changerStatut), au seul agent affecté au ticket
                // concerné — ADMIN/SUPERVISEUR passent outre cette restriction.
                .requestMatchers(HttpMethod.PUT, "/api/tickets/*/statut").hasAnyAuthority("ADMIN", "AGENT_DSI", "SUPERVISEUR")
                .requestMatchers(HttpMethod.POST, "/api/tickets/*/affecter/**").hasAnyAuthority("ADMIN", "SUPERVISEUR","SECRETAIRE", "AFFECTER_TICKET")
                .requestMatchers(HttpMethod.DELETE, "/api/tickets/**").hasAnyAuthority("ADMIN", "AGENT_DSI", "SUPERVISEUR")

                // Tickets — USAGER peut créer (POST) et voir les siens (GET) ; +
                // CREER_TICKET pour tout rôle personnalisé à qui on a coché cette permission.
                .requestMatchers("/api/tickets/**").hasAnyAuthority("ADMIN", "AGENT_DSI", "SUPERVISEUR","SECRETAIRE", "USAGER", "CREER_TICKET")
                
                // 🎯 Création d'invitation (POST) : réservée à ADMIN, SUPERVISEUR,
                // SECRETAIRE et tout rôle ayant la permission ENREGISTRER_INVITATION.
                // Un AGENT_DSI ne crée pas d'invitation — il gère ses affectations.
                .requestMatchers(HttpMethod.POST, "/api/invitations/**").hasAnyAuthority("ADMIN", "SUPERVISEUR", "SECRETAIRE", "ENREGISTRER_INVITATION")

                // Invitations — lecture pour ADMIN/AGENT_DSI/SUPERVISEUR/SECRETAIRE ;
                // + ENREGISTRER_INVITATION pour tout rôle personnalisé à qui on a coché cette permission.
                // 🎯 USAGER exclu : un usager ne doit que créer un ticket et suivre
                // son état, pas consulter les invitations.
                .requestMatchers("/api/invitations/**").hasAnyAuthority("ADMIN", "AGENT_DSI", "SUPERVISEUR", "SECRETAIRE", "ENREGISTRER_INVITATION")
                
                // Notifications — accessibles à tous les authentifiés ;
                // + VOIR_NOTIFICATION / RECEVOIR_NOTIFICATION pour tout rôle personnalisé.
                .requestMatchers("/api/notifications/**").hasAnyAuthority("ADMIN", "AGENT_DSI", "SUPERVISEUR", "USAGER", "SECRETAIRE", "VOIR_NOTIFICATION", "RECEVOIR_NOTIFICATION")
                .requestMatchers(HttpMethod.GET, "/api/services").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/services/**").permitAll()
                .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/structures").permitAll()
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("*"));
        config.setAllowedMethods(List.of("GET","POST","PUT","PATCH","DELETE","OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}