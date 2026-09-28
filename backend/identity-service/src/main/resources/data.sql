-- Demo seed data. INSERT IGNORE keeps re-runs idempotent.
-- Passwords are BCrypt-encoded: Demo@123

-- Admin account
INSERT IGNORE INTO users (id, email, password_hash, full_name, phone, role, status, email_verified, created_at, updated_at)
VALUES (1, 'admin@veggiepal.com', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', 'VeggiePal Admin', '0900000001', 'ADMIN', 'ACTIVE', true, NOW(), NOW());

-- Demo user accounts
INSERT IGNORE INTO users (id, email, password_hash, full_name, phone, role, status, email_verified, created_at, updated_at)
VALUES (2, 'user@veggiepal.com', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', 'Nguyễn Văn An', '0900000002', 'USER', 'ACTIVE', true, NOW(), NOW());

INSERT IGNORE INTO users (id, email, password_hash, full_name, phone, role, status, email_verified, created_at, updated_at)
VALUES (3, 'user2@veggiepal.com', '$2a$10$dXJ3SW6G7P50lGmMkkmwe.20cQQubK3.HZWzG3YB1tlRy.fqvM/BG', 'Trần Thị Bình', '0900000003', 'USER', 'ACTIVE', true, NOW(), NOW());
