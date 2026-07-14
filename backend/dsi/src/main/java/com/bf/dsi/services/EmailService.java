package com.bf.dsi.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

/**
 * Envoi réel des emails de notification (invitations, tickets...).
 * Séparé de AuthController (qui gère uniquement les emails de réinitialisation
 * de mot de passe) pour centraliser la logique de notification.
 */
@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    @Autowired
    private JavaMailSender mailSender;

    /**
     * Envoie un email de notification. Asynchrone pour ne jamais ralentir ou
     * faire échouer la requête HTTP appelante si le SMTP est lent/indisponible.
     * Les erreurs sont journalisées, jamais propagées.
     */
    private static final java.util.regex.Pattern EMAIL_REGEX =
        java.util.regex.Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    @Async
    public void envoyerNotification(String destinataire, String sujet, String message) {
        if (destinataire == null || destinataire.isBlank()) {
            log.warn("Email de notification NON envoyé : destinataire vide ou null (sujet : {})", sujet);
            return;
        }
        if (!EMAIL_REGEX.matcher(destinataire.trim()).matches()) {
            log.warn("Email de notification NON envoyé : adresse invalide '{}' (sujet : {})", destinataire, sujet);
            return;
        }
        try {
            SimpleMailMessage mail = new SimpleMailMessage();
            mail.setTo(destinataire.trim());
            mail.setSubject(sujet);
            mail.setText(message);
            mailSender.send(mail);
            log.info("Email de notification envoyé à {}", destinataire);
        } catch (Exception e) {
            log.error("Échec d'envoi d'email de notification à {} : {}", destinataire, e.getMessage(), e);
        }
    }
}