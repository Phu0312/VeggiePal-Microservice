// Khóa cache React Query của feature ingredient (nguyên liệu).
export const ingredientKeys = {
  all: ["ingredients"],
  list: (params) => ["ingredients", "list", params],
  detail: (id) => ["ingredients", "detail", id],
};
