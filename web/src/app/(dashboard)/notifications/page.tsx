"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
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
import {
  NotificationItem,
  getNotificationTraineeId,
} from "@/components/notifications/notification-item";
import type { Notification } from "@/types/notification";
import { useLocale } from "@/providers/locale-provider";

type Filter = "all" | "unread";

export default function NotificationsPage() {
  const { t } = useLocale();
  const router = useRouter();
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

  const handleNotificationClick = (n: Notification) => {
    const traineeId = getNotificationTraineeId(n);

    if (!n.is_read) {
      markAsRead.mutate(n.id, {
        onError: () => toast.error(t("error.failedToMarkNotification")),
      });
    }

    if (traineeId !== null) {
      router.push(`/trainees/${traineeId}`);
    } else if (!n.is_read) {
      toast.success(t("notifications.markedRead"));
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title={t("nav.notifications")}
        description={t("notifications.description")}
        actions={
          hasUnread ? (
            <Button
              variant="outline"
              size="sm"
              onClick={() =>
                markAllAsRead.mutate(undefined, {
                  onSuccess: () => toast.success(t("notifications.allRead")),
                  onError: () => toast.error(t("error.failedToMarkNotifications")),
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
          <TabsTrigger value="all">{t("common.all")}</TabsTrigger>
          <TabsTrigger value="unread">{t("notifications.unread")}</TabsTrigger>
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
              onClick={() => handleNotificationClick(n)}
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
                <ChevronLeft className="h-4 w-4" aria-hidden="true" />
                <span className="hidden sm:inline">{t("common.previous")}</span>
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
                <span className="hidden sm:inline">{t("common.next")}</span>
                <ChevronRight className="h-4 w-4" aria-hidden="true" />
              </Button>
            </nav>
          )}
        </div>
      )}
    </div>
  );
}
