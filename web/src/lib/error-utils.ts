import { ApiError } from "./api-client";

export function getErrorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    if (typeof error.body === "object" && error.body !== null) {
      const messages = Object.entries(error.body as Record<string, unknown>)
        .map(([key, value]) => {
          if (Array.isArray(value)) return `${key}: ${value.join(", ")}`;
          return `${key}: ${value}`;
        })
        .join("; ");
      if (messages) return messages;
    }
    return error.statusText;
  }
  return "An unexpected error occurred";
}
