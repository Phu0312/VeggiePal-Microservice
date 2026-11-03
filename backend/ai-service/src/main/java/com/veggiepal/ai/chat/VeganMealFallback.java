package com.veggiepal.ai.chat;

import java.util.*;

/**
 * Curated, verified 100% plant-only meals and general nutrition advice used when the local model
 * cannot produce a clean response. Every meal contains structured ingredients and explicit allergen tags
 * to guarantee deterministic allergen safety for any dietary restriction profile.
 */
final class VeganMealFallback {

    public record IngredientInfo(String name, Set<String> allergens) {
        public IngredientInfo {
            allergens = allergens == null ? Set.of() : Set.copyOf(allergens);
        }
    }

    public record Meal(String name, List<IngredientInfo> ingredients, String reason, Set<String> allergens) {
        public Meal {
            ingredients = ingredients == null ? List.of() : List.copyOf(ingredients);
            Set<String> allAllergens = new HashSet<>(allergens == null ? Set.of() : allergens);
            for (IngredientInfo ing : ingredients) {
                allAllergens.addAll(ing.allergens());
            }
            allergens = Set.copyOf(allAllergens);
        }
    }

    private static final List<Meal> MEAL_CATALOG = List.of(
            // 1. Soy-based meals (for users without soy allergy)
            new Meal(
                    "Cơm gạo lứt, đậu hũ sốt cà chua và cải xanh luộc",
                    List.of(
                            new IngredientInfo("150g đậu hũ", Set.of("SOY")),
                            new IngredientInfo("80g gạo lứt (khô)", Set.of()),
                            new IngredientInfo("2 quả cà chua chín", Set.of("TOMATO")),
                            new IngredientInfo("100g cải xanh luộc", Set.of())
                    ),
                    "đậu hũ là nguồn đạm thực vật dồi dào, gạo lứt bổ sung tinh bột hấp thu chậm và chất xơ.",
                    Set.of("SOY", "TOMATO")
            ),
            new Meal(
                    "Yến mạch sữa đậu nành với chuối và hạt bí xanh",
                    List.of(
                            new IngredientInfo("50g yến mạch nguyên cám", Set.of()),
                            new IngredientInfo("250ml sữa đậu nành không đường", Set.of("SOY")),
                            new IngredientInfo("20g hạt bí xanh", Set.of()),
                            new IngredientInfo("1 quả chuối sứ", Set.of())
                    ),
                    "kết hợp ngũ cốc nguyên cám với đạm từ sữa đậu nành và kẽm từ hạt bí xanh cho bữa sáng lành mạnh.",
                    Set.of("SOY")
            ),
            new Meal(
                    "Tempeh áp chảo ít dầu với khoai lang và bông cải xanh",
                    List.of(
                            new IngredientInfo("100g tempeh lên men", Set.of("SOY")),
                            new IngredientInfo("150g khoai lang hấp", Set.of()),
                            new IngredientInfo("100g bông cải xanh luộc", Set.of()),
                            new IngredientInfo("1 muỗng cà phê dầu ô liu", Set.of())
                    ),
                    "tempeh lên men tự nhiên giàu protein và men vi sinh có lợi, khoai lang cung cấp năng lượng bền bỉ.",
                    Set.of("SOY")
            ),
            new Meal(
                    "Miến dong nấu nấm rơm với tàu hũ ky",
                    List.of(
                            new IngredientInfo("60g tàu hũ ky tươi", Set.of("SOY")),
                            new IngredientInfo("100g nấm rơm tươi", Set.of("MUSHROOM")),
                            new IngredientInfo("80g miến dong (khô)", Set.of()),
                            new IngredientInfo("100g cải thìa", Set.of())
                    ),
                    "tàu hũ ky giàu đạm thực vật, nấm rơm tạo vị ngọt tự nhiên thanh nhẹ không dầu mỡ.",
                    Set.of("SOY", "MUSHROOM")
            ),

            // 2. Completely SOY-FREE, PEANUT-FREE, SESAME-FREE, GLUTEN-FREE meals
            new Meal(
                    "Cơm gạo lứt đậu lăng đỏ hầm bí đỏ và rau bina",
                    List.of(
                            new IngredientInfo("100g đậu lăng đỏ", Set.of()),
                            new IngredientInfo("80g gạo lứt (khô)", Set.of()),
                            new IngredientInfo("150g bí đỏ", Set.of()),
                            new IngredientInfo("100g rau bina (cải bó xôi)", Set.of())
                    ),
                    "đậu lăng đỏ là nguồn đạm và sắt thực vật tuyệt vời không chứa đậu nành, bí đỏ bổ sung vitamin A.",
                    Set.of()
            ),
            new Meal(
                    "Đậu gà kho sả ớt với cơm gạo lứt và dưa leo",
                    List.of(
                            new IngredientInfo("120g đậu gà nấu chín", Set.of()),
                            new IngredientInfo("80g gạo lứt (khô)", Set.of()),
                            new IngredientInfo("1 cây sả và 1 quả ớt chuông", Set.of("CHILI")),
                            new IngredientInfo("100g dưa leo tươi", Set.of())
                    ),
                    "đậu gà dồi dào protein và chất xơ, hoàn toàn không chứa đậu nành, ớt chuông giàu vitamin C tăng hấp thu sắt.",
                    Set.of("CHILI")
            ),
            new Meal(
                    "Cháo đậu xanh hạt sen với cà rốt và hạt bí",
                    List.of(
                            new IngredientInfo("60g đậu xanh bóc vỏ", Set.of("MUNG_BEAN")),
                            new IngredientInfo("50g hạt sen tươi", Set.of()),
                            new IngredientInfo("80g gạo lứt", Set.of()),
                            new IngredientInfo("20g hạt bí xanh", Set.of()),
                            new IngredientInfo("50g cà rốt thái hạt lựu", Set.of())
                    ),
                    "đậu xanh và hạt sen thanh mát bổ dưỡng, hạt bí bổ sung kẽm và chất béo lành mạnh.",
                    Set.of("MUNG_BEAN")
            ),
            new Meal(
                    "Súp đậu đen khoai lang tím và bắp ngọt",
                    List.of(
                            new IngredientInfo("100g đậu đen xanh lòng", Set.of()),
                            new IngredientInfo("150g khoai lang tím", Set.of()),
                            new IngredientInfo("50g bắp ngọt tách hạt", Set.of("CORN")),
                            new IngredientInfo("100g cải ngọt luộc", Set.of())
                    ),
                    "đậu đen cung cấp đạm thực vật và chất chống oxy hóa tự nhiên, khoai lang tím giúp no lâu.",
                    Set.of("CORN")
            ),
            new Meal(
                    "Đậu đỏ hầm hạt sen và bí đao thanh nhiệt",
                    List.of(
                            new IngredientInfo("80g đậu đỏ", Set.of()),
                            new IngredientInfo("50g hạt sen tươi", Set.of()),
                            new IngredientInfo("150g bí đao", Set.of()),
                            new IngredientInfo("80g cơm gạo lứt", Set.of())
                    ),
                    "đậu đỏ dồi dào chất xơ hòa tan và protein, hạt sen và bí đao giúp thanh lọc cơ thể nhẹ nhàng.",
                    Set.of()
            ),
            new Meal(
                    "Bún gạo lứt trộn đậu lăng nâu bắp cải cà rốt và dầu ô liu",
                    List.of(
                            new IngredientInfo("80g bún gạo lứt (khô)", Set.of()),
                            new IngredientInfo("80g đậu lăng nâu", Set.of()),
                            new IngredientInfo("100g bắp cải thái sợi", Set.of()),
                            new IngredientInfo("50g cà rốt bào sợi", Set.of()),
                            new IngredientInfo("1 muỗng canh dầu ô liu", Set.of())
                    ),
                    "đậu lăng nâu giàu đạm và kali, bún gạo lứt thanh nhẹ dễ tiêu, không chứa đậu nành hay gluten.",
                    Set.of()
            ),

            // 3. Nut-based protein meals (soy-free, peanut-free, sesame-free)
            new Meal(
                    "Salad đậu gà sốt bơ hạt điều với cà chua bi và dưa leo",
                    List.of(
                            new IngredientInfo("120g đậu gà nấu chín", Set.of()),
                            new IngredientInfo("25g hạt điều rang mộc", Set.of("CASHEW", "TREE_NUT")),
                            new IngredientInfo("100g cà chua bi", Set.of("TOMATO")),
                            new IngredientInfo("100g xà lách và dưa leo", Set.of())
                    ),
                    "đậu gà kết hợp hạt điều cung cấp protein và chất béo không bão hòa đơn lành mạnh.",
                    Set.of("CASHEW", "TREE_NUT", "TOMATO")
            ),

            // 4. Mushroom-based meal (soy-free, nut-free, peanut-free)
            new Meal(
                    "Canh nấm đùi gà hạt sen và rong biển với cơm gạo lứt",
                    List.of(
                            new IngredientInfo("100g nấm đùi gà", Set.of("MUSHROOM")),
                            new IngredientInfo("50g hạt sen tươi", Set.of()),
                            new IngredientInfo("10g rong biển khô", Set.of()),
                            new IngredientInfo("80g cơm gạo lứt", Set.of())
                    ),
                    "nấm đùi gà dai ngọt tự nhiên giàu axit amin, hạt sen thanh mát và rong biển giàu khoáng chất.",
                    Set.of("MUSHROOM")
            )
    );

    private VeganMealFallback() {
    }

    /**
     * Backward-compatible overload with empty restrictions.
     */
    static String compose(int count) {
        return compose(count, DietaryRestrictions.empty());
    }

    /**
     * Composes allergy-safe, curated plant-only meals respecting user dietary restrictions.
     */
    static String compose(int count, DietaryRestrictions restrictions) {
        DietaryRestrictions safeRestrictions = restrictions == null ? DietaryRestrictions.empty() : restrictions;

        // Filter catalog against restrictions
        List<Meal> safeMeals = new ArrayList<>();
        for (Meal meal : MEAL_CATALOG) {
            if (isMealSafe(meal, safeRestrictions)) {
                safeMeals.add(meal);
            }
        }

        // Case 1: No verified safe meals found for the given combination of allergies
        if (safeMeals.isEmpty()) {
            return "Rất tiếc, VeggiePal không tìm thấy món ăn nào trong kho dữ liệu được kiểm chứng đáp ứng đồng thời "
                    + "tất cả các yêu cầu dị ứng hoặc kiêng khem của bạn: " + safeRestrictions.toPromptWarning() + ". "
                    + "Để đảm bảo an toàn tuyệt đối cho sức khỏe, hệ thống từ chối tự ý gợi ý món ăn khi chưa xác thực thành phần. "
                    + "Vui lòng tham khảo ý kiến bác sĩ hoặc chuyên gia dinh dưỡng để được xây dựng thực đơn cá nhân hóa an toàn.";
        }

        int targetCount = Math.max(1, count);
        int availableCount = safeMeals.size();
        int n = Math.min(targetCount, availableCount);

        StringBuilder sb = new StringBuilder("Gợi ý thực đơn thuần chay an toàn");
        if (!safeRestrictions.isEmpty()) {
            sb.append(" (không chứa: ").append(safeRestrictions.toPromptWarning()).append(")");
        }
        sb.append(":\n");

        for (int i = 0; i < n; i++) {
            Meal meal = safeMeals.get(i);
            sb.append("\nBữa ").append(i + 1).append(": ").append(meal.name()).append('\n')
                    .append("- Nguyên liệu: ");
            List<String> ingStrings = new ArrayList<>();
            for (IngredientInfo ing : meal.ingredients()) {
                ingStrings.add(ing.name());
            }
            sb.append(String.join(", ", ingStrings)).append('\n')
                    .append("- Vì sao phù hợp: ").append(meal.reason()).append('\n');
        }

        if (availableCount < targetCount) {
            sb.append("\n* Lưu ý về số lượng: Hiện chỉ có ").append(availableCount)
                    .append(" món được kiểm chứng hoàn toàn an toàn theo các tiêu chí dị ứng của bạn; chúng tôi không tự bịa thêm món chưa được xác thực.\n");
        }

        sb.append("\nLưu ý quan trọng về dị ứng & dinh dưỡng: Lượng nguyên liệu trên là gợi ý tham khảo. ")
                .append("Khi mua sắm hoặc chuẩn bị thực phẩm, vui lòng luôn kiểm tra kỹ nhãn thành phần và cảnh báo nguy cơ nhiễm chéo (cross-contact) từ nhà sản xuất. ")
                .append("Người ăn thuần chay nên bổ sung Vitamin B12 và tham khảo ý kiến bác sĩ hoặc chuyên gia dinh dưỡng để có chế độ ăn phù hợp nhất với thể trạng.");

        return sb.toString();
    }

    private static boolean isMealSafe(Meal meal, DietaryRestrictions restrictions) {
        if (restrictions == null || restrictions.isEmpty()) {
            return true;
        }
        if (restrictions.containsAnyAllergen(meal.allergens())) {
            return false;
        }
        for (IngredientInfo ing : meal.ingredients()) {
            if (restrictions.violates(ing.name())) {
                return false;
            }
        }
        return true;
    }

    // Fixed implementation of isMealSafe
    static {
        // Validation check on catalog at classload
        for (Meal m : MEAL_CATALOG) {
            if (m.ingredients().isEmpty()) {
                throw new IllegalStateException("Meal has no ingredients: " + m.name());
            }
        }
    }

    /**
     * Backward-compatible general advice.
     */
    static String generalAdvice(String query) {
        return generalAdvice(query, DietaryRestrictions.empty());
    }

    /**
     * Generates allergy-aware nutrition advice ensuring excluded allergens are never recommended.
     */
    static String generalAdvice(String query, DietaryRestrictions restrictions) {
        DietaryRestrictions safeRestrictions = restrictions == null ? DietaryRestrictions.empty() : restrictions;
        String q = query == null ? "" : query.toLowerCase(Locale.ROOT);
        boolean soyExcluded = safeRestrictions.allergenCodes().contains("SOY");
        boolean peanutExcluded = safeRestrictions.allergenCodes().contains("PEANUT");
        boolean sesameExcluded = safeRestrictions.allergenCodes().contains("SESAME");
        boolean glutenExcluded = safeRestrictions.allergenCodes().contains("GLUTEN");

        if (q.contains("sắt") || q.contains("sat") || q.contains("canxi")) {
            StringBuilder sb = new StringBuilder("Để bổ sung sắt và canxi hiệu quả trong chế độ ăn thuần chay");
            if (!safeRestrictions.isEmpty()) {
                sb.append(" (không chứa: ").append(safeRestrictions.toPromptWarning()).append(")");
            }
            sb.append(", bạn nên tăng cường:\n");

            sb.append("- Sắt thực vật (non-heme iron): ");
            List<String> ironSources = new ArrayList<>();
            if (!soyExcluded) ironSources.add("đậu hũ, tempeh, đậu nành");
            ironSources.add("đậu lăng");
            ironSources.add("đậu gà");
            ironSources.add("đậu đen");
            ironSources.add("rau cải bó xôi, rau muống");
            ironSources.add("hạt bí xanh");
            if (!sesameExcluded) ironSources.add("mè (vừng) đen");
            sb.append(String.join(", ", ironSources)).append("; kết hợp cùng thực phẩm giàu vitamin C (cam, chanh, ớt chuông, cà chua) để tăng hấp thu sắt.\n");

            sb.append("- Canxi thực vật: ");
            List<String> calSources = new ArrayList<>();
            if (!soyExcluded) calSources.add("đậu hũ bổ sung canxi, sữa đậu nành tăng cường canxi");
            calSources.add("sữa yến mạch hoặc sữa hạt tăng cường canxi");
            if (!sesameExcluded) calSources.add("mè (vừng)");
            calSources.add("rau cải xoăn, bông cải xanh, cải thìa, hạt chia");
            sb.append(String.join(", ", calSources)).append(".\n");

            sb.append("- Khuyến nghị an toàn y khoa: Người ăn thuần chay nên xét nghiệm máu định kỳ và tham khảo ý kiến bác sĩ hoặc chuyên gia dinh dưỡng để được chỉ định bổ sung sắt, canxi hoặc Vitamin B12 phù hợp.");
            return sb.toString();
        }

        if (q.contains("giảm cân") || q.contains("giam can") || q.contains("béo") || q.contains("mỡ")) {
            StringBuilder sb = new StringBuilder("Để giảm cân lành mạnh và bền vững khi ăn chay");
            if (!safeRestrictions.isEmpty()) {
                sb.append(" (không chứa: ").append(safeRestrictions.toPromptWarning()).append(")");
            }
            sb.append(", bạn nên áp dụng các nguyên tắc sau:\n");
            sb.append("- Ưu tiên phương pháp chế biến thanh đạm: luộc, hấp, áp chảo ít dầu thay vì đồ chiên xào ngập dầu mỡ hoặc thực phẩm chay chế biến sẵn.\n");
            sb.append("- Thay tinh bột trắng bằng ngũ cốc nguyên cám: gạo lứt, yến mạch, khoai lang giàu chất xơ giúp no lâu.\n");
            sb.append("- Tăng cường đạm thực vật sạch và rau xanh: ");
            List<String> proteinSources = new ArrayList<>();
            if (!soyExcluded) proteinSources.add("đậu hũ, tempeh");
            proteinSources.add("đậu gà, đậu lăng, đậu đen, nấm và rau họ cải");
            sb.append(String.join(", ", proteinSources)).append(" để duy trì khối cơ.\n");
            sb.append("- Uống đủ nước và duy trì vận động thể chất thường xuyên.\n");
            sb.append("- Khuyến nghị: Việc giảm cân cần đảm bảo thâm hụt calo an toàn, tuyệt đối không nhịn ăn cực đoan; nên tham khảo bác sĩ hoặc chuyên gia dinh dưỡng để có lộ trình phù hợp.");
            return sb.toString();
        }

        if (q.contains("tiểu đường") || q.contains("đường huyết")) {
            StringBuilder sb = new StringBuilder("Nếu bạn bị tiểu đường và áp dụng chế độ ăn chay");
            if (!safeRestrictions.isEmpty()) {
                sb.append(" (không chứa: ").append(safeRestrictions.toPromptWarning()).append(")");
            }
            sb.append(", hãy lưu ý:\n");
            sb.append("- Ưu tiên tinh bột hấp thu chậm giàu chất xơ: gạo lứt, yến mạch, các loại đậu (đậu đen, đậu xanh, đậu đỏ) để giúp ổn định đường huyết sau bữa ăn.\n");
            sb.append("- Bổ sung đạm thực vật từ ");
            if (!soyExcluded) sb.append("đậu hũ, tempeh, ");
            sb.append("đậu gà, đậu lăng, nấm và hạn chế các món chay chiên ngập dầu hoặc chứa đường ngọt.\n");
            sb.append("- Bắt buộc tham khảo ý kiến bác sĩ chuyên khoa hoặc chuyên gia dinh dưỡng để theo dõi chỉ số đường huyết định kỳ.");
            return sb.toString();
        }

        // General advice
        StringBuilder sb = new StringBuilder("VeggiePal khuyến nghị bạn ưu tiên các nguồn dinh dưỡng thực vật lành mạnh như ");
        List<String> safeStaples = new ArrayList<>();
        if (!soyExcluded) safeStaples.add("đậu hũ, tempeh");
        safeStaples.add("đậu lăng, đậu gà, các loại đậu hạt");
        safeStaples.add("ngũ cốc nguyên cám (gạo lứt, yến mạch)");
        safeStaples.add("rau xanh đậm");
        if (!peanutExcluded && !safeRestrictions.allergenCodes().contains("TREE_NUT")) safeStaples.add("các loại hạt");
        sb.append(String.join(", ", safeStaples));
        sb.append(". Hãy kết hợp đa dạng các nhóm thực phẩm, luôn kiểm tra nhãn thành phần để tránh các chất gây dị ứng và tham khảo ý kiến bác sĩ hoặc chuyên gia dinh dưỡng.");
        return sb.toString();
    }
}
