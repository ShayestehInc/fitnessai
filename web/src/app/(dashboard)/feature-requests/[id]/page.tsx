"use client";

import { use } from "react";
import Link from "next/link";
import { format } from "date-fns";
import { ArrowLeft, Loader2, Info } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { PageTransition } from "@/components/shared/page-transition";
import { ErrorState } from "@/components/shared/error-state";
import { useFeatureRequest } from "@/hooks/use-feature-requests";
import { VoteWidget } from "@/components/feature-requests/vote-widget";
import { FeatureRequestComments } from "@/components/feature-requests/feature-request-comments";
import {
  STATUS_LABELS,
  STATUS_COLORS,
  CATEGORY_LABELS,
} from "@/types/feature-request";

interface FeatureRequestDetailPageProps {
  params: Promise<{ id: string }>;
}

export default function FeatureRequestDetailPage({
  params,
}: FeatureRequestDetailPageProps) {
  const { id: idParam } = use(params);
  const id = Number(idParam);
  const { data: feature, isLoading, isError, refetch } = useFeatureRequest(id);

  if (isLoading) {
    return (
      <PageTransition>
        <div className="flex items-center justify-center py-16">
          <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
        </div>
      </PageTransition>
    );
  }

  if (isError || !feature) {
    return (
      <PageTransition>
        <ErrorState
          message="Failed to load feature request"
          onRetry={() => refetch()}
        />
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="mx-auto max-w-3xl space-y-6">
        <Link
          href="/feature-requests"
          className="inline-flex items-center gap-1 text-sm text-muted-foreground transition-colors hover:text-foreground"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to requests
        </Link>

        <div className="flex items-start gap-4">
          <VoteWidget
            featureId={feature.id}
            voteScore={feature.vote_score}
            userVote={feature.user_vote}
            size="md"
          />
          <div className="flex-1 min-w-0 space-y-2">
            <h1 className="text-2xl font-bold">{feature.title}</h1>
            <div className="flex flex-wrap items-center gap-2">
              <Badge
                variant="secondary"
                className={STATUS_COLORS[feature.status] ?? ""}
              >
                {STATUS_LABELS[feature.status] ?? feature.status}
              </Badge>
              <Badge variant="outline">
                {CATEGORY_LABELS[feature.category] ?? feature.category}
              </Badge>
              <span className="text-sm text-muted-foreground">
                by {feature.submitted_by_name || "Anonymous"}
              </span>
              <span className="text-sm text-muted-foreground">
                {format(new Date(feature.created_at), "MMM d, yyyy")}
              </span>
            </div>
          </div>
        </div>

        <div className="rounded-lg border p-4">
          <p className="whitespace-pre-wrap text-sm leading-relaxed">
            {feature.description}
          </p>
        </div>

        {feature.public_response && (
          <div className="rounded-lg border border-primary/30 bg-primary/5 p-4 space-y-2">
            <div className="flex items-center gap-2">
              <Info className="h-4 w-4 text-primary" />
              <h3 className="text-sm font-semibold">Official Response</h3>
            </div>
            <p className="whitespace-pre-wrap text-sm text-muted-foreground">
              {feature.public_response}
            </p>
            {feature.target_release && (
              <p className="text-xs text-muted-foreground">
                Target release: <strong>{feature.target_release}</strong>
              </p>
            )}
          </div>
        )}

        <hr />

        <FeatureRequestComments featureId={feature.id} />
      </div>
    </PageTransition>
  );
}
