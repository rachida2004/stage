package com.bf.dsi.repository;

import com.bf.dsi.entity.AffectationTicket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AffectationTicketRepository extends JpaRepository<AffectationTicket, Long> {
    
    // Cette méthode permet de vérifier l'existence avant même d'essayer d'insérer
  boolean existsByTicketIdAndAgentUserId(Long ticketId, Long agentId);
}