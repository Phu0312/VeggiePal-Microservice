import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import { Info, Loader2, TriangleAlert, X } from "lucide-react";

import { buttonVariants } from "@/components/ui/variants/button-variants";
import AppHeader from "@/shared/components/AppHeader";
import AppFooter from "@/shared/components/AppFooter";
import { useChatbot } from "@/features/chatbot/hooks/useChatbot";
import { useMySubscription } from "@/features/payment/hooks/useMySubscription";
import { PLAN_DETAILS } from "@/features/payment/utils/paymentFormat";
import ChatSidebar from "@/features/chatbot/components/ChatSidebar";
import ChatHeader from "@/features/chatbot/components/ChatHeader";
import ChatMessage from "@/features/chatbot/components/ChatMessage";
import ChatEmptyState from "@/features/chatbot/components/ChatEmptyState";
import TypingIndicator from "@/features/chatbot/components/TypingIndicator";
import ChatComposer from "@/features/chatbot/components/ChatComposer";

/**
 * Trang chatbot dinh dưỡng (/chatbot).
 * Dùng ai-service thật qua @/features/chatbot/api/chatbotApi.js:
 * - Đã đăng nhập: lịch sử hội thoại lưu ở BE (sidebar, nhiều lượt).
 * - Chưa đăng nhập: chế độ dùng thử, không có sidebar, giới hạn số lượt hỏi.
 */
export default function ChatbotScreen() {
  const {
    isAuthenticated,
    sessions,
    activeSessionId,
    activeMessages,
    loadingMessages,
    sending,
    remainingRequests,
    errorMessage,
    dismissError,
    selectSession,
    startNewSession,
    deleteSession,
    sendMessage,
  } = useChatbot();

  const { subscription } = useMySubscription();
  const [draft, setDraft] = useState("");
  const [collapsed, setCollapsed] = useState(false);
  const scrollRef = useRef(null);

  const activeSession = sessions.find((s) => s.id === activeSessionId);

  useEffect(() => {
    scrollRef.current?.scrollTo({
      top: scrollRef.current.scrollHeight,
      behavior: "smooth",
    });
  }, [activeMessages, sending]);

  const handleSend = async () => {
    const text = draft;
    setDraft("");
    const ok = await sendMessage(text);
    // Gửi lỗi thì trả lại nội dung để người dùng không phải gõ lại.
    if (!ok) setDraft((current) => current || text);
  };

  return (
    <div className="min-h-dvh bg-canvas">
      <AppHeader />

      <main className="mx-auto w-full max-w-[1280px] px-4 py-4 sm:px-6 lg:px-8">
        <div className="flex h-[75dvh] min-h-[620px] max-h-[960px] overflow-hidden rounded-3xl border border-border bg-card shadow-sm">
          {isAuthenticated && (
            <ChatSidebar
              sessions={sessions}
              activeSessionId={activeSessionId}
              collapsed={collapsed}
              onToggleCollapsed={() => setCollapsed((c) => !c)}
              onSelectSession={selectSession}
              onNewChat={startNewSession}
              onDeleteSession={deleteSession}
            />
          )}

          <div className="flex min-w-0 flex-1 flex-col">
            <ChatHeader
              title={activeSession?.title ?? "Cuộc trò chuyện dinh dưỡng"}
              onNewChat={startNewSession}
            />

            {!isAuthenticated && (
              <div className="flex flex-wrap items-center justify-between gap-2 border-b border-border bg-brand-soft px-6 py-2.5 text-xs text-brand">
                <span>
                  Bạn đang dùng thử
                  {remainingRequests != null &&
                    ` — còn ${remainingRequests} lượt hỏi`}
                  . Đăng nhập để lưu lịch sử và hỏi nhiều hơn.
                </span>
                <Link
                  to="/login"
                  state={{ from: { pathname: "/chatbot" } }}
                  className={buttonVariants({ variant: "default", size: "sm" })}
                >
                  Đăng nhập
                </Link>
              </div>
            )}

            {isAuthenticated && subscription && (
              <div className="flex flex-wrap items-center justify-between gap-2 border-b border-border bg-brand-soft px-6 py-2.5 text-xs text-brand">
                <span>
                  {PLAN_DETAILS[subscription.planCode]?.name ?? subscription.planCode}
                  {" · "}
                  {remainingRequests != null
                    ? `còn ${remainingRequests}/${subscription.chatPerDay} lượt hỏi hôm nay`
                    : `tối đa ${subscription.chatPerDay} lượt hỏi mỗi ngày`}
                </span>
                {subscription.planCode !== "PRO" && (
                  <Link to="/pricing" className="font-semibold underline underline-offset-2">
                    Nâng cấp để hỏi nhiều hơn
                  </Link>
                )}
              </div>
            )}

            {errorMessage && (
              <div
                role="alert"
                className="mx-6 mt-4 flex items-start gap-2 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive"
              >
                <TriangleAlert className="mt-0.5 h-4 w-4 shrink-0" />
                <span className="flex-1">
                  {errorMessage.includes("/pricing") ? (
                    <>
                      {errorMessage.split("/pricing")[0]}
                      <Link to="/pricing" className="font-bold underline hover:opacity-85">
                        /pricing
                      </Link>
                      {errorMessage.split("/pricing")[1]}
                    </>
                  ) : (
                    errorMessage
                  )}
                </span>
                <button
                  type="button"
                  onClick={dismissError}
                  aria-label="Đóng thông báo lỗi"
                  className="shrink-0 rounded-full p-0.5 transition hover:bg-destructive/10"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            )}

            <div ref={scrollRef} className="flex-1 overflow-y-auto px-6 py-6">
              <div className="mx-auto flex w-full max-w-3xl flex-col gap-6">
                {loadingMessages ? (
                  <div className="flex items-center justify-center gap-2 py-24 text-sm text-subtle">
                    <Loader2 className="h-5 w-5 animate-spin text-brand" />
                    Đang tải cuộc trò chuyện…
                  </div>
                ) : activeMessages.length === 0 ? (
                  <ChatEmptyState />
                ) : (
                  activeMessages.map((message) => (
                    <ChatMessage key={message.id} message={message} />
                  ))
                )}
                {sending && <TypingIndicator />}
              </div>
            </div>

            <ChatComposer
              value={draft}
              onChange={setDraft}
              onSend={handleSend}
              disabled={sending || loadingMessages}
            />

            <p className="flex items-center justify-center gap-1.5 px-6 pb-4 text-center text-xs text-subtle">
              <Info className="h-3.5 w-3.5 shrink-0" />
              Trợ lý cung cấp thông tin tham khảo về ăn chay và dinh dưỡng,
              không thay thế tư vấn y tế chuyên nghiệp. Hãy hỏi ý kiến chuyên
              gia khi có vấn đề sức khỏe.
            </p>
          </div>
        </div>
      </main>

      <AppFooter />
    </div>
  );
}
