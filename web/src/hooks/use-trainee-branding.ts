"use client";

import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import type { TraineeBranding } from "@/types/branding";

export type { TraineeBranding } from "@/types/branding";

const HEX_COLOR_PATTERN = /^#[0-9a-fA-F]{6}$/;

const DEFAULT_BRANDING: TraineeBranding = {
  app_name: "",
  primary_color: "#6366F1",
  secondary_color: "#818CF8",
  logo_url: null,
};

/**
 * Sanitize branding data from the API, falling back to defaults for
 * any malformed color values to prevent broken inline styles.
 */
function sanitizeBranding(raw: TraineeBranding): TraineeBranding {
  return {
    app_name: raw.app_name,
    primary_color: HEX_COLOR_PATTERN.test(raw.primary_color)
      ? raw.primary_color
      : DEFAULT_BRANDING.primary_color,
    secondary_color: HEX_COLOR_PATTERN.test(raw.secondary_color)
      ? raw.secondary_color
      : DEFAULT_BRANDING.secondary_color,
    logo_url: raw.logo_url,
  };
}

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
    branding: data ? sanitizeBranding(data) : DEFAULT_BRANDING,
    isLoading,
  };
}

export function getBrandingDisplayName(branding: TraineeBranding): string {
  return branding.app_name.trim() || "FitnessAI";
}

export function hasCustomPrimaryColor(branding: TraineeBranding): boolean {
  return branding.primary_color.toLowerCase() !== DEFAULT_BRANDING.primary_color.toLowerCase();
}
