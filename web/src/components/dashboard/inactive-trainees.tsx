"use client";

import Link from "next/link";
import { formatDistanceToNow } from "date-fns";
import { AlertTriangle } from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import type { TraineeListItem } from "@/types/trainer";

interface InactiveTraineesProps {
  trainees: TraineeListItem[];
}

export function InactiveTrainees({ trainees }: InactiveTraineesProps) {
  if (trainees.length === 0) return null;

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-amber-500" aria-hidden="true" />
          <CardTitle>Needs Attention</CardTitle>
        </div>
        <CardDescription>
          Trainees who haven&apos;t logged activity recently
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {trainees.map((t) => (
            <Link
              key={t.id}
              href={`/trainees/${t.id}`}
              aria-label={`View ${`${t.first_name} ${t.last_name}`.trim() || t.email} — ${t.last_activity ? `last active ${formatDistanceToNow(new Date(t.last_activity), { addSuffix: true })}` : "never logged"}`}
              className="flex items-center justify-between gap-3 rounded-md p-2 transition-colors hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            >
              <div className="min-w-0">
                <p className="truncate text-sm font-medium">
                  {`${t.first_name} ${t.last_name}`.trim() || t.email}
                </p>
                <p className="truncate text-xs text-muted-foreground">{t.email}</p>
              </div>
              <p className="shrink-0 whitespace-nowrap text-xs text-muted-foreground">
                {t.last_activity
                  ? `Last active ${formatDistanceToNow(new Date(t.last_activity), { addSuffix: true })}`
                  : "Never logged"}
              </p>
            </Link>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
