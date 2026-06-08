package com.bf.dsi.services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.*;
import java.nio.file.*;
import java.util.UUID;

@Service
public class FileStorageService {
    @Value("${upload.dir:./uploads}")
    private String uploadDir;

    public String store(MultipartFile file, String subDir) {
        try {
            Path dir = Paths.get(uploadDir, subDir);
            Files.createDirectories(dir);
            String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
            Path dest = dir.resolve(filename);
            Files.copy(file.getInputStream(), dest, StandardCopyOption.REPLACE_EXISTING);
            return subDir + "/" + filename;
        } catch (IOException e) {
            throw new RuntimeException("Erreur lors du stockage du fichier: " + e.getMessage(), e);
        }
    }

    public byte[] load(String relativePath) {
        try {
            Path path = Paths.get(uploadDir, relativePath);
            return Files.readAllBytes(path);
        } catch (IOException e) {
            throw new RuntimeException("Fichier introuvable: " + relativePath, e);
        }
    }
}
