"use client";

import { useMemo } from "react";
import { Pin, Megaphone } from "lucide-react";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import type { Announcement } from "@/types/trainee-dashboard";

interface AnnouncementsListProps {
  announcements: Announcement[];
}

export function AnnouncementsList({ announcements }: AnnouncementsListProps) {
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
        <Card key={announcement.id}>
          <CardHeader className="pb-2">
            <div className="flex items-start justify-between gap-2">
              <div className="flex items-center gap-2">
                {announcement.is_pinned && (
                  <Pin className="h-4 w-4 shrink-0 text-primary" aria-label="Pinned" />
                )}
                <CardTitle className="text-base">{announcement.title}</CardTitle>
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
          <CardContent>
            <p className="whitespace-pre-wrap text-sm text-muted-foreground">
              {announcement.content}
            </p>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
