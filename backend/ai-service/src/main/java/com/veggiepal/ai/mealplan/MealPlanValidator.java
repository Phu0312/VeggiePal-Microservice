package com.veggiepal.ai.mealplan;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.veggiepal.ai.common.AppException;
import com.veggiepal.ai.common.ErrorCode;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.PriorityQueue;
import java.util.Set;
import java.util.StringJoiner;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class MealPlanValidator {
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(MealPlanValidator.class);
    private static final Set<String> REQUIRED_MEALS = Set.of("BREAKFAST", "LUNCH", "DINNER");
    public static final List<String> STANDARD_DAYS = List.of(
            "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"
    );
    public static final List<String> STANDARD_MEALS = List.of(
            "BREAKFAST", "LUNCH", "DINNER"
    );
    // Share of the day's calorie target each meal aims for (spec: breakfast 25%, lunch 40%, dinner 35%).
    private static final Map<String, BigDecimal> MEAL_SHARES = Map.of(
            "BREAKFAST", new BigDecimal("0.25"),
            "LUNCH", new BigDecimal("0.40"),
            "DINNER", new BigDecimal("0.35"));

    // Same defaults as application.properties and .env.example, so a test that uses the short
    // constructor runs the planner with the runtime portion range. MealPlanRuntimeConfigTest checks this.
    public static final double DEFAULT_MIN_PORTION_SCALE = 0.75;
    public static final double DEFAULT_MAX_PORTION_SCALE = 1.50;
    // When no day can meet every macro range, days whose verified error is within this much of the
    // best error found may be used, so the week can rotate recipes. Errors are normalised by the
    // range midpoint (0.03 on a 90-130 g protein range is about 3.3 g). Calories stay in range
    // whenever any option reaches them.
    static final double NEAR_OPTIMAL_TOLERANCE = 0.08;

    private final ObjectMapper mapper;
    private final double minPortionScale;
    private final double maxPortionScale;

    public MealPlanValidator(ObjectMapper mapper) {
        this(mapper, DEFAULT_MIN_PORTION_SCALE, DEFAULT_MAX_PORTION_SCALE);
    }

    @Autowired
    public MealPlanValidator(
            ObjectMapper mapper,
            @Value("${ai.meal-plan.min-portion-scale:0.75}") double minPortionScale,
            @Value("${ai.meal-plan.max-portion-scale:1.50}") double maxPortionScale) {
        this.mapper = mapper;
        this.minPortionScale = minPortionScale;
        this.maxPortionScale = maxPortionScale;
    }

    public double minPortionScale() { return minPortionScale; }

    public double maxPortionScale() { return maxPortionScale; }

    public ArrayNode safeCandidates(JsonNode recipes, JsonNode allergies, List<String> availableIngredients) {
        if (!recipes.isArray()) throw new AppException(ErrorCode.DOWNSTREAM_UNAVAILABLE);
        List<JsonNode> safe = new ArrayList<>();
        for (JsonNode recipe : recipes) {
            if (isVegan(recipe) && isAllergySafe(recipe, allergies) && canCalculateMacro(recipe)) {
                safe.add(recipe);
            }
        }
        if (safe.isEmpty()) throw new AppException(ErrorCode.NO_VALID_RECIPES);

        Set<String> available = normalized(availableIngredients);
        if (!available.isEmpty()) {
            safe.sort((r1, r2) -> {
                int c1 = countMatchingAvailableIngredients(r1, available);
                int c2 = countMatchingAvailableIngredients(r2, available);
                return Integer.compare(c2, c1);
            });
        }

        ArrayNode result = mapper.createArrayNode();
        safe.forEach(result::add);
        return result;
    }

    public int countMatchingAvailableIngredients(JsonNode recipe, Set<String> available) {
        if (available == null || available.isEmpty()) return 0;
        int matches = 0;
        for (String wanted : available) {
            boolean matched = false;
            for (JsonNode ingredient : recipe.path("ingredients")) {
                String value = normalize(ingredient.path("ingredientName").asText());
                String normalizedName = normalize(ingredient.path("normalizedName").asText());
                if ((!value.isBlank() && (value.contains(wanted) || wanted.contains(value)))
                        || (!normalizedName.isBlank() && (normalizedName.contains(wanted) || wanted.contains(normalizedName)))) {
                    matched = true;
                    break;
                }
            }
            if (matched) matches++;
        }
        return matches;
    }

    public ArrayNode promptCandidates(JsonNode recipes) {
        ArrayNode result = mapper.createArrayNode();
        for (JsonNode recipe : recipes) {
            ObjectNode item = mapper.createObjectNode();
            item.put("id", recipe.path("id").asLong());
            item.put("title", recipe.path("title").asText());
            ArrayNode names = item.putArray("ingredients");
            for (JsonNode ingredient : recipe.path("ingredients")) names.add(ingredient.path("ingredientName").asText());
            item.set("nutritionPerServing", nutritionFor(recipe));
            result.add(item);
        }
        return result;
    }

    public static final int DEFAULT_MAX_PROMPT_RECIPES = 20;

    public ArrayNode selectPromptCandidates(ArrayNode candidates, MealPlanDtos.NutritionTarget target) {
        return selectPromptCandidates(candidates, target, DEFAULT_MAX_PROMPT_RECIPES);
    }

    public ArrayNode selectPromptCandidates(ArrayNode candidates, MealPlanDtos.NutritionTarget target, int maxRecipes) {
        if (candidates == null || candidates.size() <= maxRecipes) {
            return candidates != null ? candidates : mapper.createArrayNode();
        }
        Set<Long> selectedIds = new HashSet<>();
        ArrayNode result = mapper.createArrayNode();

        // 1. Top pantry-matched recipes (candidates is already sorted by available ingredients)
        int pantryLimit = Math.min(8, maxRecipes / 3 + 1);
        for (JsonNode recipe : candidates) {
            if (result.size() >= pantryLimit) break;
            long id = recipe.path("id").asLong();
            if (selectedIds.add(id)) result.add(recipe);
        }

        // 2. Breakfast-suitable recipes (e.g. súp, cháo, bún, phở, bánh mì, yến mạch, sinh tố...)
        int breakfastLimit = Math.min(6, maxRecipes / 4 + 1);
        int breakfastCount = 0;
        for (JsonNode recipe : candidates) {
            if (breakfastCount >= breakfastLimit || result.size() >= maxRecipes - 4) break;
            long id = recipe.path("id").asLong();
            if (mealSuitabilityPenalty(recipe, "BREAKFAST") == 0 && selectedIds.add(id)) {
                result.add(recipe);
                breakfastCount++;
            }
        }

        // 3. Fill remaining slots with diverse candidates from the safe pool
        for (JsonNode recipe : candidates) {
            if (result.size() >= maxRecipes) break;
            long id = recipe.path("id").asLong();
            if (selectedIds.add(id)) result.add(recipe);
        }
        return result;
    }

    public ArrayNode selectReplacePromptCandidates(ArrayNode candidates, BigDecimal budget, Long currentRecipeId, int maxRecipes) {
        if (candidates == null) return mapper.createArrayNode();
        ArrayNode result = mapper.createArrayNode();
        Set<Long> selectedIds = new HashSet<>();
        for (JsonNode recipe : candidates) {
            long id = recipe.path("id").asLong();
            if (currentRecipeId != null && id == currentRecipeId) continue;
            if (reachesBudget(recipe, budget) && selectedIds.add(id)) {
                result.add(recipe);
                if (result.size() >= maxRecipes) return result;
            }
        }
        for (JsonNode recipe : candidates) {
            long id = recipe.path("id").asLong();
            if (currentRecipeId != null && id == currentRecipeId) continue;
            if (selectedIds.add(id)) {
                result.add(recipe);
                if (result.size() >= maxRecipes) return result;
            }
        }
        return result;
    }

    public ArrayNode compactPromptCandidates(JsonNode recipes) {
        ArrayNode result = mapper.createArrayNode();
        if (recipes == null || !recipes.isArray()) return result;
        for (JsonNode recipe : recipes) {
            ObjectNode item = mapper.createObjectNode();
            item.put("id", recipe.path("id").asLong());
            item.put("title", recipe.path("title").asText());
            Optional<Macro> macro = tryCalculateMacro(recipe);
            if (macro.isPresent()) {
                Macro m = macro.get();
                item.put("kcal", m.getCalories().setScale(0, RoundingMode.HALF_UP).intValue());
                item.put("p", m.getProtein().setScale(0, RoundingMode.HALF_UP).intValue());
                item.put("c", m.getCarbohydrate().setScale(0, RoundingMode.HALF_UP).intValue());
                item.put("f", m.getFat().setScale(0, RoundingMode.HALF_UP).intValue());
            }
            result.add(item);
        }
        return result;
    }

    public void validateTarget(MealPlanDtos.NutritionTarget target) {
        if (target == null) return;
        checkRange(target.minCalories(), target.maxCalories());
        checkRange(target.minProtein(), target.maxProtein());
        checkRange(target.minCarbohydrate(), target.maxCarbohydrate());
        checkRange(target.minFat(), target.maxFat());
    }

    public void validateAndEnrich(ObjectNode plan, JsonNode recipes, JsonNode allergies,
            MealPlanDtos.NutritionTarget target, boolean repick) {
        if (recipes == null || !recipes.isArray()) throw new AppException(ErrorCode.DOWNSTREAM_UNAVAILABLE);

        Map<Long, JsonNode> byId = new LinkedHashMap<>();
        Map<Long, Macro> baseMacros = new HashMap<>();
        List<JsonNode> candidateList = new ArrayList<>();
        for (JsonNode recipe : recipes) {
            if (!isVegan(recipe) || !isAllergySafe(recipe, allergies)) continue;
            Optional<Macro> macro = tryCalculateMacro(recipe);
            if (macro.isEmpty()) continue;
            long id = recipe.path("id").asLong();
            byId.put(id, recipe);
            baseMacros.put(id, macro.get());
            candidateList.add(recipe);
        }
        if (byId.isEmpty()) throw new AppException(ErrorCode.NO_VALID_RECIPES);

        BigDecimal mid = midCalories(target);

        Map<String, ObjectNode> existingDays = new HashMap<>();
        JsonNode daysNode = plan.path("days");
        if (daysNode.isArray()) {
            for (JsonNode d : daysNode) {
                if (d instanceof ObjectNode on) {
                    String dName = normalizeDay(on.path("day").asText());
                    if (!dName.isBlank() && !existingDays.containsKey(dName)) {
                        existingDays.put(dName, on);
                    }
                }
            }
        }

        ArrayNode finalDaysArray = mapper.createArrayNode();
        Map<Long, Integer> weeklyUsage = new HashMap<>();
        Set<String> usedDayCombinations = new HashSet<>();
        List<WeekOption> feasibleWeekOptions = repick && hasMacroTarget(target)
                ? buildWeekOptions(candidateList, baseMacros, target) : List.of();

        for (String standardDay : STANDARD_DAYS) {
            ObjectNode dayNode = existingDays.get(standardDay);
            if (dayNode == null) {
                dayNode = mapper.createObjectNode();
            }
            dayNode.put("day", standardDay);

            Map<String, ObjectNode> existingMeals = new HashMap<>();
            JsonNode mealsNode = dayNode.path("meals");
            if (mealsNode.isArray()) {
                for (JsonNode m : mealsNode) {
                    if (m instanceof ObjectNode on) {
                        String mType = on.path("mealType").asText().toUpperCase(Locale.ROOT).trim();
                        if (REQUIRED_MEALS.contains(mType) && !existingMeals.containsKey(mType)) {
                            existingMeals.put(mType, on);
                        }
                    }
                }
            }

            ArrayNode finalMealsArray = mapper.createArrayNode();
            Set<Long> sameDayRecipeIds = new HashSet<>();
            Macro dayTotal = new Macro();
            List<Long> suggestedIds = STANDARD_MEALS.stream().map(meal -> {
                ObjectNode suggestion = existingMeals.get(meal);
                return suggestion == null ? -1L : suggestion.path("recipeId").asLong(-1);
            }).toList();
            List<Portion> optimized = !feasibleWeekOptions.isEmpty()
                    ? chooseWeekOption(feasibleWeekOptions, byId, candidateList, weeklyUsage,
                            usedDayCombinations, suggestedIds)
                    : repick && hasMacroTarget(target)
                    ? optimizeDay(candidateList, baseMacros, target, weeklyUsage, suggestedIds) : List.of();
            if (!optimized.isEmpty()) usedDayCombinations.add(combinationKey(optimized));

            for (int i = 0; i < STANDARD_MEALS.size(); i++) {
                String mealType = STANDARD_MEALS.get(i);
                ObjectNode mealNode = existingMeals.get(mealType);
                if (mealNode == null) {
                    mealNode = mapper.createObjectNode();
                    mealNode.put("note", "Bữa ăn cân bằng dinh dưỡng");
                }
                mealNode.put("mealType", mealType);

                // Budgets are taken one meal at a time, so a meal that falls short leaves more for the next.
                BigDecimal budget = mid == null ? null : mealBudget(i, mid, dayTotal.calories);
                long currentRecipeId = mealNode.path("recipeId").asLong(-1);
                boolean keep = byId.containsKey(currentRecipeId)
                        && (byId.size() < 3 || !sameDayRecipeIds.contains(currentRecipeId))
                        && (!repick || reachable(baseMacros.get(currentRecipeId).calories, budget));
                long selectedRecipeId = !optimized.isEmpty() ? optimized.get(i).recipeId()
                        : keep ? currentRecipeId
                        : selectBestCandidate(candidateList, baseMacros, sameDayRecipeIds, weeklyUsage, byId.size(), budget);
                // The existing note describes the recipe it was written for, not the one swapped in.
                if (selectedRecipeId != currentRecipeId && existingMeals.containsKey(mealType)) {
                    mealNode.put("note", "Bữa ăn cân bằng dinh dưỡng");
                }
                mealNode.put("recipeId", selectedRecipeId);

                sameDayRecipeIds.add(selectedRecipeId);
                weeklyUsage.merge(selectedRecipeId, 1, Integer::sum);

                Macro base = baseMacros.get(selectedRecipeId);
                BigDecimal scale = !optimized.isEmpty() ? optimized.get(i).scale()
                        : portionScale(base.calories, budget);
                Macro scaled = (scale.compareTo(BigDecimal.ONE) == 0) ? base : base.multiply(scale);
                mealNode.set("nutrition", scaled.toJson(mapper));
                if (scale.compareTo(BigDecimal.ONE) != 0) {
                    mealNode.put("servingMultiplier", scale);
                } else {
                    mealNode.remove("servingMultiplier");
                }
                dayTotal.add(scaled);
                finalMealsArray.add(mealNode);
            }

            dayNode.set("meals", finalMealsArray);
            dayNode.set("nutritionTotals", dayTotal.toJson(mapper));
            markTarget(dayNode, dayTotal, target);

            finalDaysArray.add(dayNode);
        }

        plan.set("days", finalDaysArray);
    }

    private boolean hasMacroTarget(MealPlanDtos.NutritionTarget target) {
        return target != null && (target.minProtein() != null || target.maxProtein() != null
                || target.minCarbohydrate() != null || target.maxCarbohydrate() != null
                || target.minFat() != null || target.maxFat() != null);
    }

    // Build whole-day options once for the week. Canonical ID order makes the search independent
    // of Recipe Service pagination order and of pantry sorting. When some days meet every supplied
    // range (checked with exact BigDecimal sums), only those enter the pool. When none do (the target
    // is out of reach for this catalogue and portion range), the pool keeps the best verified near
    // misses instead, so the week can still rotate recipes rather than repeat one day seven times.
    // markTarget then reports every miss truthfully.
    private List<WeekOption> buildWeekOptions(List<JsonNode> candidates, Map<Long, Macro> macros,
            MealPlanDtos.NutritionTarget target) {
        List<JsonNode> ordered = new ArrayList<>(candidates);
        ordered.sort((a, b) -> Long.compare(a.path("id").asLong(), b.path("id").asLong()));
        int count = ordered.size();
        if (count < 3) return List.of();
        long[] ids = new long[count];
        Macro[] values = new Macro[count];
        double[][] nutrients = new double[count][4];
        for (int i = 0; i < count; i++) {
            ids[i] = ordered.get(i).path("id").asLong();
            values[i] = macros.get(ids[i]);
            nutrients[i] = new double[]{values[i].calories.doubleValue(), values[i].protein.doubleValue(),
                    values[i].carbohydrate.doubleValue(), values[i].fat.doubleValue()};
        }
        int minimum = (int) Math.round(minPortionScale * 100);
        int maximum = (int) Math.round(maxPortionScale * 100);
        Map<String, WeekOption> exact = new LinkedHashMap<>();
        Map<String, WeekOption> near = new HashMap<>();
        java.util.Random random = new java.util.Random(20261031L);
        search: for (int restart = 0; restart < 1000; restart++) {
            int[] picked = new int[3];
            int[] scales = new int[3];
            for (int meal = 0; meal < 3; meal++) {
                do { picked[meal] = random.nextInt(count); } while (duplicate(picked, meal));
                scales[meal] = minimum + random.nextInt(maximum - minimum + 1);
            }
            double score = searchError(picked, scales, nutrients, target, CALORIE_WEIGHT);
            double bestScore = score;
            int[] bestPicked = picked.clone();
            int[] bestScales = scales.clone();
            for (int step = 0; step < 3000; step++) {
                if (score == 0 && exactTargetMet(picked, scales, values, target)) {
                    WeekOption option = weekOption(ids, values, picked, scales, target);
                    exact.putIfAbsent(option.key(), option);
                    if (exact.size() >= 80) break search;
                }
                int meal = random.nextInt(3);
                int oldId = picked[meal];
                int oldScale = scales[meal];
                if (random.nextDouble() < 0.2) {
                    picked[meal] = random.nextInt(count);
                    if (duplicateAnywhere(picked, meal)) { picked[meal] = oldId; continue; }
                } else {
                    scales[meal] = Math.clamp(scales[meal] + random.nextInt(51) - 25, minimum, maximum);
                }
                double next = searchError(picked, scales, nutrients, target, CALORIE_WEIGHT);
                double temperature = 0.03 * (1.0 - (double) step / 3000) + 0.0001;
                if (next <= score || random.nextDouble() < Math.exp((score - next) / temperature)) {
                    score = next;
                    if (score < bestScore) {
                        bestScore = score;
                        bestPicked = picked.clone();
                        bestScales = scales.clone();
                    }
                } else { picked[meal] = oldId; scales[meal] = oldScale; }
            }
            if (exact.isEmpty()) {
                WeekOption option = weekOption(ids, values, bestPicked, bestScales, target);
                near.merge(option.key(), option, (a, b) -> a.error() <= b.error() ? a : b);
            }
        }
        if (!exact.isEmpty()) return new ArrayList<>(exact.values());
        List<WeekOption> pool = nearOptimal(near.values());
        if (!pool.isEmpty()) {
            log.info("No day meets every nutrition range with portions {}-{}x; using {} near-optimal day options"
                    + " (best verified error {}).", minPortionScale, maxPortionScale, pool.size(),
                    String.format(Locale.ROOT, "%.4f", pool.getFirst().error()));
        }
        return pool;
    }

    // Keeps calorie-compliant options when any exist (targetMet depends only on calories), then the
    // options within NEAR_OPTIMAL_TOLERANCE of the best verified macro error.
    static List<WeekOption> nearOptimal(java.util.Collection<WeekOption> options) {
        List<WeekOption> pool = new ArrayList<>(options);
        if (pool.stream().anyMatch(WeekOption::caloriesMet)) pool.removeIf(option -> !option.caloriesMet());
        double best = pool.stream().mapToDouble(WeekOption::error).min().orElse(0);
        pool.removeIf(option -> option.error() > best + NEAR_OPTIMAL_TOLERANCE);
        pool.sort(java.util.Comparator.comparingDouble(WeekOption::error).thenComparing(WeekOption::key));
        return pool;
    }

    private WeekOption weekOption(long[] ids, Macro[] values, int[] picked, int[] scales,
            MealPlanDtos.NutritionTarget target) {
        List<Portion> day = new ArrayList<>();
        Macro total = new Macro();
        for (int meal = 0; meal < 3; meal++) {
            BigDecimal scale = BigDecimal.valueOf(scales[meal], 2);
            Macro scaled = values[picked[meal]].multiply(scale);
            day.add(new Portion(ids[picked[meal]], scale, scaled));
            total.add(scaled);
        }
        return new WeekOption(day, combinationKey(day),
                rangeError(total.calories, target.minCalories(), target.maxCalories(), 1) * CALORIE_WEIGHT
                        + rangeError(total.protein, target.minProtein(), target.maxProtein(), 1)
                        + rangeError(total.carbohydrate, target.minCarbohydrate(), target.maxCarbohydrate(), 1)
                        + rangeError(total.fat, target.minFat(), target.maxFat(), 1),
                inside(total.calories, target.minCalories(), target.maxCalories()));
    }

    // Picks the day for the week: recipes already used this week and repeated day combinations cost
    // far more than the small spread of verified error inside the pool, so the week rotates recipes
    // whenever the pool allows it without leaving the near-optimal band.
    private List<Portion> chooseWeekOption(List<WeekOption> options, Map<Long, JsonNode> byId,
            List<JsonNode> rankedCandidates, Map<Long, Integer> weeklyUsage,
            Set<String> usedCombinations, List<Long> suggestedIds) {
        Map<Long, Integer> pantryRank = new HashMap<>();
        for (int i = 0; i < rankedCandidates.size(); i++)
            pantryRank.put(rankedCandidates.get(i).path("id").asLong(), i);
        List<Portion> best = List.of();
        double bestScore = Double.POSITIVE_INFINITY;
        for (WeekOption weekOption : options) {
            List<Portion> option = weekOption.portions();
            String key = weekOption.key();
            for (int breakfast = 0; breakfast < 3; breakfast++) {
                for (int lunch = 0; lunch < 3; lunch++) {
                    if (lunch == breakfast) continue;
                    int dinner = 3 - breakfast - lunch;
                    List<Portion> ordered = List.of(option.get(breakfast), option.get(lunch), option.get(dinner));
                    double score = usedCombinations.contains(key) ? 100000 : 0;
                    score += weekOption.error() * 100;
                    for (int meal = 0; meal < 3; meal++) {
                        Portion portion = ordered.get(meal);
                        int uses = weeklyUsage.getOrDefault(portion.recipeId(), 0);
                        score += uses * 100 + Math.max(0, uses - 2) * 300;
                        score += mealSuitabilityPenalty(byId.get(portion.recipeId()), STANDARD_MEALS.get(meal));
                        score += pantryRank.getOrDefault(portion.recipeId(), rankedCandidates.size())
                                / (double) Math.max(1, rankedCandidates.size());
                        if (portion.recipeId() == suggestedIds.get(meal)) score -= 2;
                    }
                    if (score < bestScore) { bestScore = score; best = ordered; }
                }
            }
        }
        return best;
    }

    private double mealSuitabilityPenalty(JsonNode recipe, String mealType) {
        String title = normalize(recipe.path("title").asText());
        boolean breakfast = title.contains("sup") || title.contains("chao") || title.contains("pho")
                || title.contains("bun") || title.contains("mi ") || title.contains("banh")
                || title.contains("xoi") || title.contains("yen mach") || title.contains("sinh to")
                || title.contains("cha ") || title.contains("cuon");
        if ("BREAKFAST".equals(mealType)) {
            if (title.contains("com ") || title.contains("kho ")) return 1000;
            return breakfast ? 0 : 40;
        }
        boolean breakfastOnly = title.contains("yen mach") || title.contains("sinh to") || title.contains("xoi");
        return breakfastOnly ? 20 : 0;
    }

    private String combinationKey(List<Portion> portions) {
        long[] ids = portions.stream().mapToLong(Portion::recipeId).sorted().toArray();
        return ids[0] + ":" + ids[1] + ":" + ids[2];
    }

    // Search portions of verified, allergy-safe recipes. The bounded beam keeps generation
    // predictable for the live catalogue; final flags use exact server-calculated nutrition.
    private List<Portion> optimizeDay(List<JsonNode> candidates, Map<Long, Macro> macros,
            MealPlanDtos.NutritionTarget target, Map<Long, Integer> weeklyUsage, List<Long> suggestedIds) {
        List<Portion> portions = new ArrayList<>();
        for (JsonNode recipe : candidates) {
            long id = recipe.path("id").asLong();
            Macro base = macros.get(id);
            for (int hundredths = (int) Math.round(minPortionScale * 100);
                    hundredths <= (int) Math.round(maxPortionScale * 100); hundredths += 5) {
                BigDecimal scale = BigDecimal.valueOf(hundredths, 2);
                portions.add(new Portion(id, scale, base.multiply(scale)));
            }
        }
        if (portions.isEmpty()) return List.of();
        List<Selection> beam = List.of(new Selection(List.of(), new Macro(), 0));
        BigDecimal share = BigDecimal.ZERO;
        for (int meal = 0; meal < STANDARD_MEALS.size(); meal++) {
            share = share.add(MEAL_SHARES.get(STANDARD_MEALS.get(meal)));
            PriorityQueue<Selection> best = new PriorityQueue<>((a, b) -> Double.compare(b.score(), a.score()));
            for (Selection prefix : beam) {
                for (Portion portion : portions) {
                    if (candidates.size() >= 3 && prefix.portions().stream()
                            .anyMatch(p -> p.recipeId() == portion.recipeId())) continue;
                    Macro total = prefix.total().plus(portion.nutrition());
                    List<Portion> selected = new ArrayList<>(prefix.portions());
                    selected.add(portion);
                    double score = targetError(total, target, share.doubleValue())
                            + selected.stream().mapToInt(p -> weeklyUsage.getOrDefault(p.recipeId(), 0)).sum() * 0.00001;
                    Selection next = new Selection(selected, total, score);
                    if (best.size() < 200) best.add(next);
                    else if (score < best.peek().score()) { best.poll(); best.add(next); }
                }
            }
            beam = new ArrayList<>(best);
        }
        List<Portion> bestBeam = beam.stream().min((a, b) -> Double.compare(a.score(), b.score()))
                .map(Selection::portions).orElse(List.of());
        List<Portion> feasible = searchFeasibleDay(candidates, macros, target, weeklyUsage, suggestedIds);
        return feasible.isEmpty() ? bestBeam : feasible;
    }

    // The calorie-share beam can miss valid days with uneven meal sizes. This reproducible
    // bounded search checks whole-day constraints and returns only exactly verified solutions.
    private List<Portion> searchFeasibleDay(List<JsonNode> candidates, Map<Long, Macro> macros,
            MealPlanDtos.NutritionTarget target, Map<Long, Integer> weeklyUsage, List<Long> suggestedIds) {
        int count = candidates.size();
        if (count == 0) return List.of();
        long[] ids = new long[count];
        Macro[] values = new Macro[count];
        double[][] nutrients = new double[count][4];
        for (int i = 0; i < count; i++) {
            ids[i] = candidates.get(i).path("id").asLong();
            values[i] = macros.get(ids[i]);
            nutrients[i] = new double[]{values[i].calories.doubleValue(), values[i].protein.doubleValue(),
                    values[i].carbohydrate.doubleValue(), values[i].fat.doubleValue()};
        }
        java.util.Random random = new java.util.Random(17L + weeklyUsage.values().stream().mapToInt(Integer::intValue).sum());
        for (int restart = 0; restart < 500; restart++) {
            int[] picked = new int[3];
            int[] scales = new int[3];
            for (int i = 0; i < 3; i++) {
                int suggestedIndex = -1;
                if (restart == 0) for (int j = 0; j < count; j++) {
                    if (ids[j] == suggestedIds.get(i)) { suggestedIndex = j; break; }
                }
                if (suggestedIndex >= 0 && (count < 3 || !duplicateSuggestion(picked, i, suggestedIndex))) {
                    picked[i] = suggestedIndex;
                    scales[i] = Math.clamp(100, (int) Math.round(minPortionScale * 100),
                            (int) Math.round(maxPortionScale * 100));
                } else {
                    do { picked[i] = random.nextInt(count); }
                    while (count >= 3 && duplicate(picked, i));
                    scales[i] = random.nextInt((int) Math.round(maxPortionScale * 100)
                            - (int) Math.round(minPortionScale * 100) + 1) + (int) Math.round(minPortionScale * 100);
                }
            }
            double score = searchError(picked, scales, nutrients, target);
            for (int step = 0; step < 4000; step++) {
                if (score == 0 && exactTargetMet(picked, scales, values, target)) {
                    List<Portion> result = new ArrayList<>();
                    for (int i = 0; i < 3; i++) {
                        BigDecimal scale = BigDecimal.valueOf(scales[i], 2);
                        result.add(new Portion(ids[picked[i]], scale, values[picked[i]].multiply(scale)));
                    }
                    return result;
                }
                int meal = random.nextInt(3);
                int oldId = picked[meal];
                int oldScale = scales[meal];
                if (random.nextDouble() < 0.2) {
                    picked[meal] = random.nextInt(count);
                    if (count >= 3 && duplicateAnywhere(picked, meal)) { picked[meal] = oldId; continue; }
                } else {
                    int change = random.nextInt(51) - 25;
                    scales[meal] = Math.clamp(scales[meal] + change,
                            (int) Math.round(minPortionScale * 100), (int) Math.round(maxPortionScale * 100));
                }
                double next = searchError(picked, scales, nutrients, target);
                double temperature = 0.03 * (1.0 - (double) step / 4000) + 0.0001;
                if (next <= score || random.nextDouble() < Math.exp((score - next) / temperature)) score = next;
                else { picked[meal] = oldId; scales[meal] = oldScale; }
            }
        }
        return List.of();
    }

    private boolean duplicate(int[] picked, int position) {
        for (int i = 0; i < position; i++) if (picked[i] == picked[position]) return true;
        return false;
    }

    private boolean duplicateAnywhere(int[] picked, int position) {
        for (int i = 0; i < picked.length; i++)
            if (i != position && picked[i] == picked[position]) return true;
        return false;
    }

    private boolean duplicateSuggestion(int[] picked, int position, int suggestion) {
        for (int i = 0; i < position; i++) if (picked[i] == suggestion) return true;
        return false;
    }

    // Calories decide targetMet, so the week search weights a calorie miss above a macro miss.
    private static final double CALORIE_WEIGHT = 3;

    private double searchError(int[] picked, int[] scales, double[][] nutrients,
            MealPlanDtos.NutritionTarget target) {
        return searchError(picked, scales, nutrients, target, 1);
    }

    private double searchError(int[] picked, int[] scales, double[][] nutrients,
            MealPlanDtos.NutritionTarget target, double calorieWeight) {
        double[] total = new double[4];
        for (int i = 0; i < 3; i++) for (int j = 0; j < 4; j++)
            total[j] += nutrients[picked[i]][j] * scales[i] / 100.0;
        return rangeError(total[0], target.minCalories(), target.maxCalories(), 1) * calorieWeight
                + rangeError(total[1], target.minProtein(), target.maxProtein(), 1)
                + rangeError(total[2], target.minCarbohydrate(), target.maxCarbohydrate(), 1)
                + rangeError(total[3], target.minFat(), target.maxFat(), 1);
    }

    private boolean exactTargetMet(int[] picked, int[] scales, Macro[] values,
            MealPlanDtos.NutritionTarget target) {
        Macro total = new Macro();
        for (int i = 0; i < 3; i++) total.add(values[picked[i]].multiply(BigDecimal.valueOf(scales[i], 2)));
        return inside(total.calories, target.minCalories(), target.maxCalories())
                && inside(total.protein, target.minProtein(), target.maxProtein())
                && inside(total.carbohydrate, target.minCarbohydrate(), target.maxCarbohydrate())
                && inside(total.fat, target.minFat(), target.maxFat());
    }

    private double targetError(Macro total, MealPlanDtos.NutritionTarget target, double share) {
        return 20 * rangeError(total.calories, target.minCalories(), target.maxCalories(), share)
                + rangeError(total.protein, target.minProtein(), target.maxProtein(), share)
                + rangeError(total.carbohydrate, target.minCarbohydrate(), target.maxCarbohydrate(), share)
                + rangeError(total.fat, target.minFat(), target.maxFat(), share);
    }

    private double rangeError(BigDecimal actual, BigDecimal min, BigDecimal max, double share) {
        return rangeError(actual.doubleValue(), min, max, share);
    }

    private double rangeError(double value, BigDecimal min, BigDecimal max, double share) {
        if (min == null && max == null) return 0;
        double lower = min == null ? Double.NEGATIVE_INFINITY : min.doubleValue() * share;
        double upper = max == null ? Double.POSITIVE_INFINITY : max.doubleValue() * share;
        double reference = Math.max(1, min != null && max != null
                ? (min.doubleValue() + max.doubleValue()) / 2 * share
                : min != null ? lower : upper);
        if (value < lower) return (lower - value) / reference;
        if (value > upper) return (value - upper) / reference;
        return 0;
    }

    private record Portion(long recipeId, BigDecimal scale, Macro nutrition) {}
    record WeekOption(List<Portion> portions, String key, double error, boolean caloriesMet) {}
    private record Selection(List<Portion> portions, Macro total, double score) {}

    public Map<String, BigDecimal> mealBudgets(MealPlanDtos.NutritionTarget target) {
        Map<String, BigDecimal> budgets = new LinkedHashMap<>();
        BigDecimal mid = midCalories(target);
        if (mid == null) return budgets;
        for (String meal : STANDARD_MEALS) {
            budgets.put(meal, mid.multiply(MEAL_SHARES.get(meal)).setScale(2, RoundingMode.HALF_UP));
        }
        return budgets;
    }

    public String mealBudgetHint(MealPlanDtos.NutritionTarget target) {
        Map<String, BigDecimal> budgets = mealBudgets(target);
        if (budgets.isEmpty()) return "";
        StringJoiner parts = new StringJoiner(", ");
        budgets.forEach((meal, kcal) -> parts.add(meal + " khoảng " + kcal.setScale(0, RoundingMode.HALF_UP).toPlainString() + " kcal"));
        return " Ngân sách calo từng bữa: " + parts + ". Khẩu phần sẽ được nhân từ " + scaleText(minPortionScale)
                + " đến " + scaleText(maxPortionScale)
                + " lần cho khớp, nên chọn món có nutritionPerServing.calories gần ngân sách của bữa.";
    }

    public boolean reachesBudget(JsonNode recipe, BigDecimal budget) {
        return budget == null || tryCalculateMacro(recipe).map(m -> reachable(m.calories, budget)).orElse(false);
    }

    public long pickReplacement(JsonNode candidates, Set<Long> excluded, BigDecimal budget) {
        List<JsonNode> remaining = new ArrayList<>();
        Map<Long, Macro> macros = new HashMap<>();
        for (JsonNode c : candidates) {
            long id = c.path("id").asLong();
            if (excluded.contains(id)) continue;
            Optional<Macro> macro = tryCalculateMacro(c);
            if (macro.isEmpty()) continue;
            remaining.add(c);
            macros.put(id, macro.get());
        }
        if (remaining.isEmpty()) throw new AppException(ErrorCode.NO_VALID_RECIPES);
        return selectBestCandidate(remaining, macros, Set.of(), Map.of(), remaining.size(), budget);
    }

    private String scaleText(double scale) {
        return BigDecimal.valueOf(scale).stripTrailingZeros().toPlainString().replace('.', ',');
    }

    // Prefers recipes that can reach the budget within the portion range (least used this week first);
    // when none can, the one whose clamped portion lands closest. Ties keep candidate order, which
    // already favours recipes using the user's available ingredients. No budget = least used.
    private long selectBestCandidate(List<JsonNode> candidates, Map<Long, Macro> baseMacros, Set<Long> excluded,
            Map<Long, Integer> weeklyUsage, int totalDistinctCandidates, BigDecimal budget) {
        List<JsonNode> eligible = new ArrayList<>();
        for (JsonNode c : candidates) {
            if (totalDistinctCandidates < 3 || !excluded.contains(c.path("id").asLong())) {
                eligible.add(c);
            }
        }
        if (eligible.isEmpty()) {
            eligible = candidates;
        }

        JsonNode best = null;
        boolean bestReachable = false;
        BigDecimal bestError = null;
        int bestUsage = 0;
        for (JsonNode c : eligible) {
            long id = c.path("id").asLong();
            BigDecimal kcal = baseMacros.get(id).calories;
            boolean canReach = reachable(kcal, budget);
            BigDecimal error = canReach ? BigDecimal.ZERO
                    : portionScale(kcal, budget).multiply(kcal).subtract(budget).abs();
            int usage = weeklyUsage.getOrDefault(id, 0);
            boolean better = best == null
                    || (canReach && !bestReachable)
                    || (canReach && bestReachable && usage < bestUsage)
                    || (!canReach && !bestReachable && error.compareTo(bestError) < 0);
            if (better) {
                best = c;
                bestReachable = canReach;
                bestError = error;
                bestUsage = usage;
            }
        }
        return best.path("id").asLong();
    }

    // The day's aim: the midpoint of the range; a single-ended target aims 5% inside its bound, so the
    // 2-decimal rounding of the portion multipliers cannot land the day just outside it.
    private BigDecimal midCalories(MealPlanDtos.NutritionTarget target) {
        if (target == null) return null;
        BigDecimal min = target.minCalories();
        BigDecimal max = target.maxCalories();
        if (min != null && max != null) return min.add(max).divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP);
        if (min != null) return min.multiply(new BigDecimal("1.05")).setScale(4, RoundingMode.HALF_UP);
        return max == null ? null : max.multiply(new BigDecimal("0.95")).setScale(4, RoundingMode.HALF_UP);
    }

    private BigDecimal mealBudget(int index, BigDecimal mid, BigDecimal consumed) {
        BigDecimal remainingShare = BigDecimal.ZERO;
        for (int j = index; j < STANDARD_MEALS.size(); j++) {
            remainingShare = remainingShare.add(MEAL_SHARES.get(STANDARD_MEALS.get(j)));
        }
        BigDecimal remaining = mid.subtract(consumed).max(BigDecimal.ZERO);
        return remaining.multiply(MEAL_SHARES.get(STANDARD_MEALS.get(index)))
                .divide(remainingShare, 4, RoundingMode.HALF_UP);
    }

    private boolean reachable(BigDecimal kcal, BigDecimal budget) {
        if (budget == null) return true;
        if (kcal.signum() <= 0) return false;
        BigDecimal ratio = budget.divide(kcal, 4, RoundingMode.HALF_UP);
        return ratio.compareTo(BigDecimal.valueOf(minPortionScale)) >= 0
                && ratio.compareTo(BigDecimal.valueOf(maxPortionScale)) <= 0;
    }

    // Rounded to 2 decimals before it multiplies anything, so servingMultiplier x base = shown nutrition.
    private BigDecimal portionScale(BigDecimal kcal, BigDecimal budget) {
        if (budget == null || kcal.signum() <= 0) return BigDecimal.ONE;
        return budget.divide(kcal, 4, RoundingMode.HALF_UP)
                .max(BigDecimal.valueOf(minPortionScale))
                .min(BigDecimal.valueOf(maxPortionScale))
                .setScale(2, RoundingMode.HALF_UP);
    }

    private String normalizeDay(String raw) {
        if (raw == null) return "";
        String s = raw.trim().toUpperCase(Locale.ROOT);
        if (STANDARD_DAYS.contains(s)) return s;
        if (s.startsWith("DAY_") || s.startsWith("DAY ")) {
            String num = s.substring(4).trim();
            try {
                int idx = Integer.parseInt(num) - 1;
                if (idx >= 0 && idx < STANDARD_DAYS.size()) return STANDARD_DAYS.get(idx);
            } catch (NumberFormatException ignored) {}
        }
        return "";
    }

    public boolean canCalculateMacro(JsonNode recipe) {
        return tryCalculateMacro(recipe).isPresent();
    }

    public Optional<Macro> tryCalculateMacro(JsonNode recipe) {
        if (recipe == null) return Optional.empty();
        BigDecimal servings = safeDecimal(recipe.path("servings"));
        if (servings == null || servings.signum() <= 0) {
            log.warn("Excluding recipe id={}, title='{}': invalid servings",
                    recipe.path("id").asLong(-1), recipe.path("title").asText());
            return Optional.empty();
        }
        JsonNode ingredients = recipe.path("ingredients");
        if (!ingredients.isArray() || ingredients.isEmpty()) {
            log.warn("Excluding recipe id={}, title='{}': empty ingredients",
                    recipe.path("id").asLong(-1), recipe.path("title").asText());
            return Optional.empty();
        }
        Macro result = new Macro();
        for (JsonNode ingredient : ingredients) {
            BigDecimal cal = safeDecimal(ingredient.path("caloriesPer100g"));
            BigDecimal pro = safeDecimal(ingredient.path("proteinPer100g"));
            BigDecimal carbs = safeDecimal(ingredient.path("carbsPer100g"));
            BigDecimal fat = safeDecimal(ingredient.path("fatPer100g"));
            if (cal == null || pro == null || carbs == null || fat == null
                    || cal.signum() < 0 || pro.signum() < 0 || carbs.signum() < 0 || fat.signum() < 0) {
                log.warn("Excluding recipe id={}, title='{}': invalid or missing nutrition data for ingredient '{}'",
                        recipe.path("id").asLong(-1), recipe.path("title").asText(), ingredient.path("ingredientName").asText());
                return Optional.empty();
            }
            BigDecimal quantity = safeDecimal(ingredient.path("quantity"));
            String unit = ingredient.path("unit").asText();
            String name = ingredient.path("ingredientName").asText();
            String norm = ingredient.path("normalizedName").asText();
            Optional<BigDecimal> gramsOpt = IngredientUnitConverter.toGrams(quantity, unit, name, norm);
            if (gramsOpt.isEmpty()) {
                log.warn("Excluding recipe id={}, title='{}': cannot convert unit '{}' for ingredient '{}'",
                        recipe.path("id").asLong(-1), recipe.path("title").asText(), unit, name);
                return Optional.empty();
            }
            BigDecimal grams = gramsOpt.get();
            BigDecimal factor = grams.divide(new BigDecimal("100"), 8, RoundingMode.HALF_UP)
                    .divide(servings, 8, RoundingMode.HALF_UP);
            result.calories = result.calories.add(cal.multiply(factor));
            result.protein = result.protein.add(pro.multiply(factor));
            result.carbohydrate = result.carbohydrate.add(carbs.multiply(factor));
            result.fat = result.fat.add(fat.multiply(factor));
        }
        return Optional.of(result);
    }

    private ObjectNode nutritionFor(JsonNode recipe) {
        return macroFor(recipe).toJson(mapper);
    }

    public Macro macroFor(JsonNode recipe) {
        return tryCalculateMacro(recipe)
                .orElseThrow(() -> new AppException(ErrorCode.DOWNSTREAM_UNAVAILABLE));
    }

    private BigDecimal safeDecimal(JsonNode node) {
        if (node == null || !node.isNumber()) return null;
        return node.decimalValue();
    }

    public boolean isVegan(JsonNode recipe) {
        JsonNode ingredients = recipe.path("ingredients");
        if (!ingredients.isArray() || ingredients.isEmpty()) return false;
        for (JsonNode ingredient : ingredients) if (!ingredient.path("vegan").asBoolean(false)) return false;
        return true;
    }

    public boolean isAllergySafe(JsonNode recipe, JsonNode allergies) {
        if (allergies == null || !allergies.isArray() || allergies.isEmpty()) return true;

        Set<String> userAllergyCodes = new HashSet<>();
        Set<String> userAllergyTerms = new HashSet<>();
        allergies.forEach(item -> {
            String code = item.path("code").asText().trim().toUpperCase(Locale.ROOT);
            if (!code.isBlank()) userAllergyCodes.add(code);
            addTerm(userAllergyTerms, code);
            addTerm(userAllergyTerms, item.path("name").asText());
        });

        JsonNode ingredients = recipe.path("ingredients");
        if (!ingredients.isArray() || ingredients.isEmpty()) return false;

        for (JsonNode ingredient : ingredients) {
            JsonNode allergenNode = ingredient.path("allergen");
            if (allergenNode.isMissingNode() || allergenNode.isNull()) {
                log.warn("Excluding recipe id={}, title='{}': ingredient '{}' has missing allergen info",
                        recipe.path("id").asLong(-1), recipe.path("title").asText(),
                        ingredient.path("ingredientName").asText());
                return false;
            }

            String name = ingredient.path("ingredientName").asText();
            String norm = ingredient.path("normalizedName").asText();
            String normalizedIngName = normalize(name);
            String normalizedIngNorm = normalize(norm);

            for (String term : userAllergyTerms) {
                if ((!normalizedIngName.isBlank() && AllergenDetector.matchesWord(normalizedIngName, term))
                        || (!normalizedIngNorm.isBlank() && AllergenDetector.matchesWord(normalizedIngNorm, term))) {
                    return false;
                }
            }

            Set<String> detectedAllergenCodes = AllergenDetector.detectAllergenCodes(name, norm);
            for (String detectedCode : detectedAllergenCodes) {
                if (userAllergyCodes.contains(detectedCode)) {
                    return false;
                }
            }

            if (allergenNode.asBoolean(false) && detectedAllergenCodes.isEmpty()) {
                log.warn("Excluding recipe id={}, title='{}': ingredient '{}' has unverified allergen flag",
                        recipe.path("id").asLong(-1), recipe.path("title").asText(), name);
                return false;
            }
        }
        return true;
    }

    public boolean containsAvailableIngredient(JsonNode recipe, Set<String> available) {
        for (JsonNode ingredient : recipe.path("ingredients")) {
            String value = normalize(ingredient.path("ingredientName").asText());
            String normalizedName = normalize(ingredient.path("normalizedName").asText());
            for (String wanted : available) if ((!value.isBlank() && (value.contains(wanted) || wanted.contains(value)))
                    || (!normalizedName.isBlank() && (normalizedName.contains(wanted) || wanted.contains(normalizedName)))) return true;
        }
        return false;
    }

    public Set<String> normalized(List<String> values) {
        Set<String> result = new HashSet<>();
        if (values != null) values.forEach(value -> addTerm(result, value));
        return result;
    }

    private void addTerm(Set<String> terms, String value) {
        String normalized = normalize(value);
        if (!normalized.isBlank()) terms.add(normalized);
    }

    private String normalize(String value) {
        if (value == null) return "";
        return Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "").toLowerCase(Locale.ROOT).trim();
    }

    private void checkRange(BigDecimal min, BigDecimal max) {
        if (min != null && max != null && min.compareTo(max) > 0) throw new AppException(ErrorCode.INVALID_REQUEST);
    }

    // A day that misses the target is flagged, not rejected: one off metric on one day used to fail
    // the whole 7-day plan. Only the supplied calorie range decides targetMet;
    // allTargetsMet covers every supplied range; deviations explain each miss. Stale flags are cleared because replace()
    // re-runs this on a stored plan.
    public void markTarget(ObjectNode dayNode, Macro value, MealPlanDtos.NutritionTarget target) {
        dayNode.remove(List.of("targetMet", "allTargetsMet", "targetDeviations"));
        if (target == null) return;
        ObjectNode deviations = mapper.createObjectNode();
        addDeviation(deviations, "calories", value.calories, target.minCalories(), target.maxCalories());
        addDeviation(deviations, "protein", value.protein, target.minProtein(), target.maxProtein());
        addDeviation(deviations, "carbohydrate", value.carbohydrate, target.minCarbohydrate(), target.maxCarbohydrate());
        addDeviation(deviations, "fat", value.fat, target.minFat(), target.maxFat());
        dayNode.put("targetMet", !deviations.has("calories"));
        dayNode.put("allTargetsMet", deviations.isEmpty());
        if (!deviations.isEmpty()) dayNode.set("targetDeviations", deviations);
    }

    private void addDeviation(ObjectNode deviations, String metric, BigDecimal value, BigDecimal min, BigDecimal max) {
        if (inside(value, min, max)) return;
        ObjectNode deviation = deviations.putObject(metric);
        deviation.put("actual", value.setScale(2, RoundingMode.HALF_UP));
        if (min != null) deviation.put("min", min);
        if (max != null) deviation.put("max", max);
    }

    private boolean inside(BigDecimal value, BigDecimal min, BigDecimal max) {
        return (min == null || value.compareTo(min) >= 0) && (max == null || value.compareTo(max) <= 0);
    }

    private AppException invalidAi() { return new AppException(ErrorCode.INVALID_AI_RESPONSE); }

    public static final class Macro {
        private BigDecimal calories = BigDecimal.ZERO;
        private BigDecimal protein = BigDecimal.ZERO;
        private BigDecimal carbohydrate = BigDecimal.ZERO;
        private BigDecimal fat = BigDecimal.ZERO;

        public Macro() {}

        public Macro(BigDecimal calories, BigDecimal protein, BigDecimal carbohydrate, BigDecimal fat) {
            this.calories = calories != null ? calories : BigDecimal.ZERO;
            this.protein = protein != null ? protein : BigDecimal.ZERO;
            this.carbohydrate = carbohydrate != null ? carbohydrate : BigDecimal.ZERO;
            this.fat = fat != null ? fat : BigDecimal.ZERO;
        }

        public void add(Macro other) {
            calories = calories.add(other.calories);
            protein = protein.add(other.protein);
            carbohydrate = carbohydrate.add(other.carbohydrate);
            fat = fat.add(other.fat);
        }

        public Macro plus(Macro other) {
            Macro result = new Macro(calories, protein, carbohydrate, fat);
            result.add(other);
            return result;
        }

        public Macro multiply(BigDecimal factor) {
            return new Macro(
                    calories.multiply(factor),
                    protein.multiply(factor),
                    carbohydrate.multiply(factor),
                    fat.multiply(factor)
            );
        }

        public ObjectNode toJson(ObjectMapper mapper) {
            ObjectNode node = mapper.createObjectNode();
            node.put("calories", rounded(calories));
            node.put("protein", rounded(protein));
            node.put("carbohydrate", rounded(carbohydrate));
            node.put("fat", rounded(fat));
            return node;
        }

        private BigDecimal rounded(BigDecimal value) { return value.setScale(2, RoundingMode.HALF_UP); }

        public BigDecimal getCalories() { return calories; }
        public BigDecimal getProtein() { return protein; }
        public BigDecimal getCarbohydrate() { return carbohydrate; }
        public BigDecimal getFat() { return fat; }
    }
}
