package com.veggiepal.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum BadgeCode {

    GREEN_STARTER(
            "Khởi Đầu Sống Xanh",
            "Gia nhập cộng đồng thuần chay VeggiePal",
            "sprout"
    ),
    VERIFIED_MEMBER(
            "Thành Viên Xác Thực",
            "Đã xác thực địa chỉ email tài khoản",
            "check"
    ),
    COMPLETE_PROFILE(
            "Hồ Sơ Xanh Hoàn Thiện",
            "Hoàn thiện đầy đủ thông tin cá nhân và mức vận động",
            "user"
    ),
    VEGGIE_GREEN_HEART(
            "Trái Tim Xanh Veggie",
            "Hoàn thành thử thách 7 Ngày Sống Thuần Chay Tươi Mới",
            "calendar"
    ),
    ZERO_WASTE_CHEF(
            "Bếp Trưởng Zero-Waste",
            "Tái chế vỏ rau củ làm nước dùng thanh ngọt",
            "droplets"
    ),
    AI_MASTER_CHEF(
            "AI Master Chef",
            "Tối ưu công thức đạt chuẩn gợi ý dinh dưỡng từ AI",
            "sparkles"
    );

    final String title;
    final String description;
    final String icon;
}

