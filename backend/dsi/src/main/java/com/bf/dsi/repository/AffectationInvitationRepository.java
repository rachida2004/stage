package com.bf.dsi.repository;

import com.bf.dsi.entity.AffectationInvitation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
public interface AffectationInvitationRepository extends JpaRepository<AffectationInvitation, Long> {

    @Modifying
    @Transactional
    @Query("DELETE FROM AffectationInvitation a WHERE a.invitation.id = :invitationId")
    void deleteByInvitationId(@Param("invitationId") Long invitationId);
}