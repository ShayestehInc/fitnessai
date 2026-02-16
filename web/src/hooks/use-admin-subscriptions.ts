"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type {
  AdminSubscription,
  AdminSubscriptionListItem,
  AdminPaymentHistory,
  AdminSubscriptionChange,
} from "@/types/admin";

interface SubscriptionFilters {
  status?: string;
  tier?: string;
  past_due?: boolean;
  upcoming_days?: number;
  search?: string;
}

export function useAdminSubscriptions(filters: SubscriptionFilters = {}) {
  const params = new URLSearchParams();
  if (filters.status) params.set("status", filters.status);
  if (filters.tier) params.set("tier", filters.tier);
  if (filters.past_due) params.set("past_due", "true");
  if (filters.upcoming_days)
    params.set("upcoming_days", String(filters.upcoming_days));
  if (filters.search) params.set("search", filters.search);

  const queryString = params.toString();
  const url = queryString
    ? `${API_URLS.ADMIN_SUBSCRIPTIONS}?${queryString}`
    : API_URLS.ADMIN_SUBSCRIPTIONS;

  return useQuery<AdminSubscriptionListItem[]>({
    queryKey: ["admin", "subscriptions", filters],
    queryFn: () => apiClient.get<AdminSubscriptionListItem[]>(url),
    staleTime: 5 * 60 * 1000,
  });
}

export function useAdminSubscription(id: number) {
  return useQuery<AdminSubscription>({
    queryKey: ["admin", "subscriptions", id],
    queryFn: () =>
      apiClient.get<AdminSubscription>(
        API_URLS.adminSubscriptionDetail(id),
      ),
    enabled: id > 0,
  });
}

export function usePastDueSubscriptions() {
  return useQuery<AdminSubscriptionListItem[]>({
    queryKey: ["admin", "past-due"],
    queryFn: () =>
      apiClient.get<AdminSubscriptionListItem[]>(API_URLS.ADMIN_PAST_DUE),
    staleTime: 5 * 60 * 1000,
  });
}

export function usePaymentHistory(subscriptionId: number) {
  return useQuery<AdminPaymentHistory[]>({
    queryKey: ["admin", "subscriptions", subscriptionId, "payments"],
    queryFn: () =>
      apiClient.get<AdminPaymentHistory[]>(
        API_URLS.adminSubscriptionPaymentHistory(subscriptionId),
      ),
    enabled: subscriptionId > 0,
  });
}

export function useChangeHistory(subscriptionId: number) {
  return useQuery<AdminSubscriptionChange[]>({
    queryKey: ["admin", "subscriptions", subscriptionId, "changes"],
    queryFn: () =>
      apiClient.get<AdminSubscriptionChange[]>(
        API_URLS.adminSubscriptionChangeHistory(subscriptionId),
      ),
    enabled: subscriptionId > 0,
  });
}

export function useChangeTier() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      subscriptionId,
      new_tier,
      reason,
    }: {
      subscriptionId: number;
      new_tier: string;
      reason: string;
    }) =>
      apiClient.post<AdminSubscription>(
        API_URLS.adminSubscriptionChangeTier(subscriptionId),
        { new_tier, reason },
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "subscriptions"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "dashboard"] });
    },
  });
}

export function useChangeStatus() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      subscriptionId,
      new_status,
      reason,
    }: {
      subscriptionId: number;
      new_status: string;
      reason: string;
    }) =>
      apiClient.post<AdminSubscription>(
        API_URLS.adminSubscriptionChangeStatus(subscriptionId),
        { new_status, reason },
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "subscriptions"] });
      queryClient.invalidateQueries({ queryKey: ["admin", "dashboard"] });
    },
  });
}

export function useRecordPayment() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      subscriptionId,
      amount,
      description,
    }: {
      subscriptionId: number;
      amount: string;
      description: string;
    }) =>
      apiClient.post<AdminSubscription>(
        API_URLS.adminSubscriptionRecordPayment(subscriptionId),
        { amount, description },
      ),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ["admin", "subscriptions"] });
      queryClient.invalidateQueries({
        queryKey: [
          "admin",
          "subscriptions",
          variables.subscriptionId,
          "payments",
        ],
      });
      queryClient.invalidateQueries({ queryKey: ["admin", "dashboard"] });
    },
  });
}

export function useUpdateNotes() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      subscriptionId,
      admin_notes,
    }: {
      subscriptionId: number;
      admin_notes: string;
    }) =>
      apiClient.post<AdminSubscription>(
        API_URLS.adminSubscriptionUpdateNotes(subscriptionId),
        { admin_notes },
      ),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["admin", "subscriptions", variables.subscriptionId],
      });
    },
  });
}
