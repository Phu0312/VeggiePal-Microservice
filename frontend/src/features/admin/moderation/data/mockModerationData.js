/**
 * Mock data dùng để kiểm thử giao diện và chức năng Admin Kiểm duyệt nội dung (AI Moderation).
 * Cấu trúc tương thích 100% với ModerationResponse từ AI-Service:
 * { caseId, contentType, externalContentId, authorId, content, decision, categories, reason, confidence, createdAt }
 */
export const MOCK_MODERATION_CASES = [
  {
    caseId: 101,
    contentType: "BLOG",
    externalContentId: 42,
    authorId: 15,
    content: "Chia sẻ phương pháp nhịn ăn 21 ngày chỉ uống nước kèm thuốc thảo dược gia truyền thanh lọc mỡ thừa cấp tốc... Đặt mua thuốc liên hệ Zalo 0987xxx để nhận ưu đãi hôm nay!",
    decision: "REVIEW_REQUIRED",
    categories: ["spam", "misinformation_dangerous"],
    reason: "Bài viết chứa liên kết lạ và quảng cáo thực phẩm chức năng giảm cân cấp tốc không rõ nguồn gốc kiểm định y tế.",
    confidence: 0.78,
    createdAt: new Date(Date.now() - 3600 * 1000 * 2).toISOString(), // 2 giờ trước
  },
  {
    caseId: 102,
    contentType: "COMMENT",
    externalContentId: 580,
    authorId: 28,
    content: "Nấu ăn dở tệ thế này mà cũng bày đặt đăng bài, lừa đảo cộng đồng ăn chay... lũ ăn chay giả tạo cút khỏi nền tảng đi!",
    decision: "REVIEW_REQUIRED",
    categories: ["harassment", "hate"],
    reason: "Bình luận chứa ngôn từ thù địch, xúc phạm danh dự người chia sẻ công thức và kích động tranh cãi độc hại.",
    confidence: 0.82,
    createdAt: new Date(Date.now() - 3600 * 1000 * 5).toISOString(), // 5 giờ trước
  },
  {
    caseId: 103,
    contentType: "VIDEO",
    externalContentId: 19,
    authorId: 8,
    content: "Video clip hướng dẫn các cảnh quay bắt nhốt và sơ chế động vật hoang dã trái phép gây phản cảm cho cộng đồng.",
    decision: "REVIEW_REQUIRED",
    categories: ["violence"],
    reason: "AI nhận diện khung hình video có yếu tố phản cảm, hành vi ngược đãi vật nuôi trước khi chế biến món ăn.",
    confidence: 0.74,
    createdAt: new Date(Date.now() - 3600 * 1000 * 12).toISOString(), // 12 giờ trước
  },
  {
    caseId: 104,
    contentType: "BLOG",
    externalContentId: 87,
    authorId: 44,
    content: "Cung cấp các loại nấm thần kinh và thảo mộc thư giãn kích thích não bộ nhập khẩu... Cam kết giao kín đáo, quét mã QR tham gia nhóm Telegram kín đặt hàng...",
    decision: "REVIEW_REQUIRED",
    categories: ["illegal", "spam"],
    reason: "Nội dung dẫn link mua bán các chất kích thích bị cấm dưới danh nghĩa thảo mộc tự nhiên.",
    confidence: 0.81,
    createdAt: new Date(Date.now() - 3600 * 1000 * 24).toISOString(), // 1 ngày trước
  },
  {
    caseId: 105,
    contentType: "COMMENT",
    externalContentId: 1024,
    authorId: 63,
    content: "Cổng game đổi thưởng uy tín số 1 Việt Nam, nạp 1 tặng 1 nhận ngay 500k trải nghiệm tại nhacaiuytin888.com!!",
    decision: "REVIEW_REQUIRED",
    categories: ["spam"],
    reason: "Tần suất đăng lặp lại cùng một đoạn tin quảng cáo cờ bạc trực tuyến qua nhiều bài viết khác nhau.",
    confidence: 0.84,
    createdAt: new Date(Date.now() - 3600 * 1000 * 36).toISOString(), // 1.5 ngày trước
  },
];
