package com.bf.dsi.services;

import com.bf.dsi.entity.AffectationInvitation;
import com.bf.dsi.entity.Invitation;
import com.bf.dsi.entity.Notification;
import com.bf.dsi.entity.Utilisateur;
import com.bf.dsi.repository.AffectationInvitationRepository;
import com.bf.dsi.repository.InvitationRepository;
import com.bf.dsi.repository.NotificationRepository;
import com.bf.dsi.repository.UtilisateurRepository;
import com.bf.dsi.services.AppSettingService; // 🎯 1. Importation du service de configuration
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class InvitationServiceImpl implements InvitationService {

    private final InvitationRepository invitationRepo;
    private final AffectationInvitationRepository affectationRepo;
    private final UtilisateurRepository utilisateurRepo;
    private final NotificationRepository notificationRepo;
    private final AppSettingService appSettingService; // 🎯 2. Injection automatique grâce à @RequiredArgsConstructor

    @Override
    public Invitation affecterMembres(Long invId, List<Long> agentIds, Long responsableId) {
        // 1. Récupération de l'invitation
        Invitation inv = invitationRepo.findById(invId)
            .orElseThrow(() -> new RuntimeException("Invitation introuvable avec l'ID : " + invId));

        // 2. Nettoyage des anciennes affectations
        if (inv.getAffectations() != null) {
            affectationRepo.deleteAll(inv.getAffectations());
            inv.getAffectations().clear();
        } else {
            inv.setAffectations(new ArrayList<>());
        }
        
        affectationRepo.flush();

        // 3. Traitement des nouvelles affectations
        if (agentIds != null && !agentIds.isEmpty()) {
            for (Long agentId : agentIds) {
                Utilisateur agent = utilisateurRepo.findById(agentId)
                    .orElseThrow(() -> new RuntimeException("Agent introuvable avec l'ID : " + agentId));

                boolean estResponsable = agentId.equals(responsableId);

                AffectationInvitation aff = AffectationInvitation.builder()
                    .invitation(inv)
                    .agent(agent)
                    .responsablePrincipal(estResponsable)
                    .build();
                
                affectationRepo.save(aff);
                inv.getAffectations().add(aff);

                // 🎯 3. Condition : On vérifie si l'admin a coché "Notifications internes"
                if (appSettingService.isInternalNotificationEnabled()) {
                    String messageNotif = estResponsable 
                        ? "⚠️ Vous êtes RESPONSABLE PRINCIPAL pour l'invitation : " + inv.getObjet()
                        : "Vous avez été affecté à l'invitation : " + inv.getObjet();

                    Notification notif = Notification.builder()
                        .message(messageNotif)
                        .categorie("INVITATION")
                        .actionLabel("Voir")
                        .resourceId(invId.toString())
                        .utilisateur(agent)
                        .build();
                    
                    notificationRepo.save(notif);
                }

                // 🎯 4. Condition : On vérifie si l'admin a coché "Notifications par email"
                if (appSettingService.isEmailNotificationEnabled()) {
                    // Si tu branches ton service mail plus tard, le déclenchement se fera ici
                    // emailService.sendInvitationMail(agent, inv, estResponsable);
                    System.out.println("LOG EMAIL : Notification par courriel pour l'agent ID " + agentId);
                }
            }
        }

        // 4. Utilisation directe de la méthode de ton entité
        inv.setStatut(inv.calculerStatutAutomatique());
        
        // 5. Sauvegarde finale
        return invitationRepo.save(inv);
    }
}