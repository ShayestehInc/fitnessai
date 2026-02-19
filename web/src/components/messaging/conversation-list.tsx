"use client";

import { User, MessageSquare } from "lucide-react";
import { cn } from "@/lib/utils";
import { getInitials } from "@/lib/format-utils";
import { useAuth } from "@/hooks/use-auth";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import type { Conversation } from "@/types/messaging";

interface ConversationListProps {
  conversations: Conversation[];
  selectedId: number | null;
  onSelect: (conversation: Conversation) => void;
}

export function ConversationList({
  conversations,
  selectedId,
  onSelect,
}: ConversationListProps) {
  const { user } = useAuth();
  if (conversations.length === 0) {
    return (
      <div
        className="flex flex-col items-center justify-center py-12 text-center"
        role="status"
      >
        <div className="mb-4 rounded-full bg-muted p-4">
          <MessageSquare
            className="h-8 w-8 text-muted-foreground"
            aria-hidden="true"
          />
        </div>
        <h3 className="mb-1 text-lg font-semibold">No conversations yet</h3>
        <p className="max-w-sm text-sm text-muted-foreground">
          Start a conversation with a trainee from their profile page.
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col" role="listbox" aria-label="Conversations">
      {conversations.map((conversation) => {
        // Show the other party: trainer sees trainee info, trainee sees trainer info
        const otherParty =
          user?.id === conversation.trainer.id
            ? conversation.trainee
            : conversation.trainer;
        const displayName =
          `${otherParty.first_name} ${otherParty.last_name}`.trim() ||
          otherParty.email;
        const initials = getInitials(otherParty.first_name, otherParty.last_name);
        const isSelected = selectedId === conversation.id;
        const hasUnread = conversation.unread_count > 0;

        return (
          <button
            key={conversation.id}
            type="button"
            role="option"
            aria-selected={isSelected}
            onClick={() => onSelect(conversation)}
            className={cn(
              "flex items-center gap-3 border-b px-4 py-3 text-left transition-colors hover:bg-accent/50",
              isSelected && "bg-accent",
              hasUnread && "font-medium",
            )}
          >
            <Avatar size="default">
              {otherParty.profile_image ? (
                <AvatarImage src={otherParty.profile_image} alt={displayName} />
              ) : null}
              <AvatarFallback>
                {initials || (
                  <User className="h-4 w-4" aria-hidden="true" />
                )}
              </AvatarFallback>
            </Avatar>

            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between gap-2">
                <span
                  className={cn(
                    "truncate text-sm",
                    hasUnread ? "font-semibold" : "font-medium",
                  )}
                >
                  {displayName}
                </span>
                {conversation.last_message_at && (
                  <span className="shrink-0 text-xs text-muted-foreground">
                    {formatRelativeTime(conversation.last_message_at)}
                  </span>
                )}
              </div>
              <div className="flex items-center justify-between gap-2">
                <span
                  className={cn(
                    "truncate text-xs",
                    hasUnread
                      ? "text-foreground"
                      : "text-muted-foreground",
                  )}
                >
                  {conversation.last_message_preview ?? "No messages yet"}
                </span>
                {hasUnread && (
                  <Badge
                    variant="default"
                    className="shrink-0 h-5 min-w-[20px] px-1.5 text-[10px]"
                  >
                    {conversation.unread_count > 99
                      ? "99+"
                      : conversation.unread_count}
                  </Badge>
                )}
              </div>
            </div>
          </button>
        );
      })}
    </div>
  );
}

function formatRelativeTime(dateString: string): string {
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60_000);
  const diffHours = Math.floor(diffMs / 3_600_000);
  const diffDays = Math.floor(diffMs / 86_400_000);

  if (diffMins < 1) return "now";
  if (diffMins < 60) return `${diffMins}m`;
  if (diffHours < 24) return `${diffHours}h`;
  if (diffDays < 7) return `${diffDays}d`;

  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
  });
}
