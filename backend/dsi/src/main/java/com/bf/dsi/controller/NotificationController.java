package com.bf.dsi.controller;

import com.bf.dsi.entity.Utilisateur;
import com.bf.dsi.repository.UtilisateurRepository;
import com.bf.dsi.security.JwtUtil;
import com.bf.dsi.services.NotificationBroadcastService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Map;

/**
 * 🎯 Les notifications ne sont plus stockées en base (table "notification"
 * supprimée) — elles sont désormais poussées EN DIRECT via Server-Sent
 * Events. Un client qui n'est pas connecté au moment de l'événement ne le
 * reçoit jamais (pas d'historique, pas de rattrapage possible).
 *
 * Les anciennes routes REST (GET /api/notifications, PUT .../lire,
 * .../lire-tout, .../unread-count) ont disparu : il n'y a plus rien à lire
 * ou marquer côté serveur, tout est géré en mémoire côté client Flutter
 * (NotifBloc) une fois l'événement reçu.
 *
 * Le jeton JWT est transmis en en-tête Authorization comme pour les autres
 * routes (le client Flutter utilise Dio en flux, pas l'API EventSource du
 * navigateur, donc l'en-tête personnalisé passe sans problème).
 */
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationBroadcastService broadcastService;
    private final UtilisateurRepository utilisateurRepo;
    private final JwtUtil jwtUtil;

    /** Flux temps réel : reste ouvert tant que le client est connecté. */
    @GetMapping(value = "/stream", produces = "text/event-stream")
    public SseEmitter stream(@RequestHeader("Authorization") String authHeader) {
        Long userId = extractUserId(authHeader);
        if (userId == null) {
            // 🎯 SseEmitter ne permet pas de renvoyer un vrai 401 une fois le
            // flux ouvert ; on retourne un emitter immédiatement clos plutôt
            // que de laisser un client non authentifié en attente indéfinie.
            SseEmitter vide = new SseEmitter(0L);
            vide.complete();
            return vide;
        }
        return broadcastService.abonner(userId);
    }

    /** Diagnostic simple : combien d'utilisateurs ont un flux ouvert en ce moment. */
    @GetMapping("/stream/stats")
    public ResponseEntity<?> stats() {
        return ResponseEntity.ok(Map.of("utilisateursConnectes", broadcastService.nbUtilisateursConnectes()));
    }

    private Long extractUserId(String authHeader) {
        try {
            String token = authHeader.replace("Bearer ", "");
            String email = jwtUtil.extractEmail(token);
            return utilisateurRepo.findByEmail(email)
                .map(Utilisateur::getUserId).orElse(null);
        } catch (Exception e) { return null; }
    }
}