"use client";

import { useState } from "react";
import { format } from "date-fns";
import { ChevronUp, MessageSquare, Lightbulb, Plus } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { EmptyState } from "@/components/shared/empty-state";
import { useVoteFeatureRequest } from "@/hooks/use-feature-requests";
import { CreateFeatureRequestDialog } from "./create-feature-request-dialog";
import { getErrorMessage } from "@/lib/error-utils";
import type { FeatureRequest, FeatureRequestStatus } from "@/types/feature-request";

const STATUS_FILTERS: { value: FeatureRequestStatus | ""; label: string }[] = [
  { value: "", label: "All" },
  { value: "open", label: "Open" },
  { value: "planned", label: "Planned" },
  { value: "in_progress", label: "In Progress" },
  { value: "done", label: "Done" },
];

const STATUS_COLORS: Record<string, string> = {
  open: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-200",
  planned: "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-200",
  in_progress: "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-200",
  done: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-200",
  closed: "bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-200",
};

interface FeatureRequestListProps {
  requests: FeatureRequest[];
  statusFilter: FeatureRequestStatus | "";
  onStatusFilterChange: (status: FeatureRequestStatus | "") => void;
}

export function FeatureRequestList({
  requests,
  statusFilter,
  onStatusFilterChange,
}: FeatureRequestListProps) {
  const [createOpen, setCreateOpen] = useState(false);
  const voteMutation = useVoteFeatureRequest();

  function handleVote(id: number, hasVoted: boolean) {
    voteMutation.mutate(
      { id, vote_type: hasVoted ? "remove" : "up" },
      { onError: (err) => toast.error(getErrorMessage(err)) },
    );
  }

  return (
    <>
      <div className="space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex flex-wrap gap-2">
            {STATUS_FILTERS.map(({ value, label }) => (
              <button
                key={value}
                onClick={() => onStatusFilterChange(value)}
                className={cn(
                  "rounded-full border px-3 py-1 text-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
                  statusFilter === value
                    ? "border-primary bg-primary text-primary-foreground"
                    : "hover:bg-accent",
                )}
              >
                {label}
              </button>
            ))}
          </div>
          <Button onClick={() => setCreateOpen(true)}>
            <Plus className="mr-2 h-4 w-4" />
            Submit Request
          </Button>
        </div>

        {requests.length === 0 ? (
          <EmptyState
            icon={Lightbulb}
            title={statusFilter ? `No ${statusFilter.replace("_", " ")} requests` : "No feature requests yet"}
            description={statusFilter ? "Try a different filter." : "Be the first to submit a feature request!"}
            action={
              !statusFilter ? (
                <Button onClick={() => setCreateOpen(true)}>
                  <Plus className="mr-2 h-4 w-4" />
                  Submit a Request
                </Button>
              ) : undefined
            }
          />
        ) : (
          <div className="space-y-3">
            {requests.map((req) => (
              <div
                key={req.id}
                className="flex items-start gap-4 rounded-lg border p-4 transition-all hover:shadow-sm"
              >
                <button
                  onClick={() => handleVote(req.id, req.has_voted)}
                  className={cn(
                    "flex flex-col items-center gap-0.5 rounded-md border px-2 py-1 text-sm transition-colors",
                    req.has_voted
                      ? "border-primary bg-primary/10 text-primary"
                      : "hover:border-primary/50 hover:text-primary",
                  )}
                  aria-label={`Vote for ${req.title}`}
                >
                  <ChevronUp className={cn("h-4 w-4", req.has_voted && "fill-primary")} />
                  <span className="font-medium">{req.vote_count}</span>
                </button>
                <div className="flex-1 min-w-0">
                  <h3 className="font-medium">{req.title}</h3>
                  <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">
                    {req.description}
                  </p>
                  <div className="mt-2 flex flex-wrap items-center gap-2">
                    <Badge
                      variant="secondary"
                      className={STATUS_COLORS[req.status] ?? ""}
                    >
                      {req.status.replace("_", " ")}
                    </Badge>
                    <span className="flex items-center gap-1 text-xs text-muted-foreground">
                      <MessageSquare className="h-3 w-3" />
                      {req.comment_count}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      by {req.author_name}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      {format(new Date(req.created_at), "MMM d, yyyy")}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <CreateFeatureRequestDialog open={createOpen} onOpenChange={setCreateOpen} />
    </>
  );
}
