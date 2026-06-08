package com.bf.dsi.dto;

import lombok.Data;

@Data
public class TicketRequest {
    private String description;
    private String structure;
    private String priority;    // FAIBLE, MOYENNE, ELEVEE, URGENTE
    private String attachmentName;
    private Long createurId;    // Ajout : ID de l'utilisateur qui crée le ticket
}