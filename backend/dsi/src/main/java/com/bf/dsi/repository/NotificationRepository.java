package com.bf.dsi.repository;

import com.bf.dsi.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByUtilisateurUserIdOrderByDateEnvoiDesc(Long userId);
    long countByUtilisateurUserIdAndStatutFalse(Long userId);
}
