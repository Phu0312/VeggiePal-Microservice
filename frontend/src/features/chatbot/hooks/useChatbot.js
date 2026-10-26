import { useCallback, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  selectIsAuthenticated,
  useAuthStore,
} from "@/features/auth/store/authStore";
import {
  createGuestSession,
  deleteConversation,
  fetchConversationMessages,
  fetchConversations,
  sendChatMessage,
  sendGuestMessage,
} from "@/features/chatbot/api/chatbotApi";
import { chatbotKeys } from "@/features/chatbot/queryKeys";
import {
  createLocalId,
  getChatErrorMessage,
  isGuestSessionValid,
  pickNextActiveSessionId,
} from "@/features/chatbot/utils/chatUtils";

// Phiên khách lưu sessionStorage: đóng tab là mất, khớp với "mỗi khách 1 phiên".
const GUEST_STORAGE_KEY = "veggiepal_guest_chat";

function readGuestSession() {
  try {
    return JSON.parse(sessionStorage.getItem(GUEST_STORAGE_KEY));
  } catch {
    return null;
  }
}

function clearGuestSession() {
  sessionStorage.removeItem(GUEST_STORAGE_KEY);
}

// Dùng lại phiên còn hạn để không tốn thêm lượt tạo phiên (BE giới hạn theo IP/ngày).
// forceNew = true: bỏ qua phiên đang lưu trong sessionStorage và tạo phiên hoàn toàn mới.
async function ensureGuestSession(forceNew = false) {
  if (!forceNew) {
    const stored = readGuestSession();
    if (isGuestSessionValid(stored)) return stored.guestSession;
  }
  const created = await createGuestSession();
  sessionStorage.setItem(GUEST_STORAGE_KEY, JSON.stringify(created));
  return created.guestSession;
}

/**
 * State + hành động cho trang chatbot.
 * - Đã đăng nhập: hội thoại lưu ở BE (danh sách / chi tiết / gửi / xoá).
 *   `activeSessionId = null` nghĩa là đoạn chat mới — BE tự tạo hội thoại ở tin nhắn đầu.
 * - Chưa đăng nhập: chế độ khách, tin nhắn chỉ giữ trong bộ nhớ, bị giới hạn lượt hỏi.
 */
export function useChatbot() {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  const queryClient = useQueryClient();

  const [activeSessionId, setActiveSessionId] = useState(null);
  // Tin nhắn user hiển thị ngay trong lúc chờ AI trả lời (chưa có id từ server).
  const [optimistic, setOptimistic] = useState(null);
  const [guestMessages, setGuestMessages] = useState([]);
  const [remainingRequests, setRemainingRequests] = useState(null);
  const [errorMessage, setErrorMessage] = useState("");

  const sessionsQuery = useQuery({
    queryKey: chatbotKeys.conversations,
    queryFn: fetchConversations,
    enabled: isAuthenticated,
  });

  const messagesQuery = useQuery({
    queryKey: chatbotKeys.conversation(activeSessionId),
    queryFn: () => fetchConversationMessages(activeSessionId),
    enabled: isAuthenticated && activeSessionId != null,
  });

  const memberSend = useMutation({
    mutationFn: async (variables) => {
      const reply = await sendChatMessage(variables);
      // Đồng bộ lại trong mutationFn để dấu "đang trả lời" giữ tới khi tin nhắn
      // thật đã có trong cache (tránh nháy mất tin nhắn giữa hai lần render).
      try {
        await Promise.all([
          queryClient.fetchQuery({
            queryKey: chatbotKeys.conversation(reply.conversationId),
            queryFn: () => fetchConversationMessages(reply.conversationId),
            staleTime: 0,
          }),
          queryClient.invalidateQueries({ queryKey: chatbotKeys.conversations }),
        ]);
      } catch {
        // Lỗi đồng bộ không làm mất câu trả lời: query chi tiết sẽ tự tải lại.
      }
      return reply;
    },
  });

  const guestSend = useMutation({
    mutationFn: async (message) => {
      let guestSession = await ensureGuestSession();
      try {
        return await sendGuestMessage({ guestSession, message });
      } catch (error) {
        // Khi chat khách gặp lỗi 401 (hoặc mã 6001): tự động tạo session mới và gửi lại một lần
        const status = error.status ?? error.response?.status;
        const code = error.code ?? error.response?.data?.code;
        if (status === 401 || code === 6001) {
          clearGuestSession();
          try {
            guestSession = await ensureGuestSession(true);
            return await sendGuestMessage({ guestSession, message });
          } catch (retryError) {
            const retryStatus = retryError.status ?? retryError.response?.status;
            const retryCode = retryError.code ?? retryError.response?.data?.code;
            if (retryStatus === 401 || retryCode === 6001) {
              clearGuestSession();
            }
            throw retryError;
          }
        }
        throw error;
      }
    },
  });

  const deleteMutation = useMutation({ mutationFn: deleteConversation });

  const sessions = useMemo(() => sessionsQuery.data ?? [], [sessionsQuery.data]);

  const selectSession = useCallback((sessionId) => {
    setActiveSessionId(sessionId);
    setErrorMessage("");
  }, []);

  const startNewSession = useCallback(() => {
    setActiveSessionId(null);
    setOptimistic(null);
    setGuestMessages([]);
    setErrorMessage("");
  }, []);

  const deleteSession = useCallback(
    async (sessionId) => {
      setErrorMessage("");
      try {
        await deleteMutation.mutateAsync(sessionId);
        setActiveSessionId(
          pickNextActiveSessionId(sessions, sessionId, activeSessionId)
        );
        queryClient.removeQueries({
          queryKey: chatbotKeys.conversation(sessionId),
        });
      } catch (error) {
        setErrorMessage(getChatErrorMessage(error));
      } finally {
        // Luôn tải lại danh sách để khớp BE (kể cả khi xoá lỗi vì đã bị xoá ở nơi khác).
        queryClient.invalidateQueries({ queryKey: chatbotKeys.conversations });
      }
    },
    [deleteMutation, sessions, activeSessionId, queryClient]
  );

  const sending = memberSend.isPending || guestSend.isPending;

  /** Trả về true nếu gửi thành công (để UI biết có cần trả lại nội dung đã gõ). */
  const sendMessage = useCallback(
    async (text) => {
      const trimmed = text.trim();
      if (!trimmed || sending) return false;

      setErrorMessage("");
      const userMessage = {
        id: createLocalId("msg"),
        role: "user",
        content: trimmed,
        createdAt: new Date().toISOString(),
      };

      if (isAuthenticated) {
        setOptimistic({ conversationId: activeSessionId, message: userMessage });
        try {
          const reply = await memberSend.mutateAsync({
            conversationId: activeSessionId,
            message: trimmed,
          });
          setRemainingRequests(reply.remainingRequests);
          setActiveSessionId(reply.conversationId);
          return true;
        } catch (error) {
          setErrorMessage(getChatErrorMessage(error));
          return false;
        } finally {
          setOptimistic(null);
        }
      }

      setGuestMessages((prev) => [...prev, userMessage]);
      try {
        const reply = await guestSend.mutateAsync(trimmed);
        setRemainingRequests(reply.remainingRequests);
        setGuestMessages((prev) => [
          ...prev,
          {
            id: createLocalId("msg"),
            role: "assistant",
            content: reply.answer,
            createdAt: new Date().toISOString(),
          },
        ]);
        return true;
      } catch (error) {
        setGuestMessages((prev) => prev.filter((m) => m.id !== userMessage.id));
        setErrorMessage(getChatErrorMessage(error, { guest: true }));
        return false;
      }
    },
    [isAuthenticated, activeSessionId, sending, memberSend, guestSend]
  );

  const activeMessages = useMemo(() => {
    if (!isAuthenticated) return guestMessages;
    const saved = messagesQuery.data ?? [];
    return optimistic && optimistic.conversationId === activeSessionId
      ? [...saved, optimistic.message]
      : saved;
  }, [isAuthenticated, guestMessages, messagesQuery.data, optimistic, activeSessionId]);

  const dismissError = useCallback(() => setErrorMessage(""), []);

  const loadingMessages =
    isAuthenticated && activeSessionId != null && messagesQuery.isLoading;

  // Lỗi tải dữ liệu (danh sách / chi tiết) gộp chung vào banner lỗi.
  const queryError = sessionsQuery.error ?? messagesQuery.error;
  const displayError =
    errorMessage || (queryError ? getChatErrorMessage(queryError) : "");

  return {
    isAuthenticated,
    sessions,
    activeSessionId,
    activeMessages,
    loadingSessions: isAuthenticated && sessionsQuery.isLoading,
    loadingMessages,
    sending,
    remainingRequests,
    errorMessage: displayError,
    dismissError,
    selectSession,
    startNewSession,
    deleteSession,
    sendMessage,
  };
}
