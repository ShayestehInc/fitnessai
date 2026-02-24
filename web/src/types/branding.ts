export interface TrainerBranding {
  app_name: string;
  primary_color: string;
  secondary_color: string;
  logo: string | null;
}

/**
 * Trainee-facing branding — returned by GET /api/users/my-branding/.
 * Note: uses `logo_url` (absolute URL) whereas TrainerBranding uses `logo`
 * (relative path for CRUD operations). Both shapes are correct for their
 * respective API contracts.
 */
export interface TraineeBranding {
  app_name: string;
  primary_color: string;
  secondary_color: string;
  logo_url: string | null;
}

export interface UpdateBrandingPayload {
  app_name?: string;
  primary_color?: string;
  secondary_color?: string;
}
