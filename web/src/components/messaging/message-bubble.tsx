"use client";

import { Check, CheckCheck } from "lucide-react";
import { cn } from "@/lib/utils";
import type { Message } from "@/types/messaging";

interface MessageBubbleProps {
  message: Message;
  isOwnMessage: boolean;
}

export function MessageBubble({ message, isOwnMessage }: MessageBubbleProps) {
  return (
    <div
      className={cn(
        "flex w-full",
        isOwnMessage ? "justify-end" : "justify-start",
      )}
    >
      <div
        className={cn(
          "max-w-[70%] rounded-2xl px-4 py-2.5",
          isOwnMessage
            ? "bg-primary text-primary-foreground rounded-br-sm"
            : "bg-muted text-foreground rounded-bl-sm",
        )}
      >
        <p className="whitespace-pre-wrap break-words text-sm">
          {message.content}
        </p>
        <div
          className={cn(
            "mt-1 flex items-center gap-1",
            isOwnMessage ? "justify-end" : "justify-start",
          )}
        >
          <span
            className={cn(
              "text-[10px]",
              isOwnMessage
                ? "text-primary-foreground/70"
                : "text-muted-foreground",
            )}
          >
            {formatMessageTime(message.created_at)}
          </span>
          {isOwnMessage && (
            message.is_read ? (
              <CheckCheck
                className="h-3 w-3 text-primary-foreground/70"
                aria-label="Read"
              />
            ) : (
              <Check
                className="h-3 w-3 text-primary-foreground/70"
                aria-label="Sent"
              />
            )
          )}
        </div>
      </div>
    </div>
  );
}

function formatMessageTime(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit",
  });
}
