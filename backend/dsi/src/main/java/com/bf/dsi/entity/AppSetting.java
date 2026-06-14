package com.bf.dsi.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "app_settings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppSetting {
    @Id
    private String cle; // Ex: "notificationsEmail", "delaiMaxSansAffectation"
    
    @Column(nullable = false)
    private String valeur; // On stocke tout en String (ex: "true", "48h", "Français")
}