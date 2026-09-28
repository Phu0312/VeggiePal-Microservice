package com.veggiepal.nutrition.service;

import java.util.*;

import org.springframework.stereotype.Service;

import com.veggiepal.nutrition.entity.*;
import com.veggiepal.nutrition.exception.AppException;
import com.veggiepal.nutrition.exception.ErrorCode;
import com.veggiepal.nutrition.repository.*;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@Slf4j
public class ChatService {

    private static final int GUEST_MAX_QUESTIONS = 3;

    ChatConversationRepository chatConversationRepository;
    ChatMessageRepository chatMessageRepository;
    GuestAiUsageRepository guestAiUsageRepository;
    AiOperationLogService aiOperationLogService;

    /** Local demo AI chat provider - deterministic keyword-based responses */
    private static final Map<String, String> DEMO_RESPONSES = new LinkedHashMap<>();

    static {
        DEMO_RESPONSES.put("bmi", "BMI (Body Mass Index) là chỉ số khối cơ thể, được tính bằng công thức: BMI = cân nặng (kg) / chiều cao (m)². "
                + "BMI < 18.5: Thiếu cân | 18.5-24.9: Bình thường | 25-29.9: Thừa cân | ≥30: Béo phì. "
                + "⚕️ Thông tin này chỉ mang tính tham khảo và không thay thế tư vấn từ bác sĩ hoặc chuyên gia dinh dưỡng.");

        DEMO_RESPONSES.put("protein", "Nguồn protein thực vật tốt nhất bao gồm: đậu hũ (tofu) ~8g/100g, tempeh ~19g/100g, "
                + "đậu lăng (lentils) ~9g/100g, đậu gà (chickpeas) ~9g/100g, edamame ~11g/100g, "
                + "quinoa ~4g/100g, hạt chia ~17g/100g, và bơ đậu phộng ~25g/100g. "
                + "⚕️ Thông tin này chỉ mang tính tham khảo và không thay thế tư vấn từ bác sĩ hoặc chuyên gia dinh dưỡng.");

        DEMO_RESPONSES.put("đậu hũ", "Đậu hũ (tofu) là nguồn protein thực vật tuyệt vời! 100g đậu hũ chứa khoảng 8g protein, "
                + "4.8g chất béo, 76 calories. Đậu hũ còn chứa canxi, sắt, và các axit amin thiết yếu. "
                + "Có thể chế biến: chiên, xào, nấu canh, làm salad, hoặc smoothie. "
                + "⚕️ Thông tin này chỉ mang tính tham khảo và không thay thế tư vấn từ bác sĩ hoặc chuyên gia dinh dưỡng.");

        DEMO_RESPONSES.put("sữa", "Các loại sữa thực vật thay thế sữa bò phổ biến: sữa đậu nành (giàu protein), "
                + "sữa hạnh nhân (ít calo), sữa yến mạch (nhiều chất xơ), sữa dừa (béo ngậy), sữa gạo (nhẹ, dễ tiêu). "
                + "Lưu ý chọn loại bổ sung canxi và vitamin D. "
                + "⚕️ Thông tin này chỉ mang tính tham khảo và không thay thế tư vấn từ bác sĩ hoặc chuyên gia dinh dưỡng.");

        DEMO_RESPONSES.put("egg", "In vegan cooking, common egg replacements include: flax eggs (1 tbsp ground flax + 3 tbsp water), "
                + "chia eggs, mashed banana, applesauce, silken tofu, aquafaba (chickpea liquid), and commercial egg replacers. "
                + "⚕️ This information is for reference only and does not replace advice from a doctor or nutritionist.");

        DEMO_RESPONSES.put("vegan", "A well-planned vegan diet provides all essential nutrients. Key considerations: "
                + "Protein (tofu, legumes, quinoa), B12 (fortified foods or supplements), Iron (leafy greens, lentils), "
                + "Omega-3 (flaxseeds, walnuts, algae oil), Calcium (fortified plant milk, broccoli), Zinc (pumpkin seeds, chickpeas). "
                + "⚕️ This information is for reference only and does not replace advice from a doctor or nutritionist.");

        DEMO_RESPONSES.put("ăn chay", "Chế độ ăn chay (vegan) cung cấp đầy đủ dinh dưỡng nếu được lên kế hoạch tốt. "
                + "Cần chú ý bổ sung: Protein (đậu hũ, đậu lăng, quinoa), Vitamin B12 (thực phẩm tăng cường), "
                + "Sắt (rau lá xanh đậm, đậu lăng), Omega-3 (hạt lanh, quả óc chó), Canxi (sữa thực vật tăng cường). "
                + "⚕️ Thông tin này chỉ mang tính tham khảo và không thay thế tư vấn từ bác sĩ hoặc chuyên gia dinh dưỡng.");

        DEMO_RESPONSES.put("calories", "Calorie needs vary by age, sex, and activity level. General guidelines: "
                + "Sedentary adults: 1,600-2,400 cal/day. Active adults: 2,000-3,000 cal/day. "
                + "For weight loss, a deficit of 500 cal/day leads to ~0.5kg/week loss. "
                + "For muscle gain, a surplus of 300-500 cal/day is recommended. "
                + "⚕️ This information is for reference only and does not replace advice from a doctor or nutritionist.");

        DEMO_RESPONSES.put("giảm cân", "Để giảm cân lành mạnh với chế độ ăn chay: giảm 500 calo/ngày so với nhu cầu, "
                + "ăn nhiều rau xanh và trái cây, chọn ngũ cốc nguyên hạt, hạn chế đường và thực phẩm chế biến sẵn, "
                + "uống đủ nước (2-3 lít/ngày), kết hợp tập thể dục. "
                + "⚕️ Thông tin này chỉ mang tính tham khảo và không thay thế tư vấn từ bác sĩ hoặc chuyên gia dinh dưỡng.");
    }

    private static final String DEFAULT_RESPONSE = "Cảm ơn bạn đã hỏi! Đây là một câu hỏi thú vị về dinh dưỡng thực vật. "
            + "VeggiePal khuyên bạn nên tham khảo ý kiến chuyên gia dinh dưỡng để có câu trả lời phù hợp nhất với tình trạng sức khỏe của bạn. "
            + "Bạn có thể hỏi tôi về: BMI, protein thực vật, đậu hũ, sữa thực vật, thay thế trứng, calories, hoặc giảm cân. "
            + "⚕️ Thông tin này chỉ mang tính tham khảo và không thay thế tư vấn từ bác sĩ hoặc chuyên gia dinh dưỡng.";

    // ===================== GUEST CHAT =====================

    public Map<String, Object> guestChat(String guestId, String question) {

        long startTime = System.currentTimeMillis();

        GuestAiUsage usage = guestAiUsageRepository.findByGuestId(guestId)
                .orElseGet(() -> {
                    GuestAiUsage newUsage = GuestAiUsage.builder()
                            .guestId(guestId)
                            .questionCount(0)
                            .build();
                    return guestAiUsageRepository.save(newUsage);
                });

        if (usage.getQuestionCount() >= GUEST_MAX_QUESTIONS) {
            throw new AppException(ErrorCode.GUEST_AI_QUOTA_EXCEEDED);
        }

        String answer = generateLocalResponse(question);

        usage.setQuestionCount(usage.getQuestionCount() + 1);
        guestAiUsageRepository.save(usage);

        long duration = System.currentTimeMillis() - startTime;
        aiOperationLogService.logOperation("CHAT", "LOCAL_DEMO", "SUCCESS", duration, null);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("question", question);
        result.put("answer", answer);
        result.put("questionsUsed", usage.getQuestionCount());
        result.put("questionsRemaining", GUEST_MAX_QUESTIONS - usage.getQuestionCount());

        return result;
    }

    // ===================== AUTHENTICATED CHAT =====================

    public Map<String, Object> authenticatedChat(Long userId, Long conversationId, String message) {

        long startTime = System.currentTimeMillis();

        ChatConversation conversation;
        if (conversationId != null) {
            conversation = chatConversationRepository.findByIdAndUserId(conversationId, userId)
                    .orElseThrow(() -> new AppException(ErrorCode.CONVERSATION_NOT_FOUND));
        } else {
            // Create new conversation
            String title = message.length() > 50 ? message.substring(0, 50) + "..." : message;
            conversation = ChatConversation.builder()
                    .userId(userId)
                    .title(title)
                    .build();
            conversation = chatConversationRepository.save(conversation);
        }

        // Save user message
        ChatMessage userMessage = ChatMessage.builder()
                .conversationId(conversation.getId())
                .role("USER")
                .content(message)
                .build();
        chatMessageRepository.save(userMessage);

        // Generate response
        String answer = generateLocalResponse(message);

        // Save assistant message
        ChatMessage assistantMessage = ChatMessage.builder()
                .conversationId(conversation.getId())
                .role("ASSISTANT")
                .content(answer)
                .build();
        chatMessageRepository.save(assistantMessage);

        // Update conversation timestamp
        conversation.setUpdatedAt(java.time.LocalDateTime.now());
        chatConversationRepository.save(conversation);

        long duration = System.currentTimeMillis() - startTime;
        aiOperationLogService.logOperation("CHAT", "LOCAL_DEMO", "SUCCESS", duration, null);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("conversationId", conversation.getId());
        result.put("question", message);
        result.put("answer", answer);

        return result;
    }

    public List<ChatConversation> getConversations(Long userId) {
        return chatConversationRepository.findByUserIdOrderByUpdatedAtDesc(userId);
    }

    public Map<String, Object> getConversation(Long userId, Long conversationId) {

        ChatConversation conversation = chatConversationRepository.findByIdAndUserId(conversationId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.CONVERSATION_NOT_FOUND));

        List<ChatMessage> messages = chatMessageRepository.findByConversationIdOrderByCreatedAtAsc(conversationId);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", conversation.getId());
        result.put("title", conversation.getTitle());
        result.put("createdAt", conversation.getCreatedAt());
        result.put("messages", messages.stream().map(msg -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", msg.getId());
            m.put("role", msg.getRole());
            m.put("content", msg.getContent());
            m.put("createdAt", msg.getCreatedAt());
            return m;
        }).toList());

        return result;
    }

    // ===================== LOCAL DEMO AI PROVIDER =====================

    private String generateLocalResponse(String question) {

        String lower = question.toLowerCase();

        for (Map.Entry<String, String> entry : DEMO_RESPONSES.entrySet()) {
            if (lower.contains(entry.getKey())) {
                return entry.getValue();
            }
        }

        return DEFAULT_RESPONSE;
    }
}
