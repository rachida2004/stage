package com.bf.dsi.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * 🎯 Représente une notification poussée EN DIRECT à un utilisateur connecté,
 * via Server-Sent Events (voir NotificationBroadcastService). Volontairement
 * PAS une entité JPA : rien de tout ceci n'est écrit en base de données.
 * Si l'utilisateur n'est pas connecté au moment de l'envoi, l'événement est
 * simplement perdu (pas de file d'attente, pas d'historique) — c'est le
 * comportement demandé : ne plus rien stocker.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationEvent {

    @Builder.Default
    private String id = UUID.randomUUID().toString();

    private String message;
    private String categorie;      // "TICKET" ou "INVITATION"
    private String actionLabel;
    private String resourceId;

    @Builder.Default
    private LocalDateTime dateEnvoi = LocalDateTime.now();
}