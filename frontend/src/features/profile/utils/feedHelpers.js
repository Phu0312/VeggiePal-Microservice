/**
 * Tiện ích chuẩn hoá và gộp danh sách bài viết + công thức cho RecipeFeedCard.
 */

export function getStatusBadgeText(status) {
  switch (status) {
    case "PUBLISHED":
      return "#đã_xuất_bản";
    case "PENDING":
      return "#chờ_duyệt";
    case "DRAFT":
      return "#bản_nháp";
    case "REJECTED":
      return "#từ_chối";
    case "BANNED":
      return "#bị_khóa";
    case "HIDDEN":
      return "#đã_ẩn";
    default:
      return status ? `#${String(status).toLowerCase()}` : "#công_khai";
  }
}

/**
 * Gộp bài viết và công thức của người dùng thành 1 danh sách đồng nhất,
 * sắp xếp theo ngày tạo/ngày đăng mới nhất trước.
 */
export function mergeAndSortContent(blogs = [], recipes = []) {
  const blogItems = (blogs ?? []).map((b) => ({
    id: `blog-${b.id}`,
    originalId: b.id,
    type: "blog",
    title: b.title || "Bài viết không tên",
    description: null,
    imageUrl: b.thumbnailUrl || null,
    date: b.publishedAt || b.createdAt,
    status: b.status,
    categoryName: b.categoryName || null,
    viewCount: b.viewCount ?? null,
    voteScore: b.voteScore ?? null,
    ingredients: null,
    link: `/blog/${b.id}`,
    rawBlog: b,
  }));

  const recipeItems = (recipes ?? []).map((r) => ({
    id: `recipe-${r.id}`,
    originalId: r.id,
    type: "recipe",
    title: r.title || "Công thức không tên",
    description: r.description || null,
    imageUrl: r.imageUrl || null,
    date: r.publishedAt || r.createdAt,
    status: r.status,
    categoryName: null,
    servings: r.servings ?? null,
    prepTime: r.prepTimeMinutes ?? r.prepTime ?? null,
    cookTime: r.cookTimeMinutes ?? r.cookTime ?? null,
    ingredients: Array.isArray(r.ingredients) ? r.ingredients : null,
    link: `/recipes/${r.id}`,
    rawRecipe: r,
  }));

  return [...blogItems, ...recipeItems].sort((a, b) => {
    const timeA = new Date(a.date).getTime() || 0;
    const timeB = new Date(b.date).getTime() || 0;
    return timeB - timeA;
  });
}
