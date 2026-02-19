"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type {
  Ambassador,
  AmbassadorReferral,
  AmbassadorCommission,
  CreateAmbassadorPayload,
} from "@/types/ambassador";

export function useAdminAmbassadors(
  page: number = 1,
  search: string = "",
  status: string = "",
) {
  const params = new URLSearchParams();
  params.set("page", String(page));
  if (search) params.set("search", search);
  if (status) params.set("status", status);

  return useQuery<PaginatedResponse<Ambassador>>({
    queryKey: ["admin-ambassadors", page, search, status],
    queryFn: () =>
      apiClient.get<PaginatedResponse<Ambassador>>(
        `${API_URLS.ADMIN_AMBASSADORS}?${params.toString()}`,
      ),
  });
}

export function useAdminAmbassadorDetail(id: number) {
  return useQuery<
    Ambassador & {
      referrals: AmbassadorReferral[];
      commissions: AmbassadorCommission[];
    }
  >({
    queryKey: ["admin-ambassador", id],
    queryFn: () =>
      apiClient.get(API_URLS.adminAmbassadorDetail(id)),
    enabled: id > 0,
  });
}

export function useCreateAmbassador() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateAmbassadorPayload) =>
      apiClient.post<Ambassador>(API_URLS.ADMIN_AMBASSADOR_CREATE, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-ambassadors"] });
    },
  });
}

export function useUpdateAmbassador(id: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: Partial<{ commission_rate: number; is_active: boolean }>) =>
      apiClient.patch<Ambassador>(API_URLS.adminAmbassadorDetail(id), data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin-ambassadors"] });
      queryClient.invalidateQueries({ queryKey: ["admin-ambassador", id] });
    },
  });
}

export function useApproveCommission(ambassadorId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (commissionId: number) =>
      apiClient.post(
        API_URLS.adminCommissionApprove(ambassadorId, commissionId),
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["admin-ambassador", ambassadorId],
      });
    },
  });
}

export function usePayCommission(ambassadorId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (commissionId: number) =>
      apiClient.post(
        API_URLS.adminCommissionPay(ambassadorId, commissionId),
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["admin-ambassador", ambassadorId],
      });
    },
  });
}

export function useBulkApproveCommissions(ambassadorId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      apiClient.post(API_URLS.adminBulkApprove(ambassadorId)),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["admin-ambassador", ambassadorId],
      });
    },
  });
}

export function useBulkPayCommissions(ambassadorId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      apiClient.post(API_URLS.adminBulkPay(ambassadorId)),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["admin-ambassador", ambassadorId],
      });
    },
  });
}

export function useTriggerPayout(ambassadorId: number) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () =>
      apiClient.post(API_URLS.adminTriggerPayout(ambassadorId)),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["admin-ambassador", ambassadorId],
      });
      queryClient.invalidateQueries({ queryKey: ["admin-ambassadors"] });
    },
  });
}
