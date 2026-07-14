package com.bf.dsi.services;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.List;

/**
 * Parse un Delta JSON flutter_quill (corps de la lettre d'invitation) en une
 * liste de blocs (paragraphes) exploitables aussi bien par l'export PDF
 * (iText) que par l'export Word (Apache POI).
 *
 * Ne gère que les attributs réellement disponibles dans la toolbar de
 * l'éditeur (voir invitation_screen.dart -> QuillSimpleToolbarConfig) :
 * gras, italique, souligné, alignement, titres (header 1-3), listes
 * (puces / numérotée). Les embeds (images) dans le corps de texte sont
 * ignorés — les pièces jointes sont gérées séparément.
 */
public class QuillDeltaParser {

    public static class Run {
        public final String text;
        public final boolean bold, italic, underline;
        public Run(String text, boolean bold, boolean italic, boolean underline) {
            this.text = text; this.bold = bold; this.italic = italic; this.underline = underline;
        }
    }

    public static class Block {
        public final List<Run> runs = new ArrayList<>();
        public String align = "left";     // left | center | right | justify
        public Integer header;            // 1, 2, 3 ou null
        public String listType;           // "bullet" | "ordered" | null
    }

    /** Renvoie une liste vide (jamais null) si le JSON est vide/invalide. */
    public static List<Block> parse(String deltaJson) {
        List<Block> blocks = new ArrayList<>();
        if (deltaJson == null || deltaJson.isBlank()) return blocks;

        try {
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(deltaJson);
            JsonNode ops = root.isArray() ? root : root.path("ops");
            if (!ops.isArray()) return blocks;

            Block current = new Block();
            for (JsonNode op : ops) {
                JsonNode insertNode = op.path("insert");
                if (!insertNode.isTextual()) continue; // embeds (images) ignorés ici

                String insert = insertNode.asText();
                JsonNode attrs = op.path("attributes");
                boolean bold = attrs.path("bold").asBoolean(false);
                boolean italic = attrs.path("italic").asBoolean(false);
                boolean underline = attrs.path("underline").asBoolean(false);

                String[] parts = insert.split("\n", -1);
                for (int i = 0; i < parts.length; i++) {
                    if (!parts[i].isEmpty()) {
                        current.runs.add(new Run(parts[i], bold, italic, underline));
                    }
                    boolean estDernierMorceau = i == parts.length - 1;
                    if (!estDernierMorceau) {
                        // On clôt un bloc ici. Les attributs de BLOC (list/header/align)
                        // ne sont fiables que quand Quill a émis un op dédié "\n"
                        // (comportement standard de flutter_quill).
                        if (insert.equals("\n")) {
                            if (attrs.has("align")) current.align = attrs.path("align").asText("left");
                            if (attrs.has("header")) current.header = attrs.path("header").asInt();
                            if (attrs.has("list")) current.listType = attrs.path("list").asText(null);
                        }
                        blocks.add(current);
                        current = new Block();
                    }
                }
            }
            if (!current.runs.isEmpty()) blocks.add(current);
        } catch (Exception ignored) {
            // JSON invalide : les appelants retombent sur le texte brut (getContenu()).
        }
        return blocks;
    }
}