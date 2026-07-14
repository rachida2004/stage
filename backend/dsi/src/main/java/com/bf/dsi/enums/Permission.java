package com.bf.dsi.enums;


public enum Permission {
    CREER_TICKET,             // Créer un ticket
    AFFECTER_INVITATION,      // Affecter un agent à une invitation
    AFFECTER_TICKET,          // Affecter un agent à un ticket
    ENREGISTRER_INVITATION,   // Créer / enregistrer / modifier / générer une lettre d'invitation
    VOIR_NOTIFICATION,        // Consulter ses notifications (écran Alertes)
    RECEVOIR_NOTIFICATION,    // Recevoir des notifications (interne + email) pour les événements le concernant
    MODIFIER_PARAMETRE,        // Modifier les paramètres globaux de l'application (Admin > Paramètres)
    GERER_TICKETS
}