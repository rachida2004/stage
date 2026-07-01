package com.bf.dsi.config;

import com.bf.dsi.entity.Role;
import com.bf.dsi.entity.Utilisateur;
import com.bf.dsi.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.LinkedHashSet;
import java.util.Set;

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
                // 🎯 Système de permissions dynamique : on accorde toujours le nom du
                // rôle "primaire" (compat historique, ex: "ADMIN") ET, en plus, toutes
                // les permissions explicitement cochées sur CHACUN des rôles de
                // l'utilisateur (ex: "GERER_INVITATIONS", "AFFECTER_AGENT"). Ainsi, un
                // nouveau rôle créé depuis l'écran Admin obtient de vrais droits dès
                // qu'on lui coche des permissions — sans toucher au code Java.
                .authorities(autorites(u))
                .build())
            .orElseThrow(() -> new UsernameNotFoundException("Utilisateur non trouvé: " + email));
    }

    private Set<GrantedAuthority> autorites(Utilisateur u) {
        Set<GrantedAuthority> autorites = new LinkedHashSet<>();
        autorites.add(new SimpleGrantedAuthority(u.getPrimaryRole().name()));
        if (u.getRoles() != null) {
            for (Role role : u.getRoles()) {
                if (role.getPermissions() != null) {
                    role.getPermissions().forEach(p -> autorites.add(new SimpleGrantedAuthority(p.name())));
                }
            }
        }
        return autorites;
    }
}