"use client";

import { useState, useRef, useCallback } from "react";
import { Send, Loader2, Paperclip, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";

const MAX_LENGTH = 2000;
const WARNING_THRESHOLD = 0.9;
const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
const ACCEPTED_IMAGE_TYPES = "image/jpeg,image/png,image/webp";

interface ChatInputProps {
  onSend: (content: string, image?: File) => void;
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
  const [selectedImage, setSelectedImage] = useState<File | null>(null);
  const [imagePreviewUrl, setImagePreviewUrl] = useState<string | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const { toast } = useToast();

  const trimmedContent = content.trim();
  const canSend =
    (trimmedContent.length > 0 || selectedImage !== null) &&
    !isSending &&
    !disabled;
  const charCount = content.length;
  const showCharCount = charCount >= MAX_LENGTH * WARNING_THRESHOLD;
  const isOverLimit = charCount > MAX_LENGTH;

  const handleImageSelect = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;

      // Reset file input for re-selection of same file
      e.target.value = "";

      if (!["image/jpeg", "image/png", "image/webp"].includes(file.type)) {
        toast({
          variant: "destructive",
          title: "Invalid file type",
          description: "Only JPEG, PNG, and WebP images are supported.",
        });
        return;
      }

      if (file.size > MAX_IMAGE_SIZE) {
        toast({
          variant: "destructive",
          title: "Image too large",
          description: "Image must be under 5MB.",
        });
        return;
      }

      setSelectedImage(file);
      setImagePreviewUrl(URL.createObjectURL(file));
    },
    [toast],
  );

  const removeImage = useCallback(() => {
    if (imagePreviewUrl) {
      URL.revokeObjectURL(imagePreviewUrl);
    }
    setSelectedImage(null);
    setImagePreviewUrl(null);
  }, [imagePreviewUrl]);

  const handleSubmit = useCallback(() => {
    if (!canSend || isOverLimit) return;
    onSend(trimmedContent, selectedImage ?? undefined);
    setContent("");
    removeImage();
    if (textareaRef.current) {
      textareaRef.current.style.height = "auto";
    }
  }, [canSend, isOverLimit, trimmedContent, selectedImage, onSend, removeImage]);

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
      {/* Image preview */}
      {imagePreviewUrl && (
        <div className="relative mb-3 inline-block">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={imagePreviewUrl}
            alt="Selected image preview"
            className="h-20 w-20 rounded-lg object-cover"
          />
          <button
            type="button"
            onClick={removeImage}
            className="absolute -right-1.5 -top-1.5 flex h-5 w-5 items-center justify-center rounded-full bg-destructive text-destructive-foreground shadow-sm"
            aria-label="Remove selected image"
          >
            <X className="h-3 w-3" />
          </button>
        </div>
      )}
      <div className="flex items-end gap-2">
        {/* Image picker button */}
        <Button
          type="button"
          variant="ghost"
          size="icon"
          className="shrink-0"
          onClick={() => fileInputRef.current?.click()}
          disabled={disabled || isSending}
          aria-label="Attach image"
        >
          <Paperclip className="h-4 w-4" />
        </Button>
        <input
          ref={fileInputRef}
          type="file"
          accept={ACCEPTED_IMAGE_TYPES}
          onChange={handleImageSelect}
          className="hidden"
          aria-hidden="true"
        />
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
