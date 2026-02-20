"use client";

import { useState } from "react";
import { Check, CheckCheck } from "lucide-react";
import { cn } from "@/lib/utils";
import type { Message } from "@/types/messaging";
import { ImageModal } from "./image-modal";

interface MessageBubbleProps {
  message: Message;
  isOwnMessage: boolean;
}

export function MessageBubble({ message, isOwnMessage }: MessageBubbleProps) {
  const [imageModalOpen, setImageModalOpen] = useState(false);
  const [imageError, setImageError] = useState(false);
  const hasImage = !!message.image;
  const hasContent = !!message.content;

  return (
    <>
      <div
        className={cn(
          "flex w-full",
          isOwnMessage ? "justify-end" : "justify-start",
        )}
      >
        <div
          className={cn(
            "max-w-[70%] overflow-hidden rounded-2xl",
            isOwnMessage
              ? "bg-primary text-primary-foreground rounded-br-sm"
              : "bg-muted text-foreground rounded-bl-sm",
          )}
        >
          {/* Image attachment */}
          {hasImage && !imageError && (
            <button
              type="button"
              onClick={() => setImageModalOpen(true)}
              className="block w-full cursor-pointer"
              aria-label="View full image"
            >
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={message.image!}
                alt="Message attachment"
                className="max-h-[300px] w-full object-cover"
                loading="lazy"
                onError={() => setImageError(true)}
              />
            </button>
          )}

          {/* Image error state */}
          {hasImage && imageError && (
            <div className="flex h-[120px] w-full items-center justify-center bg-muted">
              <span className="text-xs text-muted-foreground">
                Failed to load image
              </span>
            </div>
          )}

          {/* Text content */}
          {hasContent && (
            <p
              className={cn(
                "whitespace-pre-wrap break-words text-sm",
                hasImage ? "px-4 pb-2.5 pt-1.5" : "px-4 py-2.5",
              )}
            >
              {message.content}
            </p>
          )}

          {/* Image-only spacer */}
          {!hasContent && hasImage && <div className="h-1" />}

          {/* Timestamp + read receipts */}
          <div
            className={cn(
              "flex items-center gap-1 px-4 pb-2",
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
            {isOwnMessage &&
              (message.is_read ? (
                <CheckCheck
                  className="h-3 w-3 text-primary-foreground/70"
                  aria-label="Read"
                />
              ) : (
                <Check
                  className="h-3 w-3 text-primary-foreground/70"
                  aria-label="Sent"
                />
              ))}
          </div>
        </div>
      </div>

      {/* Full-screen image modal */}
      {hasImage && message.image && (
        <ImageModal
          imageUrl={message.image}
          open={imageModalOpen}
          onClose={() => setImageModalOpen(false)}
        />
      )}
    </>
  );
}

function formatMessageTime(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit",
  });
}
