"use client";

import { useMessagingUnreadCount } from "@/hooks/use-messaging";
import { useAnnouncementUnreadCount } from "@/hooks/use-trainee-announcements";

export interface TraineeBadgeCounts {
  messages: number;
  announcements: number;
}

export function useTraineeBadgeCounts(): TraineeBadgeCounts {
  const { data: unreadMessages } = useMessagingUnreadCount();
  const { data: unreadAnnouncements } = useAnnouncementUnreadCount();

  return {
    messages: unreadMessages?.unread_count ?? 0,
    announcements: unreadAnnouncements?.unread_count ?? 0,
  };
}

export function getBadgeCount(
  counts: TraineeBadgeCounts,
  badgeKey?: string,
): number {
  if (badgeKey === "messages") return counts.messages;
  if (badgeKey === "announcements") return counts.announcements;
  return 0;
}
