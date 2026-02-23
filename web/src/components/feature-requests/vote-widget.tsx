"use client";

import { ChevronUp, ChevronDown } from "lucide-react";
import { toast } from "sonner";
import { cn } from "@/lib/utils";
import { useVoteFeatureRequest } from "@/hooks/use-feature-requests";
import { getErrorMessage } from "@/lib/error-utils";

interface VoteWidgetProps {
  featureId: number;
  voteScore: number;
  userVote: "up" | "down" | null;
  size?: "sm" | "md";
}

export function VoteWidget({
  featureId,
  voteScore,
  userVote,
  size = "sm",
}: VoteWidgetProps) {
  const voteMutation = useVoteFeatureRequest();

  function handleVote(direction: "up" | "down") {
    const voteType = userVote === direction ? "remove" : direction;
    voteMutation.mutate(
      { id: featureId, vote_type: voteType },
      { onError: (err) => toast.error(getErrorMessage(err)) },
    );
  }

  const iconSize = size === "md" ? "h-5 w-5" : "h-4 w-4";
  const containerPadding = size === "md" ? "px-3 py-1.5" : "px-2 py-1";

  return (
    <div
      className={cn(
        "flex flex-col items-center gap-0.5 rounded-md border text-sm",
        containerPadding,
      )}
    >
      <button
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          handleVote("up");
        }}
        disabled={voteMutation.isPending}
        className={cn(
          "rounded p-0.5 transition-colors hover:text-green-600 dark:hover:text-green-400",
          userVote === "up" && "text-green-600 dark:text-green-400",
        )}
        aria-label="Upvote"
      >
        <ChevronUp
          className={cn(iconSize, userVote === "up" && "fill-green-600 dark:fill-green-400")}
        />
      </button>
      <span
        className={cn(
          "font-semibold tabular-nums",
          size === "md" ? "text-base" : "text-sm",
          voteScore > 0 && "text-green-600 dark:text-green-400",
          voteScore < 0 && "text-red-600 dark:text-red-400",
        )}
      >
        {voteScore}
      </span>
      <button
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          handleVote("down");
        }}
        disabled={voteMutation.isPending}
        className={cn(
          "rounded p-0.5 transition-colors hover:text-red-600 dark:hover:text-red-400",
          userVote === "down" && "text-red-600 dark:text-red-400",
        )}
        aria-label="Downvote"
      >
        <ChevronDown
          className={cn(iconSize, userVote === "down" && "fill-red-600 dark:fill-red-400")}
        />
      </button>
    </div>
  );
}
