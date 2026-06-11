package com.bf.dsi.services;

import com.bf.dsi.entity.Invitation;
import java.util.List;

public interface InvitationService {
    Invitation affecterMembres(Long invId, List<Long> agentIds, Long responsableId);
}