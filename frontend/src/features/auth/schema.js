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

const emailField = z.string().trim().min(1, "Vui lòng nhập email").email("Email không hợp lệ");
// Mã OTP của identity-service luôn là 6 chữ số.
const otpField = z.string().trim().regex(/^\d{6}$/, "Mã OTP gồm 6 chữ số");

// Quên mật khẩu, bước 1: email nhận mã.
export const forgotEmailSchema = z.object({ email: emailField });

// Bước 2 (và xác minh email): mã OTP 6 số.
export const otpSchema = z.object({ otp: otpField });

// Bước 3: mật khẩu mới (ResetPasswordRequest: tối thiểu 6 ký tự).
export const resetPasswordSchema = z
    .object({
        newPassword: z.string().min(6, "Mật khẩu tối thiểu 6 ký tự"),
        confirmPassword: z.string().min(1, "Vui lòng nhập lại mật khẩu"),
    })
    .refine((data) => data.newPassword === data.confirmPassword, {
        message: "Mật khẩu nhập lại không khớp",
        path: ["confirmPassword"],
    });
