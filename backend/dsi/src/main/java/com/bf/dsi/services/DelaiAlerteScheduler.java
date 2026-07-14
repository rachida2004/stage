package com.bf.dsi.services;

import com.bf.dsi.entity.Invitation;
import com.bf.dsi.entity.Notification;
import com.bf.dsi.entity.Ticket;
import com.bf.dsi.entity.Utilisateur;
import com.bf.dsi.repository.InvitationRepository;
import com.bf.dsi.repository.NotificationRepository;
import com.bf.dsi.repository.TicketRepository;
import com.bf.dsi.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Vérifie périodiquement les invitations restées sans agent affecté au-delà
 * du délai configuré par l'admin ("Paramètres" -> "Délai max sans affectation"),
 * et alerte ADMIN + SECRETAIRE (notification interne + email, selon les
 * réglages activés).
 */
@Service
@RequiredArgsConstructor
public class DelaiAlerteScheduler {

    private static final Logger log = LoggerFactory.getLogger(DelaiAlerteScheduler.class);

    private final InvitationRepository invitationRepo;
    private final TicketRepository ticketRepo;
    private final NotificationRepository notificationRepo;
    private final UtilisateurRepository utilisateurRepo;
    private final AppSettingService appSettingService;
    private final EmailService emailService;

    /** Vérifie toutes les heures. */
    @Scheduled(fixedRate = 60 * 60 * 1000)
    @Transactional
    public void verifierDelaisAffectation() {
        int heures = parseHeures(appSettingService.getDelaiMaxSansAffectation());
        LocalDateTime seuil = LocalDateTime.now().minusHours(heures);

        boolean interneOn = appSettingService.isInternalNotificationEnabled();
        boolean emailOn   = appSettingService.isEmailNotificationEnabled();
        if (!interneOn && !emailOn) return;

        // Destinataires : ADMIN + SECRETAIRE (dédupliqués par id)
        Map<Long, Utilisateur> destinataires = new LinkedHashMap<>();
        utilisateurRepo.findByRoles_Nom("ADMIN").forEach(u -> destinataires.put(u.getUserId(), u));
        utilisateurRepo.findByRoles_Nom("SECRETAIRE").forEach(u -> destinataires.put(u.getUserId(), u));

        traiterInvitationsEnRetard(seuil, heures, destinataires.values(), interneOn, emailOn);
        traiterTicketsEnRetard(seuil, heures, destinataires.values(), interneOn, emailOn);
    }

    private void traiterInvitationsEnRetard(LocalDateTime seuil, int heures,
            java.util.Collection<Utilisateur> destinataires, boolean interneOn, boolean emailOn) {
        List<Invitation> enRetard = invitationRepo.findEnRetardNonAlertees(seuil);
        for (Invitation inv : enRetard) {
            String message = "⏰ Le délai max sans affectation (" + heures + "h) est dépassé pour l'invitation : " + inv.getObjet();
            alerter(destinataires, message, "INVITATION", inv.getId().toString(),
                "DSI Connect — Délai d'affectation dépassé (invitation)", interneOn, emailOn);
            inv.setAlerteDelaiEnvoyee(true);
            invitationRepo.save(inv);
            log.info("Alerte de délai envoyée pour l'invitation #{}", inv.getId());
        }
    }

    private void traiterTicketsEnRetard(LocalDateTime seuil, int heures,
            java.util.Collection<Utilisateur> destinataires, boolean interneOn, boolean emailOn) {
        List<Ticket> enRetard = ticketRepo.findEnRetardNonAlertes(seuil);
        for (Ticket t : enRetard) {
            String resume = t.getDescription() != null && t.getDescription().length() > 60
                ? t.getDescription().substring(0, 60) + "…" : t.getDescription();
            String message = "⏰ Le délai max sans affectation (" + heures + "h) est dépassé pour le ticket #" + t.getId() + " : " + resume;
            alerter(destinataires, message, "TICKET", t.getId().toString(),
                "DSI Connect — Délai d'affectation dépassé (ticket)", interneOn, emailOn);
            t.setAlerteDelaiEnvoyee(true);
            ticketRepo.save(t);
            log.info("Alerte de délai envoyée pour le ticket #{}", t.getId());
        }
    }

    private void alerter(java.util.Collection<Utilisateur> destinataires, String message,
            String categorie, String resourceId, String sujetEmail, boolean interneOn, boolean emailOn) {
        for (Utilisateur dest : destinataires) {
            if (interneOn) {
                notificationRepo.save(Notification.builder()
                    .message(message)
                    .categorie(categorie)
                    .actionLabel("Voir")
                    .resourceId(resourceId)
                    .utilisateur(dest)
                    .build());
            }
            if (emailOn && dest.getEmail() != null) {
                emailService.envoyerNotification(
                    dest.getEmail(),
                    sujetEmail,
                    message + "\n\nConnectez-vous à DSI Connect pour affecter un agent."
                );
            }
        }
    }

    /** Convertit "48h" / "72h" en nombre d'heures. Retombe sur 48 si le format est invalide. */
    private int parseHeures(String delai) {
        if (delai == null) return 48;
        try {
            return Integer.parseInt(delai.trim().toLowerCase().replace("h", ""));
        } catch (NumberFormatException e) {
            return 48;
        }
    }
}