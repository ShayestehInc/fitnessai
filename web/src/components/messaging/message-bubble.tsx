"use client";

import { useState, useRef, useEffect, useCallback } from "react";
import { Check, CheckCheck, Pencil, Trash2, X } from "lucide-react";
import { cn } from "@/lib/utils";
import type { Message } from "@/types/messaging";
import { ImageModal } from "./image-modal";
import { Button } from "@/components/ui/button";

interface MessageBubbleProps {
  message: Message;
  isOwnMessage: boolean;
  onEdit?: (content: string) => void;
  onDelete?: () => void;
}

const EDIT_WINDOW_MS = 15 * 60 * 1000; // 15 minutes

export function MessageBubble({
  message,
  isOwnMessage,
  onEdit,
  onDelete,
}: MessageBubbleProps) {
  const [imageModalOpen, setImageModalOpen] = useState(false);
  const [imageError, setImageError] = useState(false);
  const [isHovered, setIsHovered] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [editContent, setEditContent] = useState(message.content);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const editRef = useRef<HTMLTextAreaElement>(null);

  const hasImage = !!message.image;
  const hasContent = !!message.content;
  const isDeleted = message.is_deleted;
  const isEdited = !!message.edited_at;
  const canEdit =
    isOwnMessage &&
    !isDeleted &&
    Date.now() - new Date(message.created_at).getTime() < EDIT_WINDOW_MS;
  const canDelete = isOwnMessage && !isDeleted;

  // Focus textarea when entering edit mode
  useEffect(() => {
    if (isEditing && editRef.current) {
      editRef.current.focus();
      editRef.current.setSelectionRange(
        editRef.current.value.length,
        editRef.current.value.length,
      );
    }
  }, [isEditing]);

  // Dismiss delete confirmation on Escape key
  useEffect(() => {
    if (!showDeleteConfirm) return;
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setShowDeleteConfirm(false);
      }
    };
    document.addEventListener("keydown", handleEscape);
    return () => document.removeEventListener("keydown", handleEscape);
  }, [showDeleteConfirm]);

  const handleSaveEdit = useCallback(() => {
    const trimmed = editContent.trim();
    // Allow empty content for image messages (image-only); require content for text-only
    const canSave = (trimmed || hasImage) && trimmed !== message.content;
    if (canSave) {
      onEdit?.(trimmed);
    }
    setIsEditing(false);
  }, [editContent, message.content, hasImage, onEdit]);

  const handleCancelEdit = useCallback(() => {
    setEditContent(message.content);
    setIsEditing(false);
  }, [message.content]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === "Escape") {
        handleCancelEdit();
      }
      if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
        handleSaveEdit();
      }
    },
    [handleCancelEdit, handleSaveEdit],
  );

  // Deleted message placeholder
  if (isDeleted) {
    return (
      <div
        className={cn(
          "flex w-full",
          isOwnMessage ? "justify-end" : "justify-start",
        )}
        aria-label={`${isOwnMessage ? "You" : "Other participant"}: This message was deleted, ${formatMessageTime(message.created_at)}`}
      >
        <div
          className={cn(
            "max-w-[70%] overflow-hidden rounded-2xl px-4 py-2.5",
            isOwnMessage
              ? "bg-muted/50 rounded-br-sm"
              : "bg-muted/50 rounded-bl-sm",
          )}
        >
          <p className="text-sm italic text-muted-foreground">
            [This message was deleted]
          </p>
          <div className="flex items-center gap-1 pt-1">
            <span className="text-[10px] text-muted-foreground">
              {formatMessageTime(message.created_at)}
            </span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <>
      <div
        className={cn(
          "group relative flex w-full",
          isOwnMessage ? "justify-end" : "justify-start",
        )}
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => {
          setIsHovered(false);
          // Don't dismiss delete confirmation on mouse leave — user needs time to click
        }}
      >
        {/* Action icons on hover (own messages only) */}
        {isOwnMessage && isHovered && !isEditing && (canEdit || canDelete) && (
          <div className="mr-2 flex items-start gap-1 pt-1">
            {canEdit && (
              <button
                type="button"
                onClick={() => {
                  setEditContent(message.content);
                  setIsEditing(true);
                }}
                className="rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground"
                aria-label="Edit message"
              >
                <Pencil className="h-3.5 w-3.5" />
              </button>
            )}
            {canDelete && (
              <button
                type="button"
                onClick={() => setShowDeleteConfirm(true)}
                className="rounded-md p-1 text-muted-foreground hover:bg-destructive/10 hover:text-destructive"
                aria-label="Delete message"
              >
                <Trash2 className="h-3.5 w-3.5" />
              </button>
            )}
          </div>
        )}

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

          {/* Text content or inline edit */}
          {isEditing ? (
            <div className="px-3 py-2">
              <textarea
                ref={editRef}
                value={editContent}
                onChange={(e) => setEditContent(e.target.value)}
                onKeyDown={handleKeyDown}
                maxLength={2000}
                rows={2}
                className="w-full resize-none rounded-md border bg-background px-2 py-1.5 text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-ring"
              />
              <div className="mt-1 flex items-center justify-between">
                <span className="text-[10px] text-muted-foreground">
                  Esc to cancel,{" "}
                  {typeof navigator !== "undefined" &&
                  /Mac|iPhone|iPad/.test(navigator.userAgent)
                    ? "\u2318"
                    : "Ctrl"}
                  +Enter to save
                </span>
                <div className="flex gap-1">
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={handleCancelEdit}
                    className="h-6 px-2 text-xs"
                  >
                    Cancel
                  </Button>
                  <Button
                    size="sm"
                    onClick={handleSaveEdit}
                    disabled={
                      (!editContent.trim() && !hasImage) ||
                      editContent.trim() === message.content
                    }
                    className="h-6 px-2 text-xs"
                  >
                    Save
                  </Button>
                </div>
              </div>
            </div>
          ) : hasContent ? (
            <p
              className={cn(
                "whitespace-pre-wrap break-words text-sm",
                hasImage ? "px-4 pb-2.5 pt-1.5" : "px-4 py-2.5",
              )}
            >
              {message.content}
            </p>
          ) : null}

          {/* Image-only spacer */}
          {!hasContent && !isEditing && hasImage && <div className="h-1" />}

          {/* Timestamp + edited indicator + read receipts */}
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
            {isEdited && (
              <span
                className={cn(
                  "text-[10px] italic",
                  isOwnMessage
                    ? "text-primary-foreground/50"
                    : "text-muted-foreground/70",
                )}
              >
                (edited)
              </span>
            )}
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

      {/* Delete confirmation dialog */}
      {showDeleteConfirm && (
        <div
          className={cn(
            "flex w-full",
            isOwnMessage ? "justify-end" : "justify-start",
          )}
        >
          <div
            role="alertdialog"
            aria-label="Confirm message deletion"
            className="flex items-center gap-2 rounded-lg border bg-background px-3 py-2 shadow-sm"
          >
            <span className="text-xs text-muted-foreground">
              Delete this message? This can&apos;t be undone.
            </span>
            <Button
              size="sm"
              variant="destructive"
              onClick={() => {
                onDelete?.();
                setShowDeleteConfirm(false);
              }}
              className="h-6 px-2 text-xs"
            >
              Delete
            </Button>
            <Button
              size="sm"
              variant="ghost"
              onClick={() => setShowDeleteConfirm(false)}
              className="h-6 px-2 text-xs"
            >
              <X className="h-3 w-3" />
            </Button>
          </div>
        </div>
      )}

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
