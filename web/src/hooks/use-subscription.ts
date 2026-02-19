"use client";

import { useQuery, useMutation } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { PaginatedResponse } from "@/types/api";
import type {
  StripeConnectStatus,
  TrainerPayment,
  TrainerSubscriber,
  TrainerPricing,
} from "@/types/subscription";

export function useStripeConnectStatus() {
  return useQuery<StripeConnectStatus>({
    queryKey: ["stripe-connect-status"],
    queryFn: () =>
      apiClient.get<StripeConnectStatus>(API_URLS.STRIPE_CONNECT_STATUS),
  });
}

export function useStripeConnectOnboard() {
  return useMutation({
    mutationFn: () =>
      apiClient.post<{ url: string }>(API_URLS.STRIPE_CONNECT_ONBOARD),
  });
}

export function useStripeConnectDashboard() {
  return useQuery<{ url: string }>({
    queryKey: ["stripe-connect-dashboard"],
    queryFn: () =>
      apiClient.get<{ url: string }>(API_URLS.STRIPE_CONNECT_DASHBOARD),
    enabled: false,
  });
}

export function useTrainerPricing() {
  return useQuery<TrainerPricing>({
    queryKey: ["trainer-pricing"],
    queryFn: () => apiClient.get<TrainerPricing>(API_URLS.TRAINER_PRICING),
  });
}

export function useTrainerPayments(page: number = 1) {
  return useQuery<PaginatedResponse<TrainerPayment>>({
    queryKey: ["trainer-payments", page],
    queryFn: () =>
      apiClient.get<PaginatedResponse<TrainerPayment>>(
        `${API_URLS.TRAINER_PAYMENTS}?page=${page}`,
      ),
  });
}

export function useTrainerSubscribers(page: number = 1) {
  return useQuery<PaginatedResponse<TrainerSubscriber>>({
    queryKey: ["trainer-subscribers", page],
    queryFn: () =>
      apiClient.get<PaginatedResponse<TrainerSubscriber>>(
        `${API_URLS.TRAINER_SUBSCRIBERS}?page=${page}`,
      ),
  });
}
