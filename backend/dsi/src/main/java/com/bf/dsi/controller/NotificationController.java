package com.bf.dsi.controller;

import com.bf.dsi.entity.*;
import com.bf.dsi.repository.*;
import com.bf.dsi.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {
    private final NotificationRepository notificationRepo;
    private final UtilisateurRepository utilisateurRepo;
    private final JwtUtil jwtUtil;

    // Route appelée par Flutter : /api/notifications/user/3
    @GetMapping("/user/{userId}")
    public ResponseEntity<?> getByUserId(@PathVariable Long userId) {
        List<Map<String, Object>> result = notificationRepo
            .findByUtilisateurUserIdOrderByDateEnvoiDesc(userId)
            .stream().map(this::toDto).toList();
        return ResponseEntity.ok(result);
    }

    // Route avec JWT auto
    @GetMapping
    public ResponseEntity<?> getMesNotifications(
            @RequestHeader("Authorization") String authHeader) {
        Long userId = extractUserId(authHeader);
        if (userId == null) return ResponseEntity.status(401).build();
        List<Map<String, Object>> result = notificationRepo
            .findByUtilisateurUserIdOrderByDateEnvoiDesc(userId)
            .stream().map(this::toDto).toList();
        return ResponseEntity.ok(result);
    }

    @PutMapping("/{id}/lire")
    public ResponseEntity<?> marquerLu(@PathVariable Long id) {
        return notificationRepo.findById(id).map(n -> {
            n.setStatut(true);
            notificationRepo.save(n);
            return ResponseEntity.ok(Map.of("message", "Notification marquée comme lue"));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/lire-tout")
    public ResponseEntity<?> marquerToutLu(
            @RequestHeader("Authorization") String authHeader) {
        Long userId = extractUserId(authHeader);
        if (userId == null) return ResponseEntity.status(401).build();
        List<Notification> notifs = notificationRepo
            .findByUtilisateurUserIdOrderByDateEnvoiDesc(userId);
        notifs.forEach(n -> n.setStatut(true));
        notificationRepo.saveAll(notifs);
        return ResponseEntity.ok(Map.of("message", "Toutes lues"));
    }

    // Route appelée par Flutter : /api/notifications/user/3/unread-count
    @GetMapping("/user/{userId}/unread-count")
    public ResponseEntity<?> countUnreadByUser(@PathVariable Long userId) {
        long count = notificationRepo.countByUtilisateurUserIdAndStatutFalse(userId);
        return ResponseEntity.ok(Map.of("count", count));
    }

    @GetMapping("/non-lues/count")
    public ResponseEntity<?> countNonLues(
            @RequestHeader("Authorization") String authHeader) {
        Long userId = extractUserId(authHeader);
        if (userId == null) return ResponseEntity.status(401).build();
        long count = notificationRepo.countByUtilisateurUserIdAndStatutFalse(userId);
        return ResponseEntity.ok(Map.of("count", count));
    }

    private Long extractUserId(String authHeader) {
        try {
            String token = authHeader.replace("Bearer ", "");
            String email = jwtUtil.extractEmail(token);
            return utilisateurRepo.findByEmail(email)
                .map(Utilisateur::getUserId).orElse(null);
        } catch (Exception e) { return null; }
    }

    private Map<String, Object> toDto(Notification n) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", n.getId());
        m.put("message", n.getMessage());
        m.put("category", n.getCategorie());
        m.put("createdAt", n.getDateEnvoi());
        m.put("read", n.getStatut());
        m.put("actionLabel", n.getActionLabel());
        m.put("relatedResourceId", n.getResourceId());
        return m;
    }
}