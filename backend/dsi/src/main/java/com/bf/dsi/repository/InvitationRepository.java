package com.bf.dsi.repository;

import com.bf.dsi.entity.Invitation;
import com.bf.dsi.enums.StatutInvitation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.util.List;

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
    Page<Invitation> findByModeCreationOrderByIdDesc(String modeCreation, Pageable pageable);

    // 🎯 Comptages utilisés par le tableau de bord : on exclut les invitations
    // créées via "Créer" (lettres officielles), qui ne doivent pas être
    // comptabilisées ni affichées sur le tableau de bord.
    long countByModeCreation(String modeCreation);
    long countByStatutAndModeCreation(StatutInvitation statut, String modeCreation);

    // 🎯 Filtrage par mode de création : "CREER" → page Reçu, "ENREGISTRER" → page Envoyer
    /*Page<Invitation> findByModeCreation(String modeCreation, Pageable pageable);*/

    // 🎯 Invitations "reçues" : celles où la structure de l'utilisateur connecté
    // figure parmi les structures invitées (table structure_invitee).
    @Query("""
        SELECT DISTINCT i FROM Invitation i
        JOIN i.structuresInvitees si
        WHERE si.structure.id = :structureId
        ORDER BY i.id DESC
        """)
    List<Invitation> findByStructureInviteeId(@Param("structureId") Long structureId);
}