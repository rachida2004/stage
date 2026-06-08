package com.bf.dsi.repository;

import com.bf.dsi.entity.StructureInvitee;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface StructureInviteeRepository extends JpaRepository<StructureInvitee, Long> {
    List<StructureInvitee> findByInvitationId(Long invitationId);
}