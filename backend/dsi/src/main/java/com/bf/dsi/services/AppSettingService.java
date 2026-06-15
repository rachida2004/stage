package com.bf.dsi.services;

import com.bf.dsi.repository.AppSettingRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AppSettingService {

    @Autowired
    private AppSettingRepository appSettingRepository;

    /**
     * Vérifie si les notifications par email sont activées globalement.
     */
    public boolean isEmailNotificationEnabled() {
        return appSettingRepository.findById("settings_notif_email")
                .map(setting -> Boolean.parseBoolean(setting.getValeur()))
                .orElse(true); // true par défaut si la clé n'existe pas encore
    }

    /**
     * Vérifie si les notifications internes (Alertes) sont activées globalement.
     */
    public boolean isInternalNotificationEnabled() {
        return appSettingRepository.findById("settings_notif_interne")
                .map(setting -> Boolean.parseBoolean(setting.getValeur()))
                .orElse(true); // true par défaut
    }

    /**
     * Récupère la valeur du délai maximum sans affectation (ex: "48h", "72h").
     */
    public String getDelaiMaxSansAffectation() {
        return appSettingRepository.findById("settings_delai")
                .map(setting -> setting.getValeur())
                .orElse("48h"); // "48h" par défaut
    }
}
