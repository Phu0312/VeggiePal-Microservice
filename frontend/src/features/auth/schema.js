import { z } from "zod";

// Luật kiểm tra dữ liệu form đăng nhập.
// react-hook-form + zodResolver sẽ dùng schema này để validate và sinh message lỗi.
// Backend (/auth/login) chỉ chấp nhận email, không hỗ trợ số điện thoại/username.
export const loginSchema = z.object({
    email: z
        .string()
        .trim()
        .min(1, "Vui lòng nhập email")
        .email("Email không hợp lệ"),
    password: z.string().min(6, "Mật khẩu tối thiểu 6 ký tự"),
    remember: z.boolean().optional(),
});

// Luật kiểm tra dữ liệu form đăng ký, khớp RegisterRequest của identity-service.
export const registerSchema = z
    .object({
        fullName: z.string().trim().min(1, "Vui lòng nhập họ và tên"),
        email: z
            .string()
            .trim()
            .min(1, "Vui lòng nhập email")
            .email("Email không hợp lệ"),
        phone: z.string().trim().optional().or(z.literal("")),
        password: z.string().min(6, "Mật khẩu tối thiểu 6 ký tự"),
        confirmPassword: z.string().min(1, "Vui lòng nhập lại mật khẩu"),
    })
    .refine((data) => data.password === data.confirmPassword, {
        message: "Mật khẩu nhập lại không khớp",
        path: ["confirmPassword"],
    });
