package com.bf.dsi.repository;

import com.bf.dsi.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByUtilisateurUserIdOrderByDateEnvoiDesc(Long userId);
    long countByUtilisateurUserIdAndStatutFalse(Long userId);
    // 🎯 Utilisé pour purger les notifications liées à un ticket (ou toute
    // autre ressource) supprimé, afin d'éviter des notifications "fantômes"
    // pointant vers une ressource qui n'existe plus.
    void deleteByCategorieAndResourceId(String categorie, String resourceId);
}