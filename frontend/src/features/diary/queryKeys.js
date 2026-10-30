// Khóa cache của nhật ký: mọi thứ trong một ngày cùng tiền tố `day(date)` để ghi món / nước xong làm mới một lần.
export const diaryKeys = {
  all: ["nutrition", "diary"],
  day: (date) => ["nutrition", "diary", date],
  summary: (date, goalType) => ["nutrition", "diary", date, "summary", { goalType }],
};
