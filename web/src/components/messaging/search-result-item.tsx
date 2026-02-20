"use client";

import { User } from "lucide-react";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { getInitials } from "@/lib/format-utils";
import { highlightText, truncateAroundMatch } from "@/lib/highlight-text";
import type { SearchMessageResult } from "@/types/messaging";

interface SearchResultItemProps {
  result: SearchMessageResult;
  query: string;
  onClick: (result: SearchMessageResult) => void;
}

export function SearchResultItem({
  result,
  query,
  onClick,
}: SearchResultItemProps) {
  const senderName =
    `${result.sender_first_name} ${result.sender_last_name}`.trim();
  const otherPartyName =
    `${result.other_participant_first_name} ${result.other_participant_last_name}`.trim();
  const initials = getInitials(
    result.other_participant_first_name,
    result.other_participant_last_name,
  );

  const snippet = truncateAroundMatch(result.content, query);

  const timeLabel = formatSearchTime(result.created_at);

  return (
    <div role="listitem">
      <button
        type="button"
        onClick={() => onClick(result)}
        className="flex w-full items-start gap-3 border-b px-4 py-3 text-left transition-colors hover:bg-accent/50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-inset"
        aria-label={`Message from ${senderName} in conversation with ${otherPartyName}, ${timeLabel}`}
      >
        <Avatar size="default" className="mt-0.5 shrink-0">
          <AvatarFallback>
            {initials || <User className="h-4 w-4" aria-hidden="true" />}
          </AvatarFallback>
        </Avatar>

        <div className="min-w-0 flex-1">
          <div className="flex items-center justify-between gap-2">
            <span className="truncate text-sm font-medium">
              {otherPartyName || "Unknown"}
            </span>
            <time className="shrink-0 text-xs text-muted-foreground" dateTime={result.created_at}>
              {timeLabel}
            </time>
          </div>
          <p className="mt-0.5 text-xs text-muted-foreground">
            {senderName}:
          </p>
          <p className="mt-0.5 line-clamp-2 text-sm" aria-label={`Message: ${snippet}`}>
            {highlightText(snippet, query)}
          </p>
        </div>
      </button>
    </div>
  );
}

function formatSearchTime(dateString: string): string {
  const date = new Date(dateString);
  if (isNaN(date.getTime())) return "";

  const now = new Date();
  const diffMs = now.getTime() - date.getTime();

  // Future or negative diff: show absolute date (clock skew / timezone edge case)
  if (diffMs < 0) {
    return date.toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
    });
  }

  const diffDays = Math.floor(diffMs / 86_400_000);

  if (diffDays === 0) {
    return date.toLocaleTimeString(undefined, {
      hour: "numeric",
      minute: "2-digit",
    });
  }
  if (diffDays === 1) return "Yesterday";
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: diffDays > 365 ? "numeric" : undefined,
  });
}
