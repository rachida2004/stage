package com.bf.dsi.controller;

import com.bf.dsi.entity.Role;
import com.bf.dsi.enums.Permission;
import com.bf.dsi.repository.RoleRepository;
import com.bf.dsi.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * CRUD complet sur les rôles (table `role`) + gestion de leurs permissions
 * (table `role_permissions`).
 *
 * ⚠️ Le champ `nom` d'un rôle (ADMIN, AGENT_DSI, SUPERVISEUR, USAGER...) reste
 * utilisé directement par certains contrôles historiques (hasAuthority("ADMIN")
 * notamment) et par Utilisateur.getPrimaryRole(). Mais désormais, tout nouveau
 * rôle peut aussi recevoir des PERMISSIONS (voir Permission.java) qui sont,
 * elles, vérifiées dynamiquement par SecurityConfig (hasAnyAuthority("ADMIN",
 * "MA_PERMISSION")) — donc plus besoin de modifier le code Java pour donner
 * des droits à un nouveau rôle : il suffit de cocher ses permissions ici.
 *   - le nom d'un rôle existant n'est pas modifiable une fois créé, pour ne
 *     pas casser les contrôles d'accès déjà en place (seule la description
 *     et les permissions sont éditables) ;
 *   - un rôle encore attribué à au moins un utilisateur ne peut pas être
 *     supprimé.
 */
@RestController
@RequestMapping("/api/roles")
@RequiredArgsConstructor
public class RoleController {

    private final RoleRepository roleRepo;
    private final UtilisateurRepository utilisateurRepo;

    @GetMapping
    public List<Role> lister() {
        return roleRepo.findAll();
    }

    /** Catalogue de toutes les permissions disponibles (pour les cases à cocher de l'écran Admin). */
    @GetMapping("/permissions")
    public List<String> listerPermissionsDisponibles() {
        return java.util.Arrays.stream(Permission.values()).map(Enum::name).collect(Collectors.toList());
    }

    @PostMapping
    public ResponseEntity<?> creer(@RequestBody Role role) {
        if (role.getNom() == null || role.getNom().trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Le nom du rôle est obligatoire"));
        }
        String nom = role.getNom().trim().toUpperCase().replace(" ", "_");
        if (roleRepo.findByNom(nom).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Ce rôle existe déjà"));
        }
        role.setId(null);
        role.setNom(nom);
        return ResponseEntity.status(HttpStatus.CREATED).body(roleRepo.save(role));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> modifier(@PathVariable Long id, @RequestBody Role role) {
        return roleRepo.findById(id).map(existant -> {
            if (role.getDescription() != null) {
                existant.setDescription(role.getDescription());
            }
            return ResponseEntity.ok(roleRepo.save(existant));
        }).orElse(ResponseEntity.notFound().build());
    }

    /**
     * Remplace l'ensemble des permissions d'un rôle.
     * Body attendu : { "permissions": ["GERER_INVITATIONS", "AFFECTER_AGENT"] }
     * Les chaînes ne correspondant à aucune valeur de l'enum Permission sont
     * ignorées silencieusement (évite un 500 si le frontend envoie un nom obsolète).
     */
    @PutMapping("/{id}/permissions")
    public ResponseEntity<?> modifierPermissions(@PathVariable Long id, @RequestBody Map<String, List<String>> body) {
        return roleRepo.findById(id).map(role -> {
            List<String> noms = body.getOrDefault("permissions", List.of());
            Set<Permission> permissions = new HashSet<>();
            for (String nom : noms) {
                try { permissions.add(Permission.valueOf(nom)); } catch (Exception ignored) {}
            }
            role.setPermissions(permissions);
            return ResponseEntity.ok(roleRepo.save(role));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> supprimer(@PathVariable Long id) {
        return roleRepo.findById(id).map(role -> {
            long nbUtilisateurs = utilisateurRepo.findByRoles_Nom(role.getNom()).size();
            if (nbUtilisateurs > 0) {
                return ResponseEntity.badRequest().body(Map.of(
                    "message",
                    "Impossible de supprimer : " + nbUtilisateurs + " utilisateur(s) ont encore ce rôle."
                ));
            }
            roleRepo.deleteById(id);
            return ResponseEntity.ok(Map.of("message", "Rôle supprimé"));
        }).orElse(ResponseEntity.notFound().build());
    }
}