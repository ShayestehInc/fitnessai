"use client";

import { useMemo, useState, useCallback } from "react";
import { Pin, Circle } from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import type { Announcement } from "@/types/trainee-dashboard";

interface AnnouncementsListProps {
  announcements: Announcement[];
  onAnnouncementOpen?: (id: number) => void;
}

export function AnnouncementsList({ announcements, onAnnouncementOpen }: AnnouncementsListProps) {
  const sorted = useMemo(() => {
    return [...announcements].sort((a, b) => {
      // Pinned first
      if (a.is_pinned && !b.is_pinned) return -1;
      if (!a.is_pinned && b.is_pinned) return 1;
      // Then by date descending
      return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
    });
  }, [announcements]);

  if (sorted.length === 0) {
    return null;
  }

  return (
    <div className="space-y-3">
      {sorted.map((announcement) => (
        <AnnouncementCard
          key={announcement.id}
          announcement={announcement}
          onOpen={onAnnouncementOpen}
        />
      ))}
    </div>
  );
}

function AnnouncementCard({
  announcement,
  onOpen,
}: {
  announcement: Announcement;
  onOpen?: (id: number) => void;
}) {
  const [expanded, setExpanded] = useState(false);

  const handleToggle = useCallback(() => {
    if (!expanded && !announcement.is_read && onOpen) {
      onOpen(announcement.id);
    }
    setExpanded((prev) => !prev);
  }, [expanded, announcement.is_read, announcement.id, onOpen]);

  return (
    <Card
      className={cn(
        "cursor-pointer transition-colors hover:bg-accent/50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
        !announcement.is_read && "border-primary/30 bg-primary/5",
      )}
      onClick={handleToggle}
      role="button"
      tabIndex={0}
      aria-expanded={expanded}
      aria-label={`${announcement.is_read ? "" : "Unread: "}${announcement.title}${announcement.is_pinned ? " (pinned)" : ""}`}
      onKeyDown={(e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          handleToggle();
        }
      }}
    >
      <CardHeader className="pb-2">
        <div className="flex items-start justify-between gap-2">
          <div className="flex min-w-0 items-center gap-2">
            {!announcement.is_read && (
              <Circle
                className="h-2.5 w-2.5 shrink-0 fill-primary text-primary"
                aria-label="Unread"
              />
            )}
            {announcement.is_pinned && (
              <Pin className="h-4 w-4 shrink-0 text-primary" aria-label="Pinned" />
            )}
            <CardTitle
              className={cn(
                "min-w-0 truncate text-base",
                !announcement.is_read && "font-bold",
              )}
              title={announcement.title}
            >
              {announcement.title}
            </CardTitle>
          </div>
          <Badge variant="outline" className="shrink-0 text-xs">
            {new Date(announcement.created_at).toLocaleDateString(undefined, {
              month: "short",
              day: "numeric",
              year: "numeric",
            })}
          </Badge>
        </div>
      </CardHeader>
      {expanded && (
        <CardContent>
          <p className="whitespace-pre-wrap text-sm text-muted-foreground">
            {announcement.content}
          </p>
        </CardContent>
      )}
    </Card>
  );
}
