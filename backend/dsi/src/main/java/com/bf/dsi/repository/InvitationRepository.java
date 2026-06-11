package com.bf.dsi.repository;

import com.bf.dsi.entity.Invitation;
import com.bf.dsi.enums.StatutInvitation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

public interface InvitationRepository extends JpaRepository<Invitation, Long> {

    @Query(value = """
        SELECT * FROM invitation i
        WHERE (:search IS NULL OR i.objet ILIKE '%' || CAST(:search AS varchar) || '%')
        AND (:statut IS NULL OR i.statut = CAST(:statut AS varchar))
        ORDER BY i.id DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM invitation i
        WHERE (:search IS NULL OR i.objet ILIKE '%' || CAST(:search AS varchar) || '%')
        AND (:statut IS NULL OR i.statut = CAST(:statut AS varchar))
        """,
        nativeQuery = true)
    Page<Invitation> findAllFiltered(
        @Param("search") String search,
        @Param("statut") String statut,
        Pageable pageable);

    long countByStatut(StatutInvitation statut);
}