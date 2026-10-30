import apiClient from "@/shared/api/apiClient";

/**
 * Quản lý người dùng (identity-service qua api-gateway /admin/users, chỉ ADMIN):
 *   GET   /admin/users?keyword=&role=&status=&page=&size=  -> Page<UserProfileResponse>
 *   PATCH /admin/users/:id/status { status }  (PENDING | ACTIVE | INACTIVE | BLOCKED)
 *   PATCH /admin/users/:id/role   { role }    (USER | ADMIN)
 * Page: { content, page, size, totalElements, totalPages, first, last }
 */

const VI_MESSAGES = {
  1007: "Không tìm thấy người dùng",
  1008: "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại",
  1009: "Bạn không có quyền thực hiện thao tác này",
  1018: "Dữ liệu không hợp lệ",
  1020: "Người dùng đã ở trạng thái này, danh sách đã được tải lại",
  1022: "Bạn không thể tự khóa hoặc tự hạ quyền tài khoản của chính mình",
  1023: "Người dùng đã có vai trò này, danh sách đã được tải lại",
};

function unwrap(res, fallbackMessage) {
  if (res.status >= 400) {
    const error = new Error(VI_MESSAGES[res.data?.code] ?? fallbackMessage);
    error.code = res.data?.code;
    throw error;
  }
  return res.data?.result;
}

async function send(request) {
  try {
    return await request();
  } catch (error) {
    throw new Error("Không kết nối được máy chủ, vui lòng thử lại", { cause: error });
  }
}

export async function getAdminUsers({ keyword, role, status, page = 0, size = 20 } = {}) {
  const res = await send(() =>
    apiClient.get("/admin/users", {
      params: {
        keyword: keyword || undefined,
        role: role || undefined,
        status: status || undefined,
        page,
        size,
      },
    })
  );
  return unwrap(res, "Không tải được danh sách người dùng");
}

export async function updateUserStatus(id, status) {
  const res = await send(() => apiClient.patch(`/admin/users/${id}/status`, { status }));
  return unwrap(res, "Không đổi được trạng thái người dùng");
}

export async function updateUserRole(id, role) {
  const res = await send(() => apiClient.patch(`/admin/users/${id}/role`, { role }));
  return unwrap(res, "Không đổi được vai trò người dùng");
}
