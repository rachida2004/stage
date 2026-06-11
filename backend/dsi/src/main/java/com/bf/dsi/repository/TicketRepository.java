package com.bf.dsi.repository;

import com.bf.dsi.entity.Ticket;
import com.bf.dsi.enums.Priorite;
import com.bf.dsi.enums.StatutTicket;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TicketRepository extends JpaRepository<Ticket, Long> {

    // Requête corrigée avec CAST explicite pour éviter l'erreur lower(bytea)
    @Query("""
        SELECT DISTINCT t FROM Ticket t
        WHERE (:search IS NULL OR LOWER(CAST(t.description AS string)) LIKE LOWER(CONCAT('%', CAST(:search AS string), '%')))
        AND (:statut IS NULL OR t.statut = :statut)
        AND (:priorite IS NULL OR t.priorite = :priorite)
        ORDER BY t.id DESC
        """)
    Page<Ticket> findAllFiltered(
        @Param("search") String search,
        @Param("statut") StatutTicket statut,
        @Param("priorite") Priorite priorite,
        Pageable pageable);

    @Query("SELECT COUNT(t) FROM Ticket t WHERE t.statut <> com.bf.dsi.enums.StatutTicket.FERME")
    long countOpen();

    long countByStatutNot(StatutTicket statut);
}