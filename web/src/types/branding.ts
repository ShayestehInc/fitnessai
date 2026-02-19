export interface TrainerBranding {
  app_name: string;
  primary_color: string;
  secondary_color: string;
  logo: string | null;
}

export interface UpdateBrandingPayload {
  app_name?: string;
  primary_color?: string;
  secondary_color?: string;
}
