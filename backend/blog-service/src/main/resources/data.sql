-- Demo seed data for blog-service. INSERT IGNORE keeps re-runs idempotent.

-- Categories
INSERT IGNORE INTO categories (id, parent_id, type, name, display_order, is_active, created_at, updated_at) VALUES
(1, NULL, 'FOOD_TYPE', 'Món chay truyền thống', 1, 1, NOW(), NOW()),
(2, NULL, 'FOOD_TYPE', 'Món chay Á - Âu hiện đại', 2, 1, NOW(), NOW()),
(3, NULL, 'RECIPE_TYPE', 'Món nước & Canh súp', 1, 1, NOW(), NOW()),
(4, NULL, 'RECIPE_TYPE', 'Món kho & Món xào', 2, 1, NOW(), NOW()),
(5, NULL, 'RECIPE_TYPE', 'Bánh & Đồ ngọt thuần chay', 3, 1, NOW(), NOW()),
(6, NULL, 'RECIPE_TYPE', 'Sữa hạt & Đồ uống dinh dưỡng', 4, 1, NOW(), NOW()),
(7, 3, 'RECIPE_TYPE', 'Phở & Bún chay', 1, 1, NOW(), NOW()),
(8, 4, 'RECIPE_TYPE', 'Nấm kho & Đậu kho', 1, 1, NOW(), NOW());

-- Blogs
INSERT IGNORE INTO blogs (id, author_id, category_id, title, content, status, view_count, vote_score, published_at, created_at, updated_at) VALUES
(1, 2, 7, 'Bí quyết nấu Phở Chay ngọt nước dùng từ rau củ tự nhiên', 'Nấu phở chay ngon quan trọng nhất là nồi nước dùng thanh trong và ngọt tự nhiên. Sử dụng củ cải trắng, lê, táo, mía lau cùng hồi quế thảo quả nướng thơm, ninh nhỏ lửa 1 tiếng sẽ cho ra hương vị phở chay đậm đà không thua kém bất kỳ món phở truyền thống nào.', 'PUBLISHED', 120, 15, NOW(), NOW(), NOW()),
(2, 2, 8, 'Cách làm Nấm Rơm kho tiêu chuẩn vị cơm mẹ nấu', 'Nấm rơm tươi cắt gốc, ngâm nước muối loãng rồi để thật ráo. Ướp nước tương ngon, chút đường thốt nốt, tiêu đập dập và ớt hiểm. Kho trong nồi đất với lửa liu riu đến khi nước sốt keo lại bám đều quanh từng tai nấm dai ngọt.', 'PUBLISHED', 85, 8, NOW(), NOW(), NOW()),
(3, 3, 6, '5 công thức làm sữa hạt béo ngậy cho bữa sáng tràn đầy năng lượng', 'Sữa hạt thuần chay là lựa chọn lý tưởng cho người ăn chay. Hãy cùng VeggiePal khám phá công thức sữa hạt điều mè đen, sữa yến mạch hạt sen, và sữa hạnh nhân óc chó cực kỳ bổ dưỡng và dễ làm ngay tại nhà.', 'PUBLISHED', 210, 25, NOW(), NOW(), NOW()),
(4, 2, 1, 'Bài viết kiểm duyệt: Chia sẻ món ăn cuối tuần', 'Món ăn gia đình cuối tuần được nhiều người yêu thích, trong bài viết có nhắc đến thử nghiệm làm món sốt thịt gà và hải sản...', 'PENDING', 5, 0, NULL, NOW(), NOW()),
(5, 3, 5, 'Bánh chuối nướng yến mạch cốt dừa thơm lừng gian bếp', 'Món bánh chuối nướng healthy không dùng đường tinh luyện, không bơ sữa động vật. Vị ngọt tự nhiên của chuối sứ chín kết hợp cùng vị béo thơm ngậy của cốt dừa và độ dẻo bùi của yến mạch cán dẹt.', 'PUBLISHED', 95, 12, NOW(), NOW(), NOW());

-- Comments
INSERT IGNORE INTO comments (id, author_id, target_type, target_id, parent_comment_id, content, status, created_at, updated_at) VALUES
(1, 3, 'BLOG', 1, NULL, 'Nước dùng rau củ ninh với mía lau ngọt thanh tuyệt vời lắm bạn ơi!', 'VISIBLE', NOW(), NOW()),
(2, 2, 'BLOG', 3, NULL, 'Mình đã thử công thức sữa hạt điều yến mạch, cả nhà ai cũng khen ngon.', 'VISIBLE', NOW(), NOW());

-- Videos
INSERT IGNORE INTO videos (id, author_id, category_id, title, description, video_url, thumbnail_url, duration_seconds, summary, status, view_count, vote_score, published_at, created_at, updated_at) VALUES
(1, 2, 7, 'Hướng dẫn nấu Bún Riêu Chay thơm lừng góc bếp', 'Video hướng dẫn chi tiết cách làm riêu từ đậu phụ non và nấm rơm, nước lèo chua thanh đậm đà chuẩn vị miền Bắc.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c', 480, '📋 **TÓM TẮT VIDEO NẤU ĂN THUẦN CHAY (VEGGIEPAL AI):**\n\n🎯 **Chủ đề**: Bún Riêu Chay thơm ngon chuẩn vị\n🥦 **Nguyên liệu**: Đậu phụ non, nấm rơm, cà chua chín, me chua, bún tươi, rau kinh giới tía tô.\n👩‍🍳 **Các bước**: 1. Xào cà chua tạo màu. 2. Làm riêu từ đậu non xay nhuyễn. 3. Nấu nước dùng chua thanh ngọt dịu.', 'PUBLISHED', 150, 20, NOW(), NOW(), NOW()),
(2, 3, 6, 'Tự làm sữa hạt Macca Yến Mạch sánh mịn trong 15 phút', 'Chia sẻ bí quyết xay và nấu sữa hạt không bị tách nước, giữ trọn vẹn dưỡng chất omega-3.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'https://images.unsplash.com/photo-1563227812-0ea4c22e6cc8', 360, '📋 **TÓM TẮT VIDEO NẤU ĂN THUẦN CHAY (VEGGIEPAL AI):**\n\n🎯 **Chủ đề**: Sữa hạt Macca Yến Mạch\n🥦 **Nguyên liệu**: Hạt mắc ca tươi, yến mạch cán dẹt, chà là tạo ngọt.\n👩‍🍳 **Các bước**: Ngâm hạt 20 phút, xay cùng nước ấm và lọc qua túi vải mịn.', 'PUBLISHED', 90, 14, NOW(), NOW(), NOW()),
(3, 2, 8, 'Món Đậu Hũ Sốt Cà Chua Nấm Đông Cô siêu hao cơm', 'Công thức làm món đậu phụ rán vỏ giòn ruột mềm sốt nấm thơm nức mũi cho bữa cơm gia đình.', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd', 420, '📋 **TÓM TẮT VIDEO NẤU ĂN THUẦN CHAY (VEGGIEPAL AI):**\n\n🎯 **Chủ đề**: Đậu Hũ Sốt Cà Chua Nấm Đông Cô\n🥦 **Nguyên liệu**: Đậu hũ chiên vàng, nấm đông cô ngâm nở, sốt cà chua nguyên chất.\n👩‍🍳 **Các bước**: Xào nấm chín tới, om đậu phụ với nước sốt sánh mịn trong 10 phút.', 'PUBLISHED', 75, 11, NOW(), NOW(), NOW());

-- Moderation Cases
INSERT IGNORE INTO moderation_cases (id, target_type, target_id, author_id, content_snippet, matched_keywords, decision, reason, reviewed_by, reviewed_at, created_at) VALUES
(1, 'BLOG', 4, 2, 'Bài viết kiểm duyệt: Chia sẻ món ăn cuối tuần - trong bài viết có nhắc đến thử nghiệm làm món sốt thịt gà và hải sản...', 'thịt gà, hải sản', 'PENDING', 'Phát hiện nguyên liệu không thuần chay (thịt gà, hải sản). Cần quản trị viên kiểm duyệt trước khi công khai.', NULL, NULL, NOW());
