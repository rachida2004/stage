package com.bf.dsi.config;

import com.bf.dsi.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.*;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

@Configuration
@RequiredArgsConstructor
public class UserDetailsServiceConfig {

    private final UtilisateurRepository utilisateurRepo;

    @Bean
    public UserDetailsService userDetailsService() {
        return email -> utilisateurRepo.findByEmail(email)
            .map(u -> User.builder()
                .username(u.getEmail())
                .password(u.getMotDePasse())
                // Correction ici : on passe le rôle comme une autorité brute (ex: "ADMIN", "AGENT_DSI")
                // sans que Spring n'ajoute de préfixe caché "ROLE_"
                .authorities(new SimpleGrantedAuthority(u.getPrimaryRole().name()))
                .build())
            .orElseThrow(() -> new UsernameNotFoundException("Utilisateur non trouvé: " + email));
    }
}