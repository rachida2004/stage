package com.bf.dsi.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import java.security.Key;
import java.util.Date;
import java.time.Instant;
import io.jsonwebtoken.Jwts;

import javax.crypto.SecretKey;

@Component
public class JwtUtil {
    @Value("${jwt.secret}")
    private String secret;
    @Value("${jwt.expiration}")
    private long expiration;

    private Key getKey() {
        return Keys.hmacShaKeyFor(secret.getBytes());
    }
public String generate(String email, String role) {
    return Jwts.builder()
            .subject(email)                           // Remplace .setSubject()
            .claim("role", role)                      // Inchangé
            .issuedAt(Date.from(Instant.now()))       // Remplace .setIssuedAt()
            .expiration(Date.from(Instant.now().plusMillis(expiration))) // Remplace .setExpiration()
            .signWith(getKey())                       // Signature simplifiée (l'algorithme est déduit de la clé)
            .compact();
}

    public String extractEmail(String token) {
    return Jwts.parser()
            .verifyWith((SecretKey) getKey()) // Vérifie la signature avec la clé
            .build()
            .parseSignedClaims(token)         // Remplace parseClaimsJws
            .getPayload()                     // Remplace getBody
            .getSubject();
}

public boolean validate(String token) {
    try {
        Jwts.parser()
            .verifyWith((SecretKey) getKey())
            .build()
            .parseSignedClaims(token);
        return true;
    } catch (Exception e) { 
        return false; 
    }
}
}
