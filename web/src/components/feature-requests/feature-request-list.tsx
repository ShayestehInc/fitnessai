"use client";

import { useState } from "react";
import Link from "next/link";
import { format } from "date-fns";
import { MessageSquare, Lightbulb, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { EmptyState } from "@/components/shared/empty-state";
import { VoteWidget } from "./vote-widget";
import { CreateFeatureRequestDialog } from "./create-feature-request-dialog";
import type { FeatureRequest, FeatureRequestStatus } from "@/types/feature-request";
import {
  STATUS_LABELS,
  STATUS_COLORS,
  CATEGORY_LABELS,
} from "@/types/feature-request";

const STATUS_FILTERS: { value: FeatureRequestStatus | ""; label: string }[] = [
  { value: "", label: "All" },
  { value: "submitted", label: "Submitted" },
  { value: "under_review", label: "Under Review" },
  { value: "planned", label: "Planned" },
  { value: "in_development", label: "In Development" },
  { value: "released", label: "Released" },
  { value: "declined", label: "Declined" },
];

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
            title={
              statusFilter
                ? `No ${STATUS_LABELS[statusFilter]?.toLowerCase() ?? statusFilter} requests`
                : "No feature requests yet"
            }
            description={
              statusFilter
                ? "Try a different filter."
                : "Be the first to submit a feature request!"
            }
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
              <Link
                key={req.id}
                href={`/feature-requests/${req.id}`}
                className="flex items-start gap-4 rounded-lg border p-4 transition-all hover:shadow-sm hover:border-primary/20"
              >
                <VoteWidget
                  featureId={req.id}
                  voteScore={req.vote_score}
                  userVote={req.user_vote}
                  size="sm"
                />
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
                      {STATUS_LABELS[req.status] ?? req.status}
                    </Badge>
                    <Badge variant="outline" className="text-xs">
                      {CATEGORY_LABELS[req.category] ?? req.category}
                    </Badge>
                    <span className="flex items-center gap-1 text-xs text-muted-foreground">
                      <MessageSquare className="h-3 w-3" />
                      {req.comment_count}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      by {req.submitted_by_name || "Anonymous"}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      {format(new Date(req.created_at), "MMM d, yyyy")}
                    </span>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>

      <CreateFeatureRequestDialog open={createOpen} onOpenChange={setCreateOpen} />
    </>
  );
}
