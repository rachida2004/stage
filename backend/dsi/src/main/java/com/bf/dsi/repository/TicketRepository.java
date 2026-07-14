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
    // 🎯 :createurId est optionnel — null pour les rôles internes (voient tout),
    // renseigné pour un USAGER afin qu'il ne voie QUE ses propres tickets
    // ("créer un ticket et suivre son état", rien d'autre).
    @Query("""
        SELECT DISTINCT t FROM Ticket t
        WHERE (:search IS NULL OR LOWER(CAST(t.description AS string)) LIKE LOWER(CONCAT('%', CAST(:search AS string), '%')))
        AND (:statut IS NULL OR t.statut = :statut)
        AND (:priorite IS NULL OR t.priorite = :priorite)
        AND (:createurId IS NULL OR t.createur.userId = :createurId)
        ORDER BY t.id DESC
        """)
    Page<Ticket> findAllFiltered(
        @Param("search") String search,
        @Param("statut") StatutTicket statut,
        @Param("priorite") Priorite priorite,
        @Param("createurId") Long createurId,
        Pageable pageable);

    @Query("SELECT COUNT(t) FROM Ticket t WHERE t.statut <> com.bf.dsi.enums.StatutTicket.FERME")
    long countOpen();

    long countByStatutNot(StatutTicket statut);

    // 🎯 Tickets sans aucun agent affecté, créés avant le seuil donné,
    // et pour lesquels aucune alerte de dépassement de délai n'a encore été envoyée.
    @Query("""
        SELECT t FROM Ticket t
        WHERE t.affectations IS EMPTY
        AND t.alerteDelaiEnvoyee = false
        AND t.dateCreation <= :seuil
        """)
    java.util.List<Ticket> findEnRetardNonAlertes(@Param("seuil") java.time.LocalDateTime seuil);
}