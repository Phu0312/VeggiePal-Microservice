package com.veggiepal.moderation.service;

import com.veggiepal.moderation.dto.response.ModerationResult;

public interface ContentModerationService {

    ModerationResult moderate(String text);
}
