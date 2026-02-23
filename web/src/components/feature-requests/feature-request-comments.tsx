"use client";

import { useState } from "react";
import { format } from "date-fns";
import { Loader2, MessageSquare } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { EmptyState } from "@/components/shared/empty-state";
import {
  useFeatureComments,
  useCreateFeatureComment,
} from "@/hooks/use-feature-requests";
import { getErrorMessage } from "@/lib/error-utils";
import type { FeatureComment } from "@/types/feature-request";

interface FeatureRequestCommentsProps {
  featureId: number;
}

const MAX_COMMENT_LENGTH = 2000;

export function FeatureRequestComments({
  featureId,
}: FeatureRequestCommentsProps) {
  const [content, setContent] = useState("");
  const { data, isLoading, isError } = useFeatureComments(featureId);
  const createComment = useCreateFeatureComment(featureId);

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const trimmed = content.trim();
    if (!trimmed) return;

    createComment.mutate(trimmed, {
      onSuccess: () => {
        setContent("");
        toast.success("Comment posted");
      },
      onError: (err) => toast.error(getErrorMessage(err)),
    });
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-8">
        <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (isError) {
    return (
      <p className="py-4 text-sm text-destructive">
        Failed to load comments.
      </p>
    );
  }

  const comments: FeatureComment[] = data?.results ?? [];

  return (
    <div className="space-y-4">
      <h3 className="text-sm font-semibold">
        Comments ({comments.length})
      </h3>

      {comments.length === 0 ? (
        <EmptyState
          icon={MessageSquare}
          title="No comments yet"
          description="Be the first to share your thoughts."
        />
      ) : (
        <div className="space-y-3">
          {comments.map((comment) => (
            <div
              key={comment.id}
              className={cn(
                "rounded-lg border p-3",
                comment.is_admin_response &&
                  "border-primary/30 bg-primary/5",
              )}
            >
              <div className="flex items-center gap-2">
                <span className="text-sm font-medium">
                  {comment.user_name || "Anonymous"}
                </span>
                {comment.is_admin_response && (
                  <Badge variant="secondary" className="text-xs">
                    Team
                  </Badge>
                )}
                <span className="text-xs text-muted-foreground">
                  {format(new Date(comment.created_at), "MMM d, yyyy 'at' h:mm a")}
                </span>
              </div>
              <p className="mt-1 whitespace-pre-wrap text-sm text-muted-foreground">
                {comment.content}
              </p>
            </div>
          ))}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-2">
        <div className="flex justify-between">
          <label htmlFor="comment-input" className="text-sm font-medium">
            Add a comment
          </label>
          <span className="text-xs text-muted-foreground">
            {content.length}/{MAX_COMMENT_LENGTH}
          </span>
        </div>
        <textarea
          id="comment-input"
          value={content}
          onChange={(e) => setContent(e.target.value)}
          maxLength={MAX_COMMENT_LENGTH}
          rows={3}
          placeholder="Share your thoughts..."
          className="w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
        />
        <div className="flex justify-end">
          <Button
            type="submit"
            size="sm"
            disabled={!content.trim() || createComment.isPending}
          >
            {createComment.isPending && (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            )}
            Post Comment
          </Button>
        </div>
      </form>
    </div>
  );
}
