package com.bf.dsi.dto;

import lombok.Data;
import java.time.LocalDate;
@Data
public class InvitationRequest {
    private String objet;
    private LocalDate dateDebut;
    private LocalDate dateFin;
    private Integer nombreParticipants;
    private String lieu;
    private String visibilite;
    private Long structureEmettriceId;
    private String statut;
}
