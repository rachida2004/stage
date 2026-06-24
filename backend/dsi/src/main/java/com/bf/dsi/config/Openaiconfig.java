package com.bf.dsi.config;

 
import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;
 
/**
 * Active le bouton "Authorize" dans Swagger UI pour pouvoir tester les
 * routes protégées (/api/invitations, /api/tickets, ...) avec un token JWT.
 *
 * Utilisation dans Swagger UI :
 *  1) POST /api/auth/login -> récupérer le champ "token" de la réponse
 *  2) Cliquer sur le bouton "Authorize" (cadenas en haut de la page)
 *  3) Coller le token (juste le token, sans le préfixe "Bearer ")
 *  4) Cliquer sur "Authorize" puis "Close"
 *  5) Toutes les requêtes "Try it out" incluront désormais l'en-tête
 *     Authorization: Bearer <token>
 */
@Configuration
@OpenAPIDefinition(security = @SecurityRequirement(name = "bearerAuth"))
@SecurityScheme(
    name = "bearerAuth",
    type = SecuritySchemeType.HTTP,
    scheme = "bearer",
    bearerFormat = "JWT"
)
public class Openaiconfig {
    
}
