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

    // 🎯 Utilisée par le tableau de bord pour recalculer les statuts à la
    // volée (calculerStatutAutomatique()) plutôt que de compter sur la colonne
    // "statut" stockée, qui ne se met à jour qu'au moment d'une affectation
    // et peut donc devenir obsolète avec le temps (ex: date de fin dépassée
    // depuis, sans nouvelle affectation).
    java.util.List<Invitation> findByModeCreation(String modeCreation);

    // 🎯 Filtrage par mode de création : "CREER" → page Reçu, "ENREGISTRER" → page Envoyer
    /*Page<Invitation> findByModeCreation(String modeCreation, Pageable pageable);*/

    // 🎯 Invitations sans aucun agent affecté, créées avant le seuil donné,
    // et pour lesquelles aucune alerte de dépassement de délai n'a encore été envoyée.
    @Query("""
        SELECT i FROM Invitation i
        WHERE i.affectations IS EMPTY
        AND i.alerteDelaiEnvoyee = false
        AND i.dateCreation <= :seuil
        """)
    List<Invitation> findEnRetardNonAlertees(@Param("seuil") java.time.LocalDateTime seuil);

    // 🎯 Invitations "reçues" : celles où la structure de l'utilisateur connecté
    // figure parmi les structures invitées (table structure_invitee).
    @Query("""
        SELECT DISTINCT i FROM Invitation i
        JOIN i.structuresInvitees si
        WHERE si.structure.id = :structureId
        ORDER BY i.id DESC
        """)
    List<Invitation> findByStructureInviteeId(@Param("structureId") Long structureId);

    // ── Module Archivage ─────────────────────────────────────────────────
    // 🎯 L'archivage ne concerne que les lettres officielles (mode "CREER")
    // ayant un numéro de référence renseigné.
    // 🎯 CORRECTIF : l'ancienne requête utilisait le motif JPQL
    // "(:param IS NULL OR ...)" combiné à un CONCAT, qui provoque une erreur
    // 500 sur certaines versions d'Hibernate quand le paramètre est null
    // (mauvaise inférence du type du paramètre). On récupère maintenant
    // simplement TOUTES les invitations archivables via une requête dérivée
    // basique (aucun risque d'erreur), et le filtrage par numéro/année se
    // fait en Java, dans InvitationController — voir méthode rechercherArchives().
    List<Invitation> findByModeCreationAndNumeroReferenceIsNotNullOrderByDateCreationDesc(String modeCreation);

    // 🎯 Dernier numéro de référence utilisé (toutes années confondues,
    // numérotation continue) — sert de simple RAPPEL à l'écran de création,
    // la saisie du numéro suivant restant manuelle.
    @Query("""
        SELECT i.numeroReference FROM Invitation i
        WHERE i.modeCreation = 'CREER' AND i.numeroReference IS NOT NULL
        ORDER BY i.dateCreation DESC
        """)
    List<String> findDerniersNumerosReference(Pageable pageable);
}