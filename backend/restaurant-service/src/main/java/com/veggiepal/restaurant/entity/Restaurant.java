package com.veggiepal.restaurant.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
@Entity
@Table(name = "restaurants")
public class Restaurant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @Column(nullable = false)
    String name;

    @Column(nullable = false)
    String address;

    @Column(nullable = false)
    Double latitude;

    @Column(nullable = false)
    Double longitude;

    @Column(columnDefinition = "TEXT")
    String description;

    @Column(nullable = false)
    String type;

    @Column(name = "supported_dishes", columnDefinition = "TEXT")
    String supportedDishes;

    @Column(name = "created_at", nullable = false, updatable = false)
    LocalDateTime createdAt;

    @PrePersist
    void prePersist() {
        createdAt = LocalDateTime.now();
    }
}
