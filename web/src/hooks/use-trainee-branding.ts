"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";

interface TraineeBranding {
  app_name: string;
  primary_color: string;
  secondary_color: string;
  logo_url: string | null;
}

const DEFAULT_BRANDING: TraineeBranding = {
  app_name: "",
  primary_color: "#6366F1",
  secondary_color: "#818CF8",
  logo_url: null,
};

export function useTraineeBranding(): {
  branding: TraineeBranding;
  isLoading: boolean;
} {
  const { data, isLoading } = useQuery<TraineeBranding>({
    queryKey: ["trainee-branding"],
    queryFn: () =>
      apiClient.get<TraineeBranding>(API_URLS.TRAINEE_BRANDING),
    staleTime: 5 * 60 * 1000,
    retry: 1,
  });

  return {
    branding: data ?? DEFAULT_BRANDING,
    isLoading,
  };
}

export function getBrandingDisplayName(branding: TraineeBranding): string {
  return branding.app_name.trim() || "FitnessAI";
}
