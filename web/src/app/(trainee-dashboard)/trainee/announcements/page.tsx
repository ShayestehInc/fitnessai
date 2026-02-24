"use client";

import { useCallback } from "react";
import { Megaphone, CheckCheck, Loader2 } from "lucide-react";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { Button } from "@/components/ui/button";
import { AnnouncementsList } from "@/components/trainee-dashboard/announcements-list";
import {
  useAnnouncements,
  useAnnouncementUnreadCount,
  useMarkAnnouncementsRead,
  useMarkAnnouncementRead,
} from "@/hooks/use-trainee-announcements";
import { toast } from "sonner";

export default function AnnouncementsPage() {
  const { data: announcements, isLoading, isError, refetch } =
    useAnnouncements();
  const { data: unreadData } = useAnnouncementUnreadCount();
  const markAllRead = useMarkAnnouncementsRead();
  const markOneRead = useMarkAnnouncementRead();

  const unreadCount = unreadData?.unread_count ?? 0;

  const handleMarkAllRead = () => {
    markAllRead.mutate(undefined, {
      onSuccess: () => {
        toast.success("All announcements marked as read");
      },
      onError: () => {
        toast.error("Failed to mark announcements as read");
      },
    });
  };

  const handleAnnouncementOpen = useCallback(
    (id: number) => {
      markOneRead.mutate(id);
    },
    // markOneRead.mutate is stable across renders (from useMutation)
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [markOneRead.mutate],
  );

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Announcements"
          description="Updates from your trainer"
        />
        <LoadingSpinner label="Loading announcements..." />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Announcements"
          description="Updates from your trainer"
        />
        <ErrorState
          message="Failed to load announcements. Please try again."
          onRetry={() => refetch()}
        />
      </div>
    );
  }

  return (
    <PageTransition>
      <div className="space-y-6">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <PageHeader
            title="Announcements"
            description="Updates from your trainer"
          />
          {unreadCount > 0 && (
            <Button
              variant="outline"
              size="sm"
              onClick={handleMarkAllRead}
              disabled={markAllRead.isPending}
              className="gap-2 self-start sm:self-auto"
            >
              {markAllRead.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <CheckCheck className="h-4 w-4" />
              )}
              {markAllRead.isPending ? "Marking..." : "Mark all read"}
              {!markAllRead.isPending && (
                <span className="rounded-full bg-primary px-1.5 py-0.5 text-xs text-primary-foreground">
                  {unreadCount}
                </span>
              )}
            </Button>
          )}
        </div>

        {!announcements?.length ? (
          <EmptyState
            icon={Megaphone}
            title="No announcements yet"
            description="Your trainer hasn't posted any announcements yet. Check back later!"
          />
        ) : (
          <AnnouncementsList
            announcements={announcements}
            onAnnouncementOpen={handleAnnouncementOpen}
          />
        )}
      </div>
    </PageTransition>
  );
}
