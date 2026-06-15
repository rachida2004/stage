package com.bf.dsi.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.bf.dsi.entity.Service;
import com.bf.dsi.repository.ServiceRepository;
import java.util.List;

@RestController
@RequestMapping("/api/services")
public class ServiceController {
    
    @Autowired
    private ServiceRepository repository;

    @GetMapping
    public List<Service> listerServices() {
        return repository.findAll();
    }

    @PostMapping
    public Service ajouterService(@RequestBody Service service) {
        return repository.save(service);
    }

    @PutMapping("/{id}")
    public Service modifierService(@PathVariable Long id, @RequestBody Service service) {
        service.setId(id);
        return repository.save(service);
    }

    @DeleteMapping("/{id}")
    public boolean supprimerService(@PathVariable Long id) {
        if (repository.existsById(id)) {
            repository.deleteById(id);
            return true;
        }
        return false;
    }
}