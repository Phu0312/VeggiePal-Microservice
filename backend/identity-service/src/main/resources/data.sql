-- ============================================================
-- VEGGIEPAL IDENTITY SERVICE - SAMPLE USERS
-- ============================================================
-- Matches seeded author_id / user_id (1, 2, 3) in blog-service and recipe-service.
-- Passwords are BCrypt-encoded: password

INSERT INTO users (id, email, password_hash, full_name, phone, role, status, email_verified, created_at, updated_at)
SELECT 1, 'admin@veggiepal.com', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', 'VeggiePal Admin', '0900000001', 'ADMIN', 'ACTIVE', TRUE, NOW(), NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE id = 1 OR email = 'admin@veggiepal.com'
);

INSERT INTO users (id, email, password_hash, full_name, phone, role, status, email_verified, created_at, updated_at)
SELECT 2, 'user@veggiepal.com', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', 'Nguyễn Văn An', '0900000002', 'USER', 'ACTIVE', TRUE, NOW(), NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE id = 2 OR email = 'user@veggiepal.com'
);

INSERT INTO users (id, email, password_hash, full_name, phone, role, status, email_verified, created_at, updated_at)
SELECT 3, 'user2@veggiepal.com', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', 'Trần Thị Bình', '0900000003', 'USER', 'ACTIVE', TRUE, NOW(), NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE id = 3 OR email = 'user2@veggiepal.com'
);

