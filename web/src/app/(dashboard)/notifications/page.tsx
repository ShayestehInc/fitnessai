"use client";

import { useState } from "react";
import { Bell, ChevronLeft, ChevronRight } from "lucide-react";
import {
  useNotifications,
  useMarkAsRead,
  useMarkAllAsRead,
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

  const notifications = data?.results ?? [];
  const hasUnread = notifications.some((n) => !n.is_read);
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
              onClick={() => markAllAsRead.mutate()}
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
                if (!n.is_read) markAsRead.mutate(n.id);
              }}
            />
          ))}

          {(hasPrevPage || hasNextPage) && (
            <div className="flex items-center justify-between pt-4">
              <Button
                variant="outline"
                size="sm"
                disabled={!hasPrevPage}
                onClick={() => setPage((p) => p - 1)}
              >
                <ChevronLeft className="mr-1 h-4 w-4" />
                Previous
              </Button>
              <span className="text-sm text-muted-foreground">
                Page {page}
              </span>
              <Button
                variant="outline"
                size="sm"
                disabled={!hasNextPage}
                onClick={() => setPage((p) => p + 1)}
              >
                Next
                <ChevronRight className="ml-1 h-4 w-4" />
              </Button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
