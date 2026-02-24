"use client";

import { useState, useCallback } from "react";
import {
  Plus,
  MessageSquare,
  MoreHorizontal,
  Pencil,
  Trash2,
  Loader2,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { cn } from "@/lib/utils";
import type { AiChatThread } from "@/types/ai-chat";

interface AiThreadSidebarProps {
  threads: AiChatThread[];
  selectedId: number | null;
  isLoading: boolean;
  onSelect: (thread: AiChatThread) => void;
  onNewThread: () => void;
  onRename: (threadId: number, title: string) => void;
  onDelete: (threadId: number) => void;
  isCreating: boolean;
}

export function AiThreadSidebar({
  threads,
  selectedId,
  isLoading,
  onSelect,
  onNewThread,
  onRename,
  onDelete,
  isCreating,
}: AiThreadSidebarProps) {
  const [renameDialogOpen, setRenameDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [targetThread, setTargetThread] = useState<AiChatThread | null>(null);
  const [renameValue, setRenameValue] = useState("");

  const handleRenameOpen = useCallback((thread: AiChatThread) => {
    setTargetThread(thread);
    setRenameValue(thread.title);
    setRenameDialogOpen(true);
  }, []);

  const handleDeleteOpen = useCallback((thread: AiChatThread) => {
    setTargetThread(thread);
    setDeleteDialogOpen(true);
  }, []);

  const handleRenameConfirm = useCallback(() => {
    if (targetThread && renameValue.trim()) {
      onRename(targetThread.id, renameValue.trim());
    }
    setRenameDialogOpen(false);
    setTargetThread(null);
  }, [targetThread, renameValue, onRename]);

  const handleDeleteConfirm = useCallback(() => {
    if (targetThread) {
      onDelete(targetThread.id);
    }
    setDeleteDialogOpen(false);
    setTargetThread(null);
  }, [targetThread, onDelete]);

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return "";
    const date = new Date(dateStr);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days === 0) {
      return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    }
    if (days === 1) return "Yesterday";
    if (days < 7) return `${days}d ago`;
    return date.toLocaleDateString([], { month: "short", day: "numeric" });
  };

  return (
    <div className="flex h-full flex-col">
      {/* Header with New Thread button */}
      <div className="border-b p-3">
        <Button
          onClick={onNewThread}
          disabled={isCreating}
          className="w-full"
          size="sm"
        >
          {isCreating ? (
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
          ) : (
            <Plus className="mr-2 h-4 w-4" />
          )}
          New thread
        </Button>
      </div>

      {/* Thread list */}
      <div className="flex-1 overflow-y-auto">
        {isLoading ? (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
          </div>
        ) : threads.length === 0 ? (
          <div className="flex flex-col items-center justify-center gap-2 px-4 py-8 text-center">
            <MessageSquare className="h-8 w-8 text-muted-foreground" />
            <p className="text-sm text-muted-foreground">No threads yet</p>
            <p className="text-xs text-muted-foreground">
              Start a new thread to chat with AI
            </p>
          </div>
        ) : (
          threads.map((thread) => (
            <div
              key={thread.id}
              className={cn(
                "group flex cursor-pointer items-start gap-2 border-b px-3 py-3 transition-colors hover:bg-accent",
                selectedId === thread.id && "bg-accent",
              )}
              onClick={() => onSelect(thread)}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  onSelect(thread);
                }
              }}
            >
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium">{thread.title}</p>
                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                  {thread.trainee_context_name && (
                    <span className="truncate">
                      {thread.trainee_context_name}
                    </span>
                  )}
                  <span>{formatDate(thread.last_message_at || thread.created_at)}</span>
                </div>
              </div>

              {/* Actions menu */}
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button
                    variant="ghost"
                    size="icon-xs"
                    className="shrink-0 opacity-0 group-hover:opacity-100"
                    onClick={(e) => e.stopPropagation()}
                    aria-label="Thread actions"
                  >
                    <MoreHorizontal className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem
                    onClick={(e) => {
                      e.stopPropagation();
                      handleRenameOpen(thread);
                    }}
                  >
                    <Pencil className="mr-2 h-4 w-4" />
                    Rename
                  </DropdownMenuItem>
                  <DropdownMenuItem
                    onClick={(e) => {
                      e.stopPropagation();
                      handleDeleteOpen(thread);
                    }}
                    className="text-destructive focus:text-destructive"
                  >
                    <Trash2 className="mr-2 h-4 w-4" />
                    Delete
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          ))
        )}
      </div>

      {/* Rename dialog */}
      <Dialog open={renameDialogOpen} onOpenChange={setRenameDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Rename thread</DialogTitle>
            <DialogDescription>
              Enter a new title for this thread.
            </DialogDescription>
          </DialogHeader>
          <Input
            value={renameValue}
            onChange={(e) => setRenameValue(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") handleRenameConfirm();
            }}
            placeholder="Thread title"
            maxLength={200}
            autoFocus
          />
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setRenameDialogOpen(false)}
            >
              Cancel
            </Button>
            <Button
              onClick={handleRenameConfirm}
              disabled={!renameValue.trim()}
            >
              Rename
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete confirmation dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete thread</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete &quot;{targetThread?.title}&quot;?
              This cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setDeleteDialogOpen(false)}
            >
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDeleteConfirm}>
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
