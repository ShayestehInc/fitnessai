"use client";

import Link from "next/link";
import { AlertTriangle } from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { usePastDueSubscriptions } from "@/hooks/use-admin-subscriptions";
import { formatCurrency } from "@/lib/format-utils";

export function PastDueAlerts() {
  const { data: pastDue, isLoading } = usePastDueSubscriptions();

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Past Due Alerts</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <div
                key={i}
                className="h-12 animate-pulse rounded-md bg-muted"
              />
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  const items = pastDue ?? [];
  const displayItems = items.slice(0, 5);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-base">
          <AlertTriangle
            className="h-4 w-4 text-destructive"
            aria-hidden="true"
          />
          Past Due Alerts
        </CardTitle>
        <CardDescription>
          Subscriptions with outstanding balances
        </CardDescription>
      </CardHeader>
      <CardContent>
        {items.length === 0 ? (
          <p className="text-sm text-muted-foreground">
            No past due subscriptions
          </p>
        ) : (
          <div className="space-y-3">
            {displayItems.map((sub) => (
              <div
                key={sub.id}
                className="flex items-center justify-between rounded-md border p-3"
              >
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium">
                    {sub.trainer_name}
                  </p>
                  <p className="truncate text-xs text-muted-foreground">
                    {sub.trainer_email}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <Badge variant="destructive">
                    {formatCurrency(sub.past_due_amount)}
                    <span className="sr-only"> past due</span>
                  </Badge>
                  {sub.days_past_due !== null && sub.days_past_due > 0 && (
                    <span className="text-xs text-muted-foreground">
                      {sub.days_past_due}d
                    </span>
                  )}
                </div>
              </div>
            ))}
            {items.length > 0 && (
              <Button variant="outline" size="sm" className="w-full" asChild>
                <Link href="/admin/subscriptions?past_due=true">
                  View All ({items.length})
                </Link>
              </Button>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
