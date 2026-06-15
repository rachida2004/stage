package com.bf.dsi.dto;

import lombok.Data;

@Data
public class NotificationSettingsDto {
    private boolean emailEnabled;
    private boolean internalEnabled;
    private String delaiMaxSansAffectation;
    private String langue;
}