import apiClient from "@/shared/api/apiClient";
import {
  toMessageItem,
  toSessionItem,
} from "@/features/chatbot/utils/chatUtils";

/**
 * API chatbot — ai-service qua gateway (baseURL đã có /api nên đường dẫn bắt
 * đầu từ /ai/...). Response envelope: { code, message, result }.
 */

// Gắn status + code vào Error để UI dịch sang tiếng Việt (BE trả message tiếng Anh).
function unwrap(res, fallbackMessage) {
  if (res.status >= 400) {
    const error = new Error(res.data?.message || fallbackMessage);
    error.status = res.status;
    error.code = res.data?.code;
    throw error;
  }
  return res.data?.result;
}

/** POST /ai/chat/guest-sessions — tạo phiên dùng thử (mỗi khách 1 phiên). */
export async function createGuestSession() {
  const res = await apiClient.post("/ai/chat/guest-sessions");
  return unwrap(res, "Không tạo được phiên dùng thử");
}

/** POST /ai/chat/guest — hỏi AI khi chưa đăng nhập (giới hạn lượt/ngày). */
export async function sendGuestMessage({ guestSession, message }) {
  const res = await apiClient.post("/ai/chat/guest", { guestSession, message });
  return unwrap(res, "Không gửi được câu hỏi");
}

/**
 * POST /ai/chat — hỏi AI khi đã đăng nhập. `conversationId` rỗng = BE tự tạo
 * hội thoại mới, có giá trị = nối tiếp hội thoại cũ (nhiều lượt).
 */
export async function sendChatMessage({ conversationId, message }) {
  const body = conversationId ? { conversationId, message } : { message };
  const res = await apiClient.post("/ai/chat", body);
  return unwrap(res, "Không gửi được câu hỏi");
}

/** GET /ai/chat/conversations — danh sách hội thoại (mới nhất trước). */
export async function fetchConversations() {
  const res = await apiClient.get("/ai/chat/conversations");
  const list = unwrap(res, "Không tải được lịch sử trò chuyện") ?? [];
  return list.map(toSessionItem);
}

/** GET /ai/chat/conversations/:id — tin nhắn của một hội thoại. */
export async function fetchConversationMessages(conversationId) {
  const res = await apiClient.get(`/ai/chat/conversations/${conversationId}`);
  const detail = unwrap(res, "Không tải được cuộc trò chuyện");
  return (detail?.messages ?? []).map(toMessageItem);
}

/** DELETE /ai/chat/conversations/:id */
export async function deleteConversation(conversationId) {
  const res = await apiClient.delete(`/ai/chat/conversations/${conversationId}`);
  unwrap(res, "Không xoá được cuộc trò chuyện");
}
