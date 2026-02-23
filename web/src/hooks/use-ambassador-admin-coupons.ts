"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  AdminCoupon,
  AdminCouponListItem,
  CreateCouponPayload,
  UpdateCouponPayload,
} from "@/types/admin";

interface CouponFilters {
  status?: string;
  search?: string;
}

export function useAmbassadorAdminCoupons(filters: CouponFilters = {}) {
  const params = new URLSearchParams();
  if (filters.status) params.set("status", filters.status);
  if (filters.search) params.set("search", filters.search);

  const queryString = params.toString();
  const url = queryString
    ? `${API_URLS.AMBASSADOR_ADMIN_COUPONS}?${queryString}`
    : API_URLS.AMBASSADOR_ADMIN_COUPONS;

  return useQuery<AdminCouponListItem[]>({
    queryKey: ["ambassador-admin", "coupons", filters],
    queryFn: () => apiClient.get<AdminCouponListItem[]>(url),
    staleTime: 5 * 60 * 1000,
  });
}

export function useAmbassadorAdminCouponDetail(id: number) {
  return useQuery<AdminCoupon>({
    queryKey: ["ambassador-admin", "coupons", id],
    queryFn: () =>
      apiClient.get<AdminCoupon>(API_URLS.ambassadorAdminCouponDetail(id)),
    enabled: id > 0,
  });
}

export function useAmbassadorAdminCreateCoupon() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateCouponPayload) =>
      apiClient.post<AdminCoupon>(API_URLS.AMBASSADOR_ADMIN_COUPONS, data),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["ambassador-admin", "coupons"],
      });
    },
  });
}

export function useAmbassadorAdminUpdateCoupon() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: UpdateCouponPayload }) =>
      apiClient.patch<AdminCoupon>(
        API_URLS.ambassadorAdminCouponDetail(id),
        data,
      ),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["ambassador-admin", "coupons"],
      });
      queryClient.invalidateQueries({
        queryKey: ["ambassador-admin", "coupons", variables.id],
      });
    },
  });
}

export function useAmbassadorAdminDeleteCoupon() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) =>
      apiClient.delete(API_URLS.ambassadorAdminCouponDetail(id)),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["ambassador-admin", "coupons"],
      });
    },
  });
}
