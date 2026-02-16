import { ApiError } from "./api-client";

/** Keys that should never be shown to the user in error messages */
const SENSITIVE_KEYS = new Set(["detail", "non_field_errors"]);

function formatFieldError(key: string, value: unknown): string {
  const label = SENSITIVE_KEYS.has(key) ? "" : `${key}: `;
  if (Array.isArray(value)) return `${label}${value.join(", ")}`.trim();
  if (typeof value === "string") return `${label}${value}`.trim();
  return `${label}${String(value)}`.trim();
}

export function getErrorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    if (typeof error.body === "object" && error.body !== null) {
      const entries = Object.entries(error.body as Record<string, unknown>);
      const messages = entries
        .map(([key, value]) => formatFieldError(key, value))
        .filter(Boolean)
        .join("; ");
      if (messages) return messages;
    }
    if (typeof error.body === "string" && error.body.length > 0) {
      return error.body;
    }
    return error.statusText || "Request failed";
  }
  if (error instanceof Error) {
    return error.message || "An unexpected error occurred";
  }
  return "An unexpected error occurred";
}
