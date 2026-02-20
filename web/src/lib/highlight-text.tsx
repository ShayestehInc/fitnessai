import type { ReactNode } from "react";

/**
 * Highlights matching portions of text by wrapping them in <mark> tags.
 * Case-insensitive matching. Returns ReactNode array.
 */
export function highlightText(text: string, query: string): ReactNode {
  if (!query || query.length < 2) return text;

  // Escape regex special characters in the query
  const escaped = query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  // Use 'i' flag only for split (capture group preserves matched casing).
  // Do NOT use 'g' flag — it causes stateful lastIndex issues with test().
  const regex = new RegExp(`(${escaped})`, "i");
  const parts = text.split(regex);

  if (parts.length === 1) return text;

  const lowerQuery = query.toLowerCase();

  return parts.map((part, index) =>
    part.toLowerCase() === lowerQuery ? (
      <mark key={index} className="rounded-sm bg-primary/20 px-0.5">
        {part}
      </mark>
    ) : (
      part
    ),
  );
}

/**
 * Truncates text around the first match of the query string.
 * Returns ~150 chars around the match with "..." on either side if truncated.
 */
export function truncateAroundMatch(
  text: string,
  query: string,
  maxLength: number = 150,
): string {
  if (text.length <= maxLength) return text;

  const lowerText = text.toLowerCase();
  const lowerQuery = query.toLowerCase();
  const matchIndex = lowerText.indexOf(lowerQuery);

  if (matchIndex === -1) {
    // No match found, truncate from start
    return text.slice(0, maxLength) + "...";
  }

  // Center the window around the match
  const padding = Math.floor((maxLength - query.length) / 2);
  let start = Math.max(0, matchIndex - padding);
  let end = Math.min(text.length, start + maxLength);

  // Adjust start if end was clamped
  if (end === text.length) {
    start = Math.max(0, end - maxLength);
  }

  let result = text.slice(start, end);
  if (start > 0) result = "..." + result;
  if (end < text.length) result = result + "...";

  return result;
}
