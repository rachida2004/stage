package com.bf.dsi.dto;

import lombok.Data;
@Data
public class RegisterRequest {
    private String nom;
    private String prenom;
    private String email;
    private String password;
    private String telephone;
    private String structure;
    private String service;
    private String identifiantUnique;
    private String role;
}
