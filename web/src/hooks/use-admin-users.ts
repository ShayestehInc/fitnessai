"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  AdminUser,
  CreateUserPayload,
  UpdateUserPayload,
} from "@/types/admin";

interface UserFilters {
  role?: string;
  search?: string;
}

export function useAdminUsers(filters: UserFilters = {}) {
  const params = new URLSearchParams();
  if (filters.role) params.set("role", filters.role);
  if (filters.search) params.set("search", filters.search);

  const queryString = params.toString();
  const url = queryString
    ? `${API_URLS.ADMIN_USERS}?${queryString}`
    : API_URLS.ADMIN_USERS;

  return useQuery<AdminUser[]>({
    queryKey: ["admin", "users", filters],
    queryFn: () => apiClient.get<AdminUser[]>(url),
    staleTime: 5 * 60 * 1000,
  });
}

export function useAdminUser(id: number) {
  return useQuery<AdminUser>({
    queryKey: ["admin", "users", id],
    queryFn: () =>
      apiClient.get<AdminUser>(API_URLS.adminUserDetail(id)),
    enabled: id > 0,
  });
}

export function useCreateAdminUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateUserPayload) =>
      apiClient.post<{ success: boolean; user: AdminUser }>(
        API_URLS.ADMIN_USERS_CREATE,
        data,
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "dashboard"] });
    },
  });
}

export function useUpdateAdminUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: UpdateUserPayload }) =>
      apiClient.patch<AdminUser>(API_URLS.adminUserDetail(id), data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "dashboard"] });
    },
  });
}

export function useDeleteAdminUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      apiClient.delete<{ success: boolean; message: string }>(
        API_URLS.adminUserDetail(id),
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "dashboard"] });
    },
  });
}
