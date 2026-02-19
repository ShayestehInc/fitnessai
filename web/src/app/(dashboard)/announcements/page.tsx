"use client";

import { useState } from "react";
import { Plus } from "lucide-react";
import { useAnnouncements } from "@/hooks/use-announcements";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import { AnnouncementList } from "@/components/announcements/announcement-list";
import { AnnouncementListSkeleton } from "@/components/announcements/announcement-list-skeleton";

export default function AnnouncementsPage() {
  const [page] = useState(1);
  const { data, isLoading, isError, refetch } = useAnnouncements(page);

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
      </div>
    </PageTransition>
  );
}
