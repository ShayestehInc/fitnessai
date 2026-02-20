"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type {
  AmbassadorDashboardData,
  AmbassadorSelfReferral,
  AmbassadorPayout,
  AmbassadorConnectStatus,
} from "@/types/ambassador";

export function useAmbassadorDashboard() {
  return useQuery<AmbassadorDashboardData>({
    queryKey: ["ambassador-dashboard"],
    queryFn: () =>
      apiClient.get<AmbassadorDashboardData>(API_URLS.AMBASSADOR_DASHBOARD),
  });
}

export function useAmbassadorReferralCode() {
  return useQuery<{ referral_code: string }>({
    queryKey: ["ambassador-referral-code"],
    queryFn: () =>
      apiClient.get<{ referral_code: string }>(API_URLS.AMBASSADOR_REFERRAL_CODE),
  });
}

export function useUpdateReferralCode() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (referral_code: string) =>
      apiClient.put<{ referral_code: string }>(
        API_URLS.AMBASSADOR_REFERRAL_CODE,
        { referral_code },
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["ambassador-referral-code"] });
      queryClient.invalidateQueries({ queryKey: ["ambassador-dashboard"] });
    },
  });
}

export function useAmbassadorReferrals(
  status: string = "",
  page: number = 1,
) {
  const params = new URLSearchParams();
  params.set("page", String(page));
  if (status) params.set("status", status);

  return useQuery<PaginatedResponse<AmbassadorSelfReferral>>({
    queryKey: ["ambassador-referrals", status, page],
    queryFn: () =>
      apiClient.get<PaginatedResponse<AmbassadorSelfReferral>>(
        `${API_URLS.AMBASSADOR_REFERRALS}?${params.toString()}`,
      ),
  });
}

export function useAmbassadorPayouts(page: number = 1) {
  return useQuery<PaginatedResponse<AmbassadorPayout>>({
    queryKey: ["ambassador-payouts", page],
    queryFn: () =>
      apiClient.get<PaginatedResponse<AmbassadorPayout>>(
        `${API_URLS.AMBASSADOR_PAYOUTS}?page=${page}`,
      ),
  });
}

export function useAmbassadorConnectStatus() {
  return useQuery<AmbassadorConnectStatus>({
    queryKey: ["ambassador-connect-status"],
    queryFn: () =>
      apiClient.get<AmbassadorConnectStatus>(API_URLS.AMBASSADOR_CONNECT_STATUS),
  });
}

export function useAmbassadorConnectOnboard() {
  return useMutation({
    mutationFn: () =>
      apiClient.post<{ url: string }>(API_URLS.AMBASSADOR_CONNECT_ONBOARD),
  });
}
