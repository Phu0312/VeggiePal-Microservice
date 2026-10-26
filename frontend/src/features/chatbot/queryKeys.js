// Khóa cache React Query của feature chatbot.
// Tách "conversations" (danh sách) và "conversation" (chi tiết) để invalidate
// danh sách không làm mất cache chi tiết từng cuộc trò chuyện.
export const chatbotKeys = {
  conversations: ["chatbot", "conversations"],
  conversation: (id) => ["chatbot", "conversation", id],
};
