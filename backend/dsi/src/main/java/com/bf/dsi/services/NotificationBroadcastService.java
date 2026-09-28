package com.bf.dsi.services;

import com.bf.dsi.dto.NotificationEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * 🎯 Remplace le stockage en base des notifications (table "notification",
 * supprimée) par un envoi EN DIRECT aux clients connectés, via Server-Sent
 * Events (flux HTTP long, une seule requête GET maintenue ouverte).
 *
 * Fonctionnement :
 *  - Chaque client Flutter ouvre une connexion sur GET /api/notifications/stream
 *    (une fois connecté, via TicketBloc/NotifBloc) → abonner(userId) crée un
 *    SseEmitter et le garde en mémoire, indexé par userId.
 *  - Quand un événement survient (ticket affecté, invitation créée...),
 *    envoyer(userId, event) pousse l'événement à TOUS les emitters actifs
 *    de cet utilisateur (plusieurs onglets/appareils possibles).
 *  - Si l'utilisateur n'a AUCUN emitter actif (pas connecté / app fermée),
 *    l'événement est perdu — c'est le comportement voulu : rien n'est
 *    stocké nulle part pour le lui redonner plus tard.
 *  - Tout est en mémoire (ConcurrentHashMap) : un redémarrage du backend
 *    déconnecte tous les clients (ils se reconnectent automatiquement côté
 *    Flutter) et ne perd donc rien de plus que ce qui est déjà volontairement
 *    éphémère.
 */
@Service
public class NotificationBroadcastService {

    private static final Logger log = LoggerFactory.getLogger(NotificationBroadcastService.class);

    // ⏱️ Timeout long (30 min) : le client Flutter reconnecte automatiquement
    // avant/à l'expiration, mais on évite de couper trop souvent.
    private static final long TIMEOUT_MS = 30 * 60 * 1000L;

    private final Map<Long, List<SseEmitter>> emittersParUtilisateur = new ConcurrentHashMap<>();

    /** Ouvre un nouvel abonnement pour cet utilisateur et retourne l'emitter à renvoyer au client. */
    public SseEmitter abonner(Long userId) {
        SseEmitter emitter = new SseEmitter(TIMEOUT_MS);
        emittersParUtilisateur.computeIfAbsent(userId, k -> new CopyOnWriteArrayList<>()).add(emitter);

        Runnable retirer = () -> {
            List<SseEmitter> liste = emittersParUtilisateur.get(userId);
            if (liste != null) {
                liste.remove(emitter);
                if (liste.isEmpty()) emittersParUtilisateur.remove(userId);
            }
        };
        emitter.onCompletion(retirer::run);
        emitter.onTimeout(retirer::run);
        emitter.onError(e -> retirer.run());

        // 🎯 Petit événement immédiat pour confirmer la connexion côté client
        // (utile pour distinguer "connecté, en attente" de "jamais connecté").
        try {
            emitter.send(SseEmitter.event().name("connecte").data("ok"));
        } catch (IOException ignored) {
            retirer.run();
        }
        return emitter;
    }

    /** Envoie un événement à un seul utilisateur (tous ses appareils/onglets connectés). */
    public void envoyer(Long userId, NotificationEvent event) {
        if (userId == null) return;
        List<SseEmitter> liste = emittersParUtilisateur.get(userId);
        if (liste == null || liste.isEmpty()) return; // personne de connecté : perdu, volontairement

        for (SseEmitter emitter : liste) {
            try {
                emitter.send(SseEmitter.event().name("notification").data(event));
            } catch (IOException | IllegalStateException e) {
                emitter.completeWithError(e);
            }
        }
    }

    /** Envoie le même événement à plusieurs utilisateurs (ex: tous les ADMIN). */
    public void envoyerAGroupe(Collection<Long> userIds, NotificationEvent event) {
        if (userIds == null) return;
        userIds.forEach(id -> envoyer(id, event));
    }

    /** Nombre d'utilisateurs actuellement connectés au flux (diagnostic / tests). */
    public int nbUtilisateursConnectes() {
        return emittersParUtilisateur.size();
    }
}