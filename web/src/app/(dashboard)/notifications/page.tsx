"use client";

import { useState } from "react";
import { Bell, ChevronLeft, ChevronRight } from "lucide-react";
import { toast } from "sonner";
import {
  useNotifications,
  useMarkAsRead,
  useMarkAllAsRead,
  useUnreadCount,
} from "@/hooks/use-notifications";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { LoadingSpinner } from "@/components/shared/loading-spinner";
import { Button } from "@/components/ui/button";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { NotificationItem } from "@/components/notifications/notification-item";

type Filter = "all" | "unread";

export default function NotificationsPage() {
  const [filter, setFilter] = useState<Filter>("all");
  const [page, setPage] = useState(1);
  const { data, isLoading, isError, refetch } = useNotifications(page, filter);
  const markAsRead = useMarkAsRead();
  const markAllAsRead = useMarkAllAsRead();
  const { data: unreadCountData } = useUnreadCount();

  const notifications = data?.results ?? [];
  const hasUnread = (unreadCountData?.unread_count ?? 0) > 0;
  const hasNextPage = Boolean(data?.next);
  const hasPrevPage = page > 1;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Notifications"
        description="Stay updated on trainee activity"
        actions={
          hasUnread ? (
            <Button
              variant="outline"
              size="sm"
              onClick={() =>
                markAllAsRead.mutate(undefined, {
                  onSuccess: () => toast.success("All notifications marked as read"),
                  onError: () => toast.error("Failed to mark notifications as read"),
                })
              }
              disabled={markAllAsRead.isPending}
            >
              Mark all as read
            </Button>
          ) : undefined
        }
      />

      <Tabs
        value={filter}
        onValueChange={(v) => {
          if (v === "all" || v === "unread") {
            setFilter(v);
            setPage(1);
          }
        }}
      >
        <TabsList>
          <TabsTrigger value="all">All</TabsTrigger>
          <TabsTrigger value="unread">Unread</TabsTrigger>
        </TabsList>
      </Tabs>

      {isLoading ? (
        <LoadingSpinner />
      ) : isError ? (
        <ErrorState
          message="Failed to load notifications"
          onRetry={() => refetch()}
        />
      ) : notifications.length === 0 ? (
        <EmptyState
          icon={Bell}
          title={filter === "unread" ? "All caught up" : "No notifications"}
          description={
            filter === "unread"
              ? "You have no unread notifications."
              : "Notifications about your trainees will appear here."
          }
        />
      ) : (
        <div className="max-w-2xl space-y-1">
          {notifications.map((n) => (
            <NotificationItem
              key={n.id}
              notification={n}
              onClick={() => {
                if (!n.is_read) {
                  markAsRead.mutate(n.id, {
                    onError: () => toast.error("Failed to mark notification as read"),
                  });
                }
              }}
            />
          ))}

          {(hasPrevPage || hasNextPage) && (
            <nav className="flex items-center justify-between pt-4" aria-label="Notification pagination">
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
      )}
    </div>
  );
}
