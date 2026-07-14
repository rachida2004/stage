package com.bf.dsi.dto;

import lombok.Data;

@Data
public class NotificationSettingsDto {
    private boolean notificationsEmail;
    private boolean notificationsInternes;
    private String delaiMaxSansAffectation;
    private String langue;
}