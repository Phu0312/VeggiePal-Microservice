package com.veggiepal.recipe.service;

import java.io.IOException;
import java.text.Normalizer;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.veggiepal.recipe.dto.request.RecipeIngredientRequest;
import com.veggiepal.recipe.dto.request.RecipeRequest;
import com.veggiepal.recipe.dto.request.RecipeStepRequest;
import com.veggiepal.recipe.dto.response.ImageUploadResponse;
import com.veggiepal.recipe.dto.response.PageResponse;
import com.veggiepal.recipe.dto.response.RecipeLikeResponse;
import com.veggiepal.recipe.dto.response.RecipeResponse;
import com.veggiepal.recipe.entity.Ingredient;
import com.veggiepal.recipe.entity.Recipe;
import com.veggiepal.recipe.entity.RecipeIngredient;
import com.veggiepal.recipe.entity.RecipeLike;
import com.veggiepal.recipe.entity.RecipeStep;
import com.veggiepal.recipe.enums.ImageType;
import com.veggiepal.recipe.enums.RecipeStatus;
import com.veggiepal.recipe.exception.AppException;
import com.veggiepal.recipe.exception.ErrorCode;
import com.veggiepal.recipe.mapper.RecipeMapper;
import com.veggiepal.recipe.repository.IngredientRepository;
import com.veggiepal.recipe.repository.RecipeLikeRepository;
import com.veggiepal.recipe.repository.RecipeRepository;

import lombok.AccessLevel;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Service
@FieldDefaults(
        level = AccessLevel.PRIVATE,
        makeFinal = true
)
@Slf4j
public class RecipeService {

    private static final long MAX_IMAGE_BYTES = 5L * 1024 * 1024;
    private static final int MAX_LIKE_LOOKUP_IDS = 200;

    private static final Sort NEWEST_FIRST = Sort.by(Sort.Direction.DESC, "createdAt");
    private static final Sort POPULAR_FIRST = Sort.by(
            Sort.Order.desc("likeCount"),
            Sort.Order.desc("publishedAt"),
            Sort.Order.desc("createdAt")
    );

    private static final Set<String> SUPPORTED_UNITS = Set.of(
            "g", "gram", "grams", "gr", "gam",
            "kg", "kilogram", "kilograms", "kilo",
            "mg", "milligram", "milligrams",
            "ml", "milliliter", "milliliters", "mililit",
            "l", "liter", "liters", "lit",
            "muong canh", "thia canh", "tbsp", "tablespoon",
            "muong ca phe", "thia ca phe", "tsp", "teaspoon",
            "qua", "trai", "cu", "bap", "tep", "cay", "mieng", "bia", "la",
            "piece", "pieces", "pcs"
    );

    RecipeRepository recipeRepository;
    IngredientRepository ingredientRepository;
    RecipeMapper recipeMapper;
    RecipeLikeRepository recipeLikeRepository;
    FileStorageService fileStorageService;

    public RecipeService(
            RecipeRepository recipeRepository,
            IngredientRepository ingredientRepository,
            RecipeMapper recipeMapper
    ) {
        this(recipeRepository, ingredientRepository, recipeMapper, null, null);
    }

    @Autowired
    public RecipeService(
            RecipeRepository recipeRepository,
            IngredientRepository ingredientRepository,
            RecipeMapper recipeMapper,
            RecipeLikeRepository recipeLikeRepository,
            FileStorageService fileStorageService
    ) {
        this.recipeRepository = recipeRepository;
        this.ingredientRepository = ingredientRepository;
        this.recipeMapper = recipeMapper;
        this.recipeLikeRepository = recipeLikeRepository;
        this.fileStorageService = fileStorageService;
    }

    @Transactional
    public RecipeResponse createRecipe(
            Long userId,
            RecipeRequest request
    ) {

        validateRecipeItems(request);

        Recipe recipe = Recipe
                .builder()
                .userId(userId)
                .title(
                        request.getTitle().trim()
                )
                .description(
                        trimToNull(
                                request.getDescription()
                        )
                )
                .imageUrl(
                        trimToNull(
                                request.getImageUrl()
                        )
                )
                .servings(
                        request.getServings()
                )
                .prepTime(
                        request.getPrepTime()
                )
                .cookTime(
                        request.getCookTime()
                )
                .status(
                        RecipeStatus.DRAFT
                )
                .likeCount(0)
                .build();

        for (
                RecipeIngredientRequest item
                : request.getIngredients()
        ) {

            Ingredient ingredient = requireActiveIngredient(item.getIngredientId());

            RecipeIngredient recipeIngredient =
                    RecipeIngredient
                            .builder()
                            .ingredient(
                                    ingredient
                            )
                            .quantity(
                                    item.getQuantity()
                            )
                            .unit(
                                    normalizeAndValidateUnit(item.getUnit())
                            )
                            .note(
                                    trimToNull(
                                            item.getNote()
                                    )
                            )
                            .build();

            recipe.addIngredient(
                    recipeIngredient
            );
        }

        for (
                RecipeStepRequest item
                : request.getSteps()
        ) {

            RecipeStep step =
                    RecipeStep
                            .builder()
                            .stepNumber(
                                    item.getStepNumber()
                            )
                            .instruction(
                                    item.getInstruction()
                                            .trim()
                            )
                            .build();

            recipe.addStep(step);
        }

        Recipe saved =
                recipeRepository.save(recipe);

        return recipeMapper
                .toRecipeResponse(saved);
    }

    @Transactional(readOnly = true)
    public RecipeResponse getRecipe(
            Long id
    ) {
        return getRecipe(id, null, false);
    }

    @Transactional(readOnly = true)
    public RecipeResponse getRecipe(
            Long id,
            Long requesterId,
            boolean admin
    ) {
        Recipe recipe = findById(id);

        if (recipe.getStatus() == RecipeStatus.DRAFT || recipe.getStatus() == RecipeStatus.HIDDEN) {
            if (requesterId == null || (!admin && !recipe.getUserId().equals(requesterId))) {
                throw new AppException(ErrorCode.RECIPE_NOT_EXISTED);
            }
        }

        return recipeMapper
                .toRecipeResponse(recipe);
    }

    @Transactional(readOnly = true)
    public PageResponse<RecipeResponse>
    getPublishedRecipes(
            String keyword,
            int page,
            int size
    ) {
        return getPublishedRecipes(keyword, null, page, size);
    }

    @Transactional(readOnly = true)
    public PageResponse<RecipeResponse>
    getPublishedRecipes(
            String keyword,
            String sort,
            int page,
            int size
    ) {

        int safePage =
                Math.max(page, 0);

        int safeSize =
                Math.min(
                        Math.max(size, 1),
                        200
                );

        Pageable pageable =
                PageRequest.of(
                        safePage,
                        safeSize,
                        sortFor(sort)
                );

        String safeKeyword =
                normalizeKeyword(keyword);

        Page<Recipe> recipePage =
                recipeRepository
                        .searchPublished(
                                safeKeyword,
                                RecipeStatus.PUBLISHED,
                                pageable
                        );

        return toPageResponse(
                recipePage
        );
    }

    @Transactional(readOnly = true)
    public PageResponse<RecipeResponse> getPopularRecipes(
            int page,
            int size
    ) {
        return getPublishedRecipes(null, "popular", page, size);
    }

    @Transactional(readOnly = true)
    public PageResponse<RecipeResponse>
    getMyRecipes(
            Long userId,
            int page,
            int size
    ) {

        Pageable pageable =
                PageRequest.of(
                        Math.max(page, 0),
                        Math.min(
                                Math.max(size, 1),
                                100
                        ),
                        NEWEST_FIRST
                );

        Page<Recipe> recipePage =
                recipeRepository
                        .findByUserIdAndStatusNot(
                                userId,
                                RecipeStatus.ARCHIVED,
                                pageable
                        );

        return toPageResponse(
                recipePage
        );
    }

    @Transactional
    public RecipeResponse updateRecipe(
            Long id,
            Long userId,
            boolean admin,
            RecipeRequest request
    ) {

        Recipe recipe =
                findById(id);

        checkOwner(
                recipe,
                userId,
                admin
        );

        ensureMutable(recipe);
        validateRecipeItems(request);

        recipe.setTitle(
                request.getTitle().trim()
        );

        recipe.setDescription(
                trimToNull(
                        request.getDescription()
                )
        );

        recipe.setImageUrl(
                trimToNull(
                        request.getImageUrl()
                )
        );

        recipe.setServings(
                request.getServings()
        );

        recipe.setPrepTime(
                request.getPrepTime()
        );

        recipe.setCookTime(
                request.getCookTime()
        );

        recipe.getIngredients().clear();
        recipe.getSteps().clear();

        // Hibernate may schedule inserts before orphan deletes. Flush the removals first so
        // replacing an ingredient or step with the same unique key cannot produce HTTP 500.
        recipeRepository.flush();

        for (
                RecipeIngredientRequest item
                : request.getIngredients()
        ) {

            Ingredient ingredient = requireActiveIngredient(item.getIngredientId());

            RecipeIngredient recipeIngredient =
                    RecipeIngredient
                            .builder()
                            .ingredient(
                                    ingredient
                            )
                            .quantity(
                                    item.getQuantity()
                            )
                            .unit(
                                    normalizeAndValidateUnit(item.getUnit())
                            )
                            .note(
                                    trimToNull(
                                            item.getNote()
                                    )
                            )
                            .build();

            recipe.addIngredient(
                    recipeIngredient
            );
        }

        for (
                RecipeStepRequest item
                : request.getSteps()
        ) {

            RecipeStep step =
                    RecipeStep
                            .builder()
                            .stepNumber(
                                    item.getStepNumber()
                            )
                            .instruction(
                                    item.getInstruction()
                                            .trim()
                            )
                            .build();

            recipe.addStep(step);
        }

        Recipe saved =
                recipeRepository.save(recipe);

        return recipeMapper
                .toRecipeResponse(saved);
    }

    @Transactional
    public RecipeResponse uploadRecipeImage(
            Long id,
            Long userId,
            boolean admin,
            MultipartFile file
    ) {
        ValidatedImage validated = validateImage(file);

        Recipe recipe = findById(id);
        checkOwner(recipe, userId, admin);
        ensureMutable(recipe);

        String previousImageUrl = recipe.getImageUrl();
        String key = "recipes/" + id + "/" + UUID.randomUUID() + "." + validated.type().getExtension();
        String imageUrl = fileStorageService.upload(key, validated.bytes(), validated.type().getContentType());

        recipe.setImageUrl(imageUrl);
        Recipe saved;
        try {
            saved = recipeRepository.save(recipe);
        } catch (RuntimeException exception) {
            deleteQuietly(imageUrl);
            throw exception;
        }

        deleteQuietly(previousImageUrl);
        return recipeMapper.toRecipeResponse(saved);
    }

    public ImageUploadResponse uploadStandaloneImage(
            Long userId,
            MultipartFile file
    ) {
        ValidatedImage validated = validateImage(file);
        String key = "recipes/uploads/" + userId + "/" + UUID.randomUUID() + "." + validated.type().getExtension();
        String imageUrl = fileStorageService.upload(key, validated.bytes(), validated.type().getContentType());
        return ImageUploadResponse.builder()
                .imageUrl(imageUrl)
                .build();
    }

    @Transactional
    public RecipeLikeResponse likeRecipe(Long userId, Long recipeId) {
        Recipe recipe = requirePublishedRecipe(recipeId);
        int currentLikes = recipe.getLikeCount() == null ? 0 : recipe.getLikeCount();

        if (recipeLikeRepository.findByUserIdAndRecipeId(userId, recipeId).isPresent()) {
            return RecipeLikeResponse.builder()
                    .recipeId(recipeId)
                    .liked(true)
                    .likeCount(currentLikes)
                    .build();
        }

        recipeLikeRepository.save(RecipeLike.builder()
                .userId(userId)
                .recipeId(recipeId)
                .build());
        recipeRepository.addLikeCount(recipeId, 1);

        return RecipeLikeResponse.builder()
                .recipeId(recipeId)
                .liked(true)
                .likeCount(currentLikes + 1)
                .build();
    }

    @Transactional
    public RecipeLikeResponse unlikeRecipe(Long userId, Long recipeId) {
        Recipe recipe = requirePublishedRecipe(recipeId);
        int currentLikes = recipe.getLikeCount() == null ? 0 : recipe.getLikeCount();

        int deleted = recipeLikeRepository.deleteByUserIdAndRecipeId(userId, recipeId);
        int updatedLikes = currentLikes;
        if (deleted > 0) {
            recipeRepository.addLikeCount(recipeId, -1);
            updatedLikes = Math.max(0, currentLikes - 1);
        }

        return RecipeLikeResponse.builder()
                .recipeId(recipeId)
                .liked(false)
                .likeCount(updatedLikes)
                .build();
    }

    @Transactional(readOnly = true)
    public List<RecipeLikeResponse> getMyLikes(Long userId, List<Long> recipeIds) {
        if (recipeIds == null || recipeIds.isEmpty()) {
            throw new AppException(ErrorCode.RECIPE_IDS_REQUIRED);
        }

        Set<Long> uniqueIds = recipeIds.stream()
                .filter(id -> id != null && id > 0)
                .limit(MAX_LIKE_LOOKUP_IDS)
                .collect(Collectors.toCollection(LinkedHashSet::new));

        if (uniqueIds.isEmpty()) {
            throw new AppException(ErrorCode.RECIPE_IDS_REQUIRED);
        }

        Map<Long, Recipe> publishedRecipes = recipeRepository.findAllById(uniqueIds).stream()
                .filter(r -> r.getStatus() == RecipeStatus.PUBLISHED)
                .collect(Collectors.toMap(Recipe::getId, Function.identity()));

        Set<Long> likedIds = recipeLikeRepository.findByUserIdAndRecipeIdIn(userId, publishedRecipes.keySet())
                .stream()
                .map(RecipeLike::getRecipeId)
                .collect(Collectors.toSet());

        return uniqueIds.stream()
                .filter(publishedRecipes::containsKey)
                .map(id -> {
                    Recipe r = publishedRecipes.get(id);
                    return RecipeLikeResponse.builder()
                            .recipeId(id)
                            .liked(likedIds.contains(id))
                            .likeCount(r.getLikeCount() == null ? 0 : r.getLikeCount())
                            .build();
                })
                .toList();
    }

    @Transactional
    public RecipeResponse publishRecipe(
            Long id,
            Long userId,
            boolean admin
    ) {

        Recipe recipe =
                findById(id);

        checkOwner(
                recipe,
                userId,
                admin
        );

        ensureMutable(recipe);

        if (
                recipe.getStatus()
                        == RecipeStatus.PUBLISHED
        ) {

            throw new AppException(
                    ErrorCode
                            .RECIPE_ALREADY_PUBLISHED
            );
        }

        recipe.setStatus(
                RecipeStatus.PUBLISHED
        );

        recipe.setPublishedAt(
                LocalDateTime.now()
        );

        Recipe saved =
                recipeRepository.save(recipe);

        return recipeMapper
                .toRecipeResponse(saved);
    }

    @Transactional
    public void deleteRecipe(
            Long id,
            Long userId,
            boolean admin
    ) {

        Recipe recipe =
                findById(id);

        checkOwner(
                recipe,
                userId,
                admin
        );

        ensureMutable(recipe);

        recipe.setStatus(
                RecipeStatus.ARCHIVED
        );

        recipeRepository.save(
                recipe
        );
    }

    private Recipe requirePublishedRecipe(Long id) {
        return recipeRepository.findByIdAndStatus(id, RecipeStatus.PUBLISHED)
                .orElseThrow(() -> new AppException(ErrorCode.RECIPE_NOT_EXISTED));
    }

    private Recipe findById(
            Long id
    ) {

        return recipeRepository
                .findById(id)
                .orElseThrow(
                        () ->
                                new AppException(
                                        ErrorCode
                                                .RECIPE_NOT_EXISTED
                                )
                );
    }

    private void checkOwner(
            Recipe recipe,
            Long userId,
            boolean admin
    ) {

        if (admin) {
            return;
        }

        if (
                !recipe.getUserId()
                        .equals(userId)
        ) {

            throw new AppException(
                    ErrorCode.RECIPE_FORBIDDEN
            );
        }
    }

    private void validateRecipeItems(RecipeRequest request) {

        Set<Long> ingredientIds =
                new HashSet<>();

        for (
                RecipeIngredientRequest item
                : request.getIngredients()
        ) {

            if (
                    !ingredientIds.add(
                            item.getIngredientId()
                    )
            ) {

                throw new AppException(
                        ErrorCode
                                .DUPLICATE_RECIPE_INGREDIENT
                );
            }
        }

        Set<Integer> stepNumbers = new HashSet<>();
        for (RecipeStepRequest item : request.getSteps()) {
            if (!stepNumbers.add(item.getStepNumber())) {
                throw new AppException(ErrorCode.DUPLICATE_RECIPE_STEP);
            }
        }
    }

    private Ingredient requireActiveIngredient(Long ingredientId) {
        Ingredient ingredient = ingredientRepository.findById(ingredientId)
                .orElseThrow(() -> new AppException(ErrorCode.INGREDIENT_NOT_EXISTED));
        if (!Boolean.TRUE.equals(ingredient.getActive())) {
            throw new AppException(ErrorCode.INGREDIENT_NOT_ACTIVE);
        }
        return ingredient;
    }

    private void ensureMutable(Recipe recipe) {
        if (recipe.getStatus() == RecipeStatus.ARCHIVED || recipe.getStatus() == RecipeStatus.HIDDEN) {
            throw new AppException(ErrorCode.INVALID_RECIPE_STATUS_TRANSITION);
        }
    }

    private String normalizeAndValidateUnit(String rawUnit) {
        String normalized = Normalizer.normalize(rawUnit.trim().toLowerCase(Locale.ROOT), Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .replace('đ', 'd')
                .replace('_', ' ')
                .replaceAll("\\s+", " ");
        if (!SUPPORTED_UNITS.contains(normalized)) {
            throw new AppException(ErrorCode.INVALID_RECIPE_UNIT);
        }
        return rawUnit.trim().toUpperCase(Locale.ROOT);
    }

    private static Sort sortFor(String sort) {
        if (sort != null && "popular".equalsIgnoreCase(sort.trim())) {
            return POPULAR_FIRST;
        }
        return NEWEST_FIRST;
    }

    private ValidatedImage validateImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new AppException(ErrorCode.RECIPE_IMAGE_REQUIRED);
        }
        if (file.getSize() > MAX_IMAGE_BYTES) {
            throw new AppException(ErrorCode.RECIPE_IMAGE_TOO_LARGE);
        }

        byte[] content;
        try {
            content = file.getBytes();
        } catch (IOException exception) {
            throw new AppException(ErrorCode.FILE_UPLOAD_FAILED);
        }

        if (content.length == 0) {
            throw new AppException(ErrorCode.RECIPE_IMAGE_REQUIRED);
        }
        if (content.length > MAX_IMAGE_BYTES) {
            throw new AppException(ErrorCode.RECIPE_IMAGE_TOO_LARGE);
        }

        String declaredContentType = file.getContentType();
        ImageType detectedType = ImageTypeDetector.detect(content)
                .filter(type -> isCompatibleContentType(type, declaredContentType))
                .orElseThrow(() -> new AppException(ErrorCode.INVALID_RECIPE_IMAGE_TYPE));

        return new ValidatedImage(detectedType, content);
    }

    private static boolean isCompatibleContentType(ImageType detected, String declared) {
        if (declared == null || declared.isBlank() || "application/octet-stream".equalsIgnoreCase(declared)) {
            return true;
        }
        if ("image/jpg".equalsIgnoreCase(declared) && detected == ImageType.JPEG) {
            return true;
        }
        return detected.getContentType().equalsIgnoreCase(declared);
    }

    private void deleteQuietly(String url) {
        if (url == null || fileStorageService == null) {
            return;
        }
        try {
            fileStorageService.delete(url);
        } catch (RuntimeException exception) {
            log.warn("Could not delete recipe image object from storage", exception);
        }
    }

    private record ValidatedImage(ImageType type, byte[] bytes) {
    }

    private PageResponse<RecipeResponse>
    toPageResponse(
            Page<Recipe> recipePage
    ) {

        return PageResponse
                .<RecipeResponse>builder()
                .content(
                        recipePage
                                .getContent()
                                .stream()
                                .map(
                                        recipeMapper
                                                ::toRecipeResponse
                                )
                                .toList()
                )
                .page(
                        recipePage.getNumber()
                )
                .size(
                        recipePage.getSize()
                )
                .totalElements(
                        recipePage
                                .getTotalElements()
                )
                .totalPages(
                        recipePage
                                .getTotalPages()
                )
                .first(
                        recipePage.isFirst()
                )
                .last(
                        recipePage.isLast()
                )
                .build();
    }

    private String normalizeKeyword(
            String keyword
    ) {

        if (keyword == null) {
            return null;
        }

        String value =
                keyword.trim();

        return value.isBlank()
                ? null
                : value;
    }

    private String trimToNull(
            String value
    ) {

        if (value == null) {
            return null;
        }

        String trimmed =
                value.trim();

        return trimmed.isBlank()
                ? null
                : trimmed;
    }
}
