"use client";

import { useState, useRef, useCallback } from "react";
import { Send, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";

const MAX_LENGTH = 2000;
const WARNING_THRESHOLD = 0.9;

interface ChatInputProps {
  onSend: (content: string) => void;
  isSending: boolean;
  disabled?: boolean;
  placeholder?: string;
}

export function ChatInput({
  onSend,
  isSending,
  disabled = false,
  placeholder = "Type a message...",
}: ChatInputProps) {
  const [content, setContent] = useState("");
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const trimmedContent = content.trim();
  const canSend = trimmedContent.length > 0 && !isSending && !disabled;
  const charCount = content.length;
  const showCharCount = charCount >= MAX_LENGTH * WARNING_THRESHOLD;
  const isOverLimit = charCount > MAX_LENGTH;

  const handleSubmit = useCallback(() => {
    if (!canSend || isOverLimit) return;
    onSend(trimmedContent);
    setContent("");
    if (textareaRef.current) {
      textareaRef.current.style.height = "auto";
    }
  }, [canSend, isOverLimit, trimmedContent, onSend]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        handleSubmit();
      }
    },
    [handleSubmit],
  );

  const handleInput = useCallback(
    (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      setContent(e.target.value);
      // Auto-resize textarea
      const textarea = e.target;
      textarea.style.height = "auto";
      textarea.style.height = `${Math.min(textarea.scrollHeight, 120)}px`;
    },
    [],
  );

  return (
    <div className="border-t bg-background p-4">
      <div className="flex items-end gap-2">
        <div className="relative flex-1">
          <textarea
            ref={textareaRef}
            value={content}
            onChange={handleInput}
            onKeyDown={handleKeyDown}
            placeholder={placeholder}
            disabled={disabled || isSending}
            rows={1}
            className="w-full resize-none rounded-lg border bg-background px-3 py-2.5 text-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
            aria-label="Message input"
            maxLength={MAX_LENGTH}
          />
          {showCharCount && (
            <span
              className={`absolute bottom-1 right-2 text-[10px] ${
                isOverLimit ? "text-destructive" : "text-muted-foreground"
              }`}
              aria-live="polite"
            >
              {charCount}/{MAX_LENGTH}
            </span>
          )}
        </div>
        <Button
          size="icon"
          onClick={handleSubmit}
          disabled={!canSend || isOverLimit}
          aria-label="Send message"
        >
          {isSending ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <Send className="h-4 w-4" />
          )}
        </Button>
      </div>
    </div>
  );
}
