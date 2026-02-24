"use client";

import { useCallback } from "react";
import { format } from "date-fns";
import { CalendarDays, Link2, Link2Off, Loader2 } from "lucide-react";
import { toast } from "sonner";
import {
  useCalendarConnections,
  useCalendarEvents,
  useGoogleCalendarAuth,
  useDisconnectCalendar,
} from "@/hooks/use-calendar";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { CalendarSkeleton } from "@/components/calendar/calendar-skeleton";
import { getErrorMessage } from "@/lib/error-utils";
import type { CalendarConnection } from "@/types/calendar";

export default function CalendarPage() {
  const connections = useCalendarConnections();
  const events = useCalendarEvents();
  const googleAuth = useGoogleCalendarAuth();
  const disconnectMutation = useDisconnectCalendar();

  const isLoading = connections.isLoading;
  const isError = connections.isError;

  const handleConnectGoogle = useCallback(() => {
    googleAuth.mutate(undefined, {
      onSuccess: (data) => {
        window.open(data.url, "_blank", "width=600,height=700");
      },
      onError: (err) => toast.error(getErrorMessage(err)),
    });
  }, [googleAuth]);

  const handleDisconnect = useCallback(
    (conn: CalendarConnection) => {
      disconnectMutation.mutate(conn.id, {
        onSuccess: () => toast.success(`${conn.provider} calendar disconnected`),
        onError: (err) => toast.error(getErrorMessage(err)),
      });
    },
    [disconnectMutation],
  );

  if (isLoading) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader title="Calendar" description="Connect and manage your calendars" />
          <CalendarSkeleton />
        </div>
      </PageTransition>
    );
  }

  if (isError) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader title="Calendar" description="Connect and manage your calendars" />
          <ErrorState message="Failed to load calendar data" onRetry={() => connections.refetch()} />
        </div>
      </PageTransition>
    );
  }

  const rawConns = connections.data;
  const conns: CalendarConnection[] = Array.isArray(rawConns)
    ? rawConns
    : (rawConns as unknown as { results?: CalendarConnection[] })?.results ?? [];
  const hasConnections = conns.length > 0;

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader title="Calendar" description="Connect and manage your calendars" />

        {/* Connections */}
        <div className="grid gap-4 sm:grid-cols-2">
          {conns.map((conn) => (
            <Card key={conn.id}>
              <CardHeader>
                <CardTitle className="capitalize">{conn.provider} Calendar</CardTitle>
                <CardDescription>{conn.email}</CardDescription>
              </CardHeader>
              <CardContent className="flex items-center gap-3">
                <Badge
                  variant={conn.status === "connected" ? "default" : "secondary"}
                  className={
                    conn.status === "connected"
                      ? "bg-green-500 text-white"
                      : conn.status === "expired"
                        ? "bg-amber-100 text-amber-800"
                        : ""
                  }
                >
                  {conn.status}
                </Badge>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleDisconnect(conn)}
                  disabled={disconnectMutation.isPending}
                >
                  <Link2Off className="mr-1 h-3 w-3" />
                  Disconnect
                </Button>
              </CardContent>
            </Card>
          ))}

          {/* Connect buttons for missing providers */}
          {!conns.find((c) => c.provider === "google") && (
            <Card>
              <CardHeader>
                <CardTitle>Google Calendar</CardTitle>
                <CardDescription>Connect your Google Calendar</CardDescription>
              </CardHeader>
              <CardContent>
                <Button onClick={handleConnectGoogle} disabled={googleAuth.isPending}>
                  {googleAuth.isPending && (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  )}
                  <Link2 className="mr-2 h-4 w-4" />
                  Connect Google
                </Button>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Events */}
        {hasConnections && (
          <Card>
            <CardHeader>
              <CardTitle>Upcoming Events</CardTitle>
            </CardHeader>
            <CardContent>
              {events.isLoading ? (
                <div className="space-y-3">
                  {[1, 2, 3].map((i) => (
                    <div key={i} className="h-14 animate-pulse rounded bg-muted" />
                  ))}
                </div>
              ) : events.data && events.data.length > 0 ? (
                <div className="space-y-3">
                  {events.data.map((event) => (
                    <div
                      key={event.id}
                      className="flex items-center justify-between rounded-md border p-3"
                    >
                      <div>
                        <p className="text-sm font-medium">{event.title}</p>
                        <p className="text-xs text-muted-foreground">
                          {format(new Date(event.start_time), "MMM d, h:mm a")} -{" "}
                          {format(new Date(event.end_time), "h:mm a")}
                        </p>
                      </div>
                      <Badge variant="secondary" className="capitalize">
                        {event.calendar_provider}
                      </Badge>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="py-4 text-center text-sm text-muted-foreground">
                  No upcoming events this week
                </p>
              )}
            </CardContent>
          </Card>
        )}

        {!hasConnections && (
          <EmptyState
            icon={CalendarDays}
            title="Connect your calendar"
            description="Connect your calendar to see upcoming events and manage your schedule."
            action={
              <Button onClick={handleConnectGoogle}>
                <Link2 className="mr-2 h-4 w-4" />
                Connect Google Calendar
              </Button>
            }
          />
        )}
      </div>
    </PageTransition>
  );
}
