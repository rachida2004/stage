package com.bf.dsi.dto;

import lombok.Data;
@Data
public class RegisterRequest {
    private String nom;
    private String prenom;
    private String email;
    private String password;
    private String telephone;
    // 🎯 CORRECTIF : le formulaire "Créer un compte" (login_screen.dart)
    // envoie structureId/serviceId (les IDs sélectionnés dans les dropdowns),
    // pas des noms. structure/service (noms) sont gardés pour compatibilité
    // avec d'éventuels autres appelants, mais l'inscription normale passe
    // désormais par les ID ci-dessous.
    private String structure;
    private String service;
    private Long structureId;
    private Long serviceId;
    private String identifiantUnique;
    private String role;
}