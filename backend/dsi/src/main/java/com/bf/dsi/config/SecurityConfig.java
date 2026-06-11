package com.bf.dsi.config;

import com.bf.dsi.security.JwtFilter;
import org.springframework.context.annotation.*;
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
            .cors(c -> c.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/uploads/**").permitAll()
                
                // 🎯 AJOUT : Autorise le téléchargement des pièces jointes sans token JWT
                .requestMatchers("/api/files/download/**").permitAll()
                
                .requestMatchers("/api/invitations/*/export/**").permitAll()
                .requestMatchers("/api/dashboard/**").permitAll()
                .requestMatchers("/error").permitAll()
                .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/agents").permitAll()
                
                // Admin uniquement
                .requestMatchers("/api/admin/**").hasAuthority("ADMIN")
                
                // Liste des agents — accessible à tous les authentifiés (pour le modal d'affectation)
                .requestMatchers("/api/agents/**").hasAnyAuthority("ADMIN", "AGENT_DSI", "SUPERVISEUR")
                
                // Tickets — USAGER peut créer (POST) et voir les siens (GET)
                .requestMatchers("/api/tickets/**").hasAnyAuthority("ADMIN", "AGENT_DSI", "SUPERVISEUR", "USAGER")
                
                // Invitations — lecture pour tous, écriture filtrée côté service si besoin
                .requestMatchers("/api/invitations/**").hasAnyAuthority("ADMIN", "AGENT_DSI", "SUPERVISEUR", "USAGER")
                
                // Notifications — accessibles à tous les authentifiés
                .requestMatchers("/api/notifications/**").hasAnyAuthority("ADMIN", "AGENT_DSI", "SUPERVISEUR", "USAGER")
                
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