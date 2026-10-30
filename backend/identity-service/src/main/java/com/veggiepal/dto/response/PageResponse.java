package com.veggiepal.dto.response;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonGetter;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class PageResponse<T> {

    List<T> content;

    int page;

    int size;

    long totalElements;

    int totalPages;

    boolean first;

    boolean last;

    @JsonGetter("items")
    public List<T> getItems() {
        return content;
    }
}

