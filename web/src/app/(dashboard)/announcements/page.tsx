"use client";

import { useState } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { useAnnouncements } from "@/hooks/use-announcements";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import { AnnouncementList } from "@/components/announcements/announcement-list";
import { AnnouncementListSkeleton } from "@/components/announcements/announcement-list-skeleton";

export default function AnnouncementsPage() {
  const [page, setPage] = useState(1);
  const { data, isLoading, isError, refetch } = useAnnouncements(page);

  const hasNextPage = Boolean(data?.next);
  const hasPrevPage = page > 1;

  if (isLoading) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader title="Announcements" description="Broadcast messages to all your trainees" />
          <AnnouncementListSkeleton />
        </div>
      </PageTransition>
    );
  }

  if (isError) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader title="Announcements" description="Broadcast messages to all your trainees" />
          <ErrorState message="Failed to load announcements" onRetry={() => refetch()} />
        </div>
      </PageTransition>
    );
  }

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader
          title="Announcements"
          description="Broadcast messages to all your trainees"
        />
        <AnnouncementList announcements={data?.results ?? []} />
        {(hasPrevPage || hasNextPage) && (
          <nav className="flex items-center justify-between" aria-label="Announcement pagination">
            <Button
              variant="outline"
              size="sm"
              disabled={!hasPrevPage}
              onClick={() => setPage((p) => p - 1)}
              aria-label="Go to previous page"
            >
              <ChevronLeft className="mr-1 h-4 w-4" aria-hidden="true" />
              Previous
            </Button>
            <span className="text-sm text-muted-foreground" aria-current="page">
              Page {page}
            </span>
            <Button
              variant="outline"
              size="sm"
              disabled={!hasNextPage}
              onClick={() => setPage((p) => p + 1)}
              aria-label="Go to next page"
            >
              Next
              <ChevronRight className="ml-1 h-4 w-4" aria-hidden="true" />
            </Button>
          </nav>
        )}
      </div>
    </PageTransition>
  );
}
