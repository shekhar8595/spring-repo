package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String home() {
        return "Spring Boot CI/CD with GKE is Running..working now, thanks!";
    }

    @GetMapping("/health")
    public String health() {
        return "Application is Healthy!";
    }
}
