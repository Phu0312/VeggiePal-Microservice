package com.veggiepal.ai.chat;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import com.veggiepal.ai.mealplan.AllergenDetector;

/**
 * Deterministic quality checks for a chat answer produced by the small local model.
 * It flags degenerate output (truncation, repetition loops, duplicated meals, oversized
 * ingredient lists, foreign scripts) and affirmative animal ingredients, and can trim
 * repeated lines. Detection is structural (counts of repeated items, lines and word
 * n-grams), so a term that legitimately appears a few times is not flagged.
 */
final class ChatOutputGuard {

    enum Issue {
        TRUNCATED, REPETITION_LOOP, DUPLICATE_MEALS, EXCESSIVE_LIST, FOREIGN_SCRIPT, ANIMAL_INGREDIENT,
        INVENTED_NUTRITION, TOO_MANY_ITEMS, TEMPLATE_LEAK, INCOMPLETE_MEAL, DISCOURAGES_SUPPLEMENTS,
        ALLERGEN_VIOLATION;

        /** Soft issues justify one retry but are accepted if the retry still has them. */
        boolean isSoft() {
            return this == TOO_MANY_ITEMS;
        }
    }

    private static final Pattern NUTRITION_FIGURE = Pattern.compile(
            "\\d+([.,]\\d+)?\\s?(kcal|calo|calories)|\\d+([.,]\\d+)?\\s?g\\s+(protein|đạm|tinh bột|carb|chất xơ|chất béo|fat)",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
    private static final Pattern LIST_ITEM_LINE = Pattern.compile("(?m)^\\s*(\\d+[.)]|[-*•])\\s+\\S");
    private static final int MAX_LIST_ITEMS = 7;
    private static final Pattern DISCOURAGES_SUPPLEMENT_PATTERN = Pattern.compile(
            "(không|đừng|tránh)\\s+(nên\\s+)?(sử dụng|dùng|uống|bổ sung)[^.\\n]{0,30}(viên uống|men dinh dưỡng|thực phẩm bổ sung)"
                    + "|thay vì\\s+(dùng\\s+|uống\\s+)?(viên uống|thực phẩm bổ sung)",
            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
    private static final Pattern MEAL_HEADING_NO_NAME = Pattern.compile(
            "(?im)^\\s*(?:\\d+[.)]\\s*)?(?:\\*\\*)?(?:bữa|bua)\\s*\\d+\\s*:?\\s*(?:\\*\\*)?\\s*$");

    private static final Pattern ITEM_SPLIT = Pattern.compile("[\\n,;]");
    private static final Pattern BULLET_PREFIX = Pattern.compile("^[\\s\\-*•·]*(\\d+[.)]\\s+)?");
    private static final Pattern WORD_SPLIT = Pattern.compile("[^\\p{L}\\p{N}]+");
    private static final Pattern CJK = Pattern.compile("[\\u3040-\\u30ff\\u3400-\\u9fff\\uac00-\\ud7af]");
    private static final Pattern QUANTITY = Pattern.compile("\\b\\d+([.,]\\d+)?\\s?(g|gr|gam|kg|ml|l|lít)\\b",
            Pattern.CASE_INSENSITIVE);
    private static final Pattern MEAL_HEADING = Pattern.compile(
            "(?im)^\\s*(?:\\d+[.)]\\s*)?(?:\\*\\*)?(?:bữa|món|bua|mon|thực đơn)\\b[^\\n]*$");
    private static final Pattern VEGAN_OR_NEGATION_CONTEXT = Pattern.compile(
            "(không|tránh|thay thế|thay vì|kiêng|loại bỏ|chay|giả|thực vật|vegan|nguồn gốc thực vật)");

    private static final List<Pattern> ANIMAL_TERMS = buildAnimalTerms();

    private static final int LOOP_REPEATED_ITEM = 5;
    private static final int LOOP_REPEATED_LINE = 3;
    private static final int LOOP_REPEATED_NGRAM = 6;
    private static final int MAX_QUANTITY_ITEMS_PER_MEAL = 8;
    private static final int MAX_QUANTITY_ITEMS_TOTAL = 24;

    private ChatOutputGuard() {
    }

    private static List<Pattern> buildAnimalTerms() {
        String[] terms = {
                "cá hồi", "cá ngừ", "cá mòi", "cá thu", "cá basa", "cá tra", "cá biển", "cá viên", "chả cá",
                "cá khô", "cá rô", "cá lóc", "cá nục", "cá trích", "cá cơm", "nước cá", "dầu cá",
                "tôm", "cua", "mực", "ghẹ", "hàu", "hải sản", "thịt", "ếch", "trứng", "sữa bò", "sữa tươi",
                "sữa dê", "phô mai", "pho mát", "bơ động vật", "mật ong", "nước mắm", "mỡ heo", "mỡ lợn",
                "mỡ động vật", "xương hầm", "gelatin", "lòng đỏ", "lòng trắng"
        };
        List<Pattern> patterns = new ArrayList<>();
        for (String term : terms) {
            patterns.add(Pattern.compile("(?<![\\p{L}\\p{N}])" + Pattern.quote(term) + "(?![\\p{L}\\p{N}])",
                    Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE));
        }
        return patterns;
    }

    static Set<Issue> assess(String answer, String finishReason) {
        return assess(answer, finishReason, false, DietaryRestrictions.empty());
    }

    static Set<Issue> assess(String answer, String finishReason, boolean mealRequest) {
        return assess(answer, finishReason, mealRequest, DietaryRestrictions.empty());
    }

    static Set<Issue> assess(String answer, String finishReason, boolean mealRequest, DietaryRestrictions restrictions) {
        Set<Issue> issues = EnumSet.noneOf(Issue.class);
        if (answer == null || answer.isBlank()) {
            return issues;
        }
        if ("length".equalsIgnoreCase(finishReason)) {
            issues.add(Issue.TRUNCATED);
        }
        if (CJK.matcher(answer).find()) {
            issues.add(Issue.FOREIGN_SCRIPT);
        }
        if (hasRepetitionLoop(answer)) {
            issues.add(Issue.REPETITION_LOOP);
        }
        if (hasDuplicateMeals(answer)) {
            issues.add(Issue.DUPLICATE_MEALS);
        }
        if (hasExcessiveList(answer)) {
            issues.add(Issue.EXCESSIVE_LIST);
        }
        if (containsAffirmativeAnimalIngredient(answer)) {
            issues.add(Issue.ANIMAL_INGREDIENT);
        }
        if (restrictions != null && !restrictions.isEmpty() && containsAffirmativeAllergenViolation(answer, restrictions)) {
            issues.add(Issue.ALLERGEN_VIOLATION);
        }
        if (mealRequest && NUTRITION_FIGURE.matcher(answer).find()) {
            issues.add(Issue.INVENTED_NUTRITION);
        }
        if (DISCOURAGES_SUPPLEMENT_PATTERN.matcher(answer).find()) {
            issues.add(Issue.DISCOURAGES_SUPPLEMENTS);
        }
        if (!mealRequest && !mealBlocks(answer).isEmpty() && answer.toLowerCase(Locale.ROOT).contains("bữa 1")) {
            issues.add(Issue.TEMPLATE_LEAK);
        }
        if (mealRequest) {
            if (MEAL_HEADING_NO_NAME.matcher(answer).find()) {
                issues.add(Issue.INCOMPLETE_MEAL);
            }
            for (String block : mealBlocks(answer)) {
                if (countQuantities(block) < 3) {
                    issues.add(Issue.INCOMPLETE_MEAL);
                }
            }
        }
        if (!mealRequest && mealBlocks(answer).isEmpty()) {
            Matcher items = LIST_ITEM_LINE.matcher(answer);
            int count = 0;
            while (items.find()) {
                count++;
            }
            if (count > MAX_LIST_ITEMS) {
                issues.add(Issue.TOO_MANY_ITEMS);
            }
        }
        return issues;
    }

    // ----- allergen safety ----------------------------------------------------------------------------------------

    private static final Pattern ALLERGEN_WARNING_PATTERN = Pattern.compile(
            "\\b(khong nen|khong dung|khong an|tranh|kieng|loai bo|thay vi|di ung|can tranh|canh bao|nguy co|khong chua|khong co)\\b");

    static boolean containsAffirmativeAllergenViolation(String answer, DietaryRestrictions restrictions) {
        if (answer == null || answer.isBlank() || restrictions == null || restrictions.isEmpty()) {
            return false;
        }

        String normalizedAnswer = AllergenDetector.normalizeText(answer);

        // 1. Line-by-line inspection: Meal titles and ingredient bullets are strictly checked
        String[] lines = answer.split("\\R");
        for (String line : lines) {
            String normLine = AllergenDetector.normalizeText(line);
            if (normLine.isBlank()) {
                continue;
            }

            boolean isMealHeading = MEAL_HEADING.matcher(line).find()
                    || normLine.matches("^\\s*(bua|mon|thuc don)\\s*\\d+.*")
                    || normLine.matches("^\\s*\\d+[.)]\\s*(com|bun|pho|salad|sup|canh|chao|mi|yen mach|banh).*");

            boolean isIngredientLine = line.toLowerCase(Locale.ROOT).contains("nguyên liệu")
                    || line.toLowerCase(Locale.ROOT).contains("thành phần")
                    || normLine.contains("nguyen lieu")
                    || normLine.contains("thanh phan")
                    || (normLine.matches("^\\s*(\\d+[.)]|[-*•])\\s+.*") && QUANTITY.matcher(line).find());

            for (String keyword : restrictions.excludedKeywords()) {
                if (AllergenDetector.matchesWord(normLine, keyword)) {
                    if (isMealHeading || isIngredientLine) {
                        return true;
                    }
                    if (!isNegatedOrWarningContext(normLine, keyword)) {
                        return true;
                    }
                }
            }
        }

        // 2. Full text check for any affirmative recommendation of excluded allergens
        for (String keyword : restrictions.excludedKeywords()) {
            if (AllergenDetector.matchesWord(normalizedAnswer, keyword)) {
                if (!isNegatedOrWarningContext(normalizedAnswer, keyword)) {
                    return true;
                }
            }
        }

        return false;
    }

    private static boolean isNegatedOrWarningContext(String normalizedText, String keyword) {
        String padded = " " + normalizedText + " ";
        String target = " " + keyword + " ";
        int searchFrom = 0;

        while (true) {
            int idx = padded.indexOf(target, searchFrom);
            if (idx < 0) {
                break;
            }
            int from = Math.max(0, idx - 45);
            int to = Math.min(padded.length(), idx + target.length() + 35);
            String window = padded.substring(from, to);

            if (!ALLERGEN_WARNING_PATTERN.matcher(window).find()) {
                return false;
            }
            searchFrom = idx + target.length();
        }
        return true;
    }

    static boolean isMealSuggestionRequest(String query) {
        if (query == null) {
            return false;
        }
        String q = query.toLowerCase(Locale.ROOT);
        boolean mentionsMeal = q.contains("bữa") || q.contains("bua an") || q.contains("thực đơn")
                || q.contains("thuc don") || q.contains("món") || q.contains("mon an") || q.contains("menu")
                || q.contains("bua sang") || q.contains("bua trua") || q.contains("bua toi");
        boolean asksSuggestion = q.contains("gợi ý") || q.contains("goi y") || q.contains("lên") || q.contains("len ")
                || q.contains("đề xuất") || q.contains("de xuat") || q.contains("cho tôi") || q.contains("cho toi")
                || q.matches(".*\\b\\d+\\b.*");
        return mentionsMeal && asksSuggestion;
    }

    static int requestedMealCount(String query) {
        if (query != null) {
            Matcher m = Pattern.compile("(?<![\\p{L}\\p{N}])([1-5])(?![\\p{L}\\p{N}])\\s*(bữa|bua|món|mon)",
                    Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE).matcher(query);
            if (m.find()) {
                return Integer.parseInt(m.group(1));
            }
        }
        return 3;
    }

    // ----- repetition ---------------------------------------------------------------------------------------------

    static boolean hasRepetitionLoop(String answer) {
        Map<String, Integer> itemCounts = new HashMap<>();
        int totalItems = 0;
        for (String raw : ITEM_SPLIT.split(answer)) {
            String item = normalizeItem(raw);
            if (item.length() < 8 || item.endsWith(":")) {
                continue;
            }
            totalItems++;
            itemCounts.merge(item, 1, Integer::sum);
        }
        for (int count : itemCounts.values()) {
            if (count >= LOOP_REPEATED_ITEM) {
                return true;
            }
        }
        if (totalItems >= 12 && itemCounts.size() * 2 < totalItems) {
            return true;
        }

        Map<String, Integer> lineCounts = new HashMap<>();
        for (String raw : answer.split("\\R")) {
            String line = normalizeItem(raw);
            if (line.length() >= 25) {
                if (lineCounts.merge(line, 1, Integer::sum) >= LOOP_REPEATED_LINE) {
                    return true;
                }
            }
        }

        String[] words = WORD_SPLIT.split(answer.toLowerCase(Locale.ROOT));
        Map<String, Integer> ngrams = new HashMap<>();
        for (int i = 0; i + 4 <= words.length; i++) {
            String gram = String.join(" ", words[i], words[i + 1], words[i + 2], words[i + 3]);
            if (gram.length() < 14) {
                continue;
            }
            if (ngrams.merge(gram, 1, Integer::sum) >= LOOP_REPEATED_NGRAM) {
                return true;
            }
        }
        return false;
    }

    private static String normalizeItem(String raw) {
        String s = BULLET_PREFIX.matcher(raw == null ? "" : raw).replaceFirst("");
        s = s.toLowerCase(Locale.ROOT).replaceAll("[*_`#]", "");
        return s.replaceAll("\\s+", " ").trim();
    }

    // ----- meals --------------------------------------------------------------------------------------------------

    private static List<String> mealBlocks(String answer) {
        List<Integer> starts = new ArrayList<>();
        Matcher m = MEAL_HEADING.matcher(answer);
        while (m.find()) {
            starts.add(m.start());
        }
        List<String> blocks = new ArrayList<>();
        for (int i = 0; i < starts.size(); i++) {
            int end = i + 1 < starts.size() ? starts.get(i + 1) : answer.length();
            blocks.add(answer.substring(starts.get(i), end));
        }
        return blocks;
    }

    private static final Set<String> MEAL_STOP_WORDS = Set.of(
            "bua", "bữa", "mon", "món", "gam", "muong", "muỗng", "qua", "quả", "chut", "chút",
            "nau", "nấu", "chin", "chín", "voi", "với", "va", "và", "cho", "thi", "thì",
            "duoc", "được", "nguyen", "nguyên", "lieu", "liệu", "thia", "thìa", "ml", "g",
            "cach", "cách", "lam", "làm", "kem", "kèm", "theo", "an", "ăn");

    static String extractMealTitle(String block) {
        String firstLine = block.lines().findFirst().orElse("").trim();
        String cleaned = MEAL_HEADING.matcher(firstLine).replaceFirst("");
        cleaned = BULLET_PREFIX.matcher(cleaned).replaceFirst("");
        cleaned = cleaned.replaceAll("^[:\\-\\s]+", "").replaceAll("[*_`#]", "").trim();
        int colon = cleaned.indexOf(':');
        if (colon > 0 && colon < 20) {
            cleaned = cleaned.substring(colon + 1).trim();
        }
        return cleaned;
    }

    static boolean hasDuplicateMeals(String answer) {
        List<String> blocks = mealBlocks(answer);
        if (blocks.size() < 2) {
            return false;
        }

        List<String> titles = new ArrayList<>();
        List<Set<String>> titleWordsList = new ArrayList<>();
        List<Set<String>> blockWordSets = new ArrayList<>();

        for (String block : blocks) {
            String title = extractMealTitle(block);
            titles.add(title);

            Set<String> titleWords = new HashSet<>();
            for (String w : WORD_SPLIT.split(title.toLowerCase(Locale.ROOT))) {
                String norm = AllergenDetector.normalizeText(w);
                if (norm.length() > 2 && !MEAL_STOP_WORDS.contains(norm)) {
                    titleWords.add(norm);
                }
            }
            titleWordsList.add(titleWords);

            Set<String> words = new HashSet<>();
            for (String w : WORD_SPLIT.split(block.toLowerCase(Locale.ROOT))) {
                String norm = AllergenDetector.normalizeText(w);
                if (norm.length() > 2 && !MEAL_STOP_WORDS.contains(norm)) {
                    words.add(norm);
                }
            }
            blockWordSets.add(words);
        }

        for (int i = 0; i < blocks.size(); i++) {
            for (int j = i + 1; j < blocks.size(); j++) {
                // 1. Direct title check
                String titleA = AllergenDetector.normalizeText(titles.get(i));
                String titleB = AllergenDetector.normalizeText(titles.get(j));
                if (!titleA.isBlank() && !titleB.isBlank()) {
                    if (titleA.equals(titleB) || (titleA.length() > 10 && (titleA.contains(titleB) || titleB.contains(titleA)))) {
                        return true;
                    }
                }

                // 2. Title keywords overlap (e.g. "ca ri dau lang do" vs "ca ri dau lang voi bi do")
                Set<String> twA = titleWordsList.get(i);
                Set<String> twB = titleWordsList.get(j);
                if (twA.size() >= 2 && twB.size() >= 2) {
                    Set<String> interTw = new HashSet<>(twA);
                    interTw.retainAll(twB);
                    Set<String> unionTw = new HashSet<>(twA);
                    unionTw.addAll(twB);
                    if ((double) interTw.size() / unionTw.size() >= 0.60) {
                        return true;
                    }
                }

                // 3. Block content vocabulary Jaccard similarity
                Set<String> bwA = blockWordSets.get(i);
                Set<String> bwB = blockWordSets.get(j);
                if (bwA.size() >= 5 && bwB.size() >= 5) {
                    Set<String> interBw = new HashSet<>(bwA);
                    interBw.retainAll(bwB);
                    Set<String> unionBw = new HashSet<>(bwA);
                    unionBw.addAll(bwB);
                    if ((double) interBw.size() / unionBw.size() >= 0.55) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    static boolean hasExcessiveList(String answer) {
        int total = countQuantities(answer);
        if (total > MAX_QUANTITY_ITEMS_TOTAL) {
            return true;
        }
        List<String> blocks = mealBlocks(answer);
        if (blocks.isEmpty()) {
            return total > MAX_QUANTITY_ITEMS_PER_MEAL + 4;
        }
        for (String block : blocks) {
            if (countQuantities(block) > MAX_QUANTITY_ITEMS_PER_MEAL) {
                return true;
            }
        }
        return false;
    }

    private static int countQuantities(String text) {
        Matcher m = QUANTITY.matcher(text);
        int count = 0;
        while (m.find()) {
            count++;
        }
        return count;
    }

    // ----- animal ingredients -------------------------------------------------------------------------------------

    static boolean containsAffirmativeAnimalIngredient(String answer) {
        String lower = answer.toLowerCase(Locale.ROOT);
        for (Pattern term : ANIMAL_TERMS) {
            Matcher m = term.matcher(lower);
            while (m.find()) {
                int from = Math.max(0, m.start() - 35);
                int to = Math.min(lower.length(), m.end() + 35);
                if (!VEGAN_OR_NEGATION_CONTEXT.matcher(lower.substring(from, to)).find()) {
                    return true;
                }
            }
        }
        return false;
    }

    // ----- trimming -----------------------------------------------------------------------------------------------

    /** Drops lines and comma items already seen, and an unfinished last line of a truncated answer. */
    static String trimRepetition(String answer, boolean truncated) {
        List<String> lines = new ArrayList<>(List.of(answer.split("\\R")));
        if (truncated && lines.size() > 1) {
            lines.remove(lines.size() - 1);
        }
        Set<String> seenLines = new LinkedHashSet<>();
        StringBuilder out = new StringBuilder();
        for (String line : lines) {
            String key = normalizeItem(line);
            if (key.length() >= 12 && !seenLines.add(key)) {
                continue;
            }
            String[] items = line.split(",");
            if (items.length > 3) {
                Set<String> seenItems = new LinkedHashSet<>();
                List<String> kept = new ArrayList<>();
                for (String item : items) {
                    if (seenItems.add(normalizeItem(item))) {
                        kept.add(item.strip());
                    }
                }
                line = String.join(", ", kept);
            }
            out.append(line).append('\n');
        }
        return out.toString().strip();
    }

    static String stripForeignScript(String text) {
        if (text == null) {
            return "";
        }
        return CJK.matcher(text).replaceAll("").replaceAll(" {2,}", " ").trim();
    }
}
