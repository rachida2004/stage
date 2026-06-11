package com.bf.dsi.repository;

import com.bf.dsi.entity.Communication;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
public interface CommunicationRepository extends JpaRepository<Communication, Long> {
    List<Communication> findByTicketIdOrderByDateAsc(Long ticketId);
}
