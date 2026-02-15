export const InvitationStatus = {
  PENDING: "PENDING",
  ACCEPTED: "ACCEPTED",
  EXPIRED: "EXPIRED",
  CANCELLED: "CANCELLED",
} as const;

export type InvitationStatus =
  (typeof InvitationStatus)[keyof typeof InvitationStatus];

export interface Invitation {
  id: number;
  email: string;
  invitation_code: string;
  status: InvitationStatus;
  trainer_email: string;
  program_template: number | null;
  program_template_name: string | null;
  message: string;
  expires_at: string;
  accepted_at: string | null;
  created_at: string;
  is_expired: boolean;
}

export interface CreateInvitationPayload {
  email: string;
  message?: string;
  program_template?: number | null;
  expires_in_days?: number;
}
