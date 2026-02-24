"use client";

import { useCallback, useEffect, useState } from "react";
import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { Announcement } from "@/types/announcement";

interface AnnouncementFormDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  announcement?: Announcement | null;
  onSubmit: (data: {
    title: string;
    body: string;
    content_format: "plain" | "markdown";
    is_pinned: boolean;
  }) => void;
  isPending: boolean;
}

export function AnnouncementFormDialog({
  open,
  onOpenChange,
  announcement,
  onSubmit,
  isPending,
}: AnnouncementFormDialogProps) {
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [isPinned, setIsPinned] = useState(false);
  const [contentFormat, setContentFormat] = useState<"plain" | "markdown">("plain");
  const [errors, setErrors] = useState<Record<string, string>>({});

  const isEdit = Boolean(announcement);

  useEffect(() => {
    if (open && announcement) {
      setTitle(announcement.title);
      setBody(announcement.body);
      setIsPinned(announcement.is_pinned);
      setContentFormat(announcement.content_format);
      setErrors({});
    } else if (open) {
      setTitle("");
      setBody("");
      setIsPinned(false);
      setContentFormat("plain");
      setErrors({});
    }
  }, [open, announcement]);

  const handleSubmit = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      const newErrors: Record<string, string> = {};

      if (!title.trim()) newErrors.title = "Title is required";
      if (!body.trim()) newErrors.body = "Body is required";

      if (Object.keys(newErrors).length > 0) {
        setErrors(newErrors);
        return;
      }

      onSubmit({
        title: title.trim(),
        body: body.trim(),
        content_format: contentFormat,
        is_pinned: isPinned,
      });
    },
    [title, body, contentFormat, isPinned, onSubmit],
  );

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>
            {isEdit ? "Edit Announcement" : "Create Announcement"}
          </DialogTitle>
          <DialogDescription>
            {isEdit
              ? "Update your announcement details."
              : "Create a new announcement to broadcast to all trainees."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label htmlFor="title">Title</Label>
              <span className="text-xs text-muted-foreground">
                {title.length}/200
              </span>
            </div>
            <Input
              id="title"
              value={title}
              onChange={(e) => {
                setTitle(e.target.value);
                setErrors((prev) => ({ ...prev, title: "" }));
              }}
              maxLength={200}
              placeholder="Announcement title"
              aria-invalid={Boolean(errors.title)}
            />
            {errors.title && (
              <p className="text-sm text-destructive">{errors.title}</p>
            )}
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label htmlFor="body">Body</Label>
              <span className="text-xs text-muted-foreground">
                {body.length}/2000
              </span>
            </div>
            <textarea
              id="body"
              value={body}
              onChange={(e) => {
                setBody(e.target.value);
                setErrors((prev) => ({ ...prev, body: "" }));
              }}
              maxLength={2000}
              rows={5}
              placeholder="Announcement body"
              className="w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-xs placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] disabled:opacity-50"
              aria-invalid={Boolean(errors.body)}
            />
            {errors.body && (
              <p className="text-sm text-destructive">{errors.body}</p>
            )}
          </div>

          <div className="flex items-center gap-4">
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={isPinned}
                onChange={(e) => setIsPinned(e.target.checked)}
                className="rounded border-input"
              />
              Pin announcement
            </label>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={contentFormat === "markdown"}
                onChange={(e) =>
                  setContentFormat(e.target.checked ? "markdown" : "plain")
                }
                className="rounded border-input"
              />
              Markdown
            </label>
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              type="button"
              onClick={() => onOpenChange(false)}
              disabled={isPending}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isPending}>
              {isPending && (
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
              )}
              {isEdit ? "Update" : "Create"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
