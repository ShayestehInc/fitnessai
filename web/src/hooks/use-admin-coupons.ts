"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  AdminCoupon,
  AdminCouponListItem,
  AdminCouponUsage,
  CreateCouponPayload,
  UpdateCouponPayload,
} from "@/types/admin";

interface CouponFilters {
  status?: string;
  type?: string;
  applies_to?: string;
  search?: string;
}

export function useAdminCoupons(filters: CouponFilters = {}) {
  const params = new URLSearchParams();
  if (filters.status) params.set("status", filters.status);
  if (filters.type) params.set("type", filters.type);
  if (filters.applies_to) params.set("applies_to", filters.applies_to);
  if (filters.search) params.set("search", filters.search);

  const queryString = params.toString();
  const url = queryString
    ? `${API_URLS.ADMIN_COUPONS}?${queryString}`
    : API_URLS.ADMIN_COUPONS;

  return useQuery<AdminCouponListItem[]>({
    queryKey: ["admin", "coupons", filters],
    queryFn: () => apiClient.get<AdminCouponListItem[]>(url),
    staleTime: 5 * 60 * 1000,
  });
}

export function useAdminCoupon(id: number) {
  return useQuery<AdminCoupon>({
    queryKey: ["admin", "coupons", id],
    queryFn: () =>
      apiClient.get<AdminCoupon>(API_URLS.adminCouponDetail(id)),
    enabled: id > 0,
  });
}

export function useCouponUsages(id: number) {
  return useQuery<AdminCouponUsage[]>({
    queryKey: ["admin", "coupons", id, "usages"],
    queryFn: () =>
      apiClient.get<AdminCouponUsage[]>(API_URLS.adminCouponUsages(id)),
    enabled: id > 0,
  });
}

export function useCreateCoupon() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateCouponPayload) =>
      apiClient.post<AdminCoupon>(API_URLS.ADMIN_COUPONS, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "coupons"] });
    },
  });
}

export function useUpdateCoupon() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: UpdateCouponPayload }) =>
      apiClient.patch<AdminCoupon>(API_URLS.adminCouponDetail(id), data),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "coupons"] });
      queryClient.invalidateQueries({
        queryKey: ["admin", "coupons", variables.id],
      });
    },
  });
}

export function useDeleteCoupon() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      apiClient.delete(API_URLS.adminCouponDetail(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "coupons"] });
    },
  });
}

export function useRevokeCoupon() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      apiClient.post<AdminCoupon>(API_URLS.adminCouponRevoke(id)),
    onSuccess: (_data, id) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "coupons"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "coupons", id] });
    },
  });
}

export function useReactivateCoupon() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      apiClient.post<AdminCoupon>(API_URLS.adminCouponReactivate(id)),
    onSuccess: (_data, id) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "coupons"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "coupons", id] });
    },
  });
}
