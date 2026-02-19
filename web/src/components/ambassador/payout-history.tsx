"use client";

import { format } from "date-fns";
import { DollarSign } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { useAmbassadorPayouts } from "@/hooks/use-ambassador";
import { formatCurrency } from "@/lib/format-utils";
import type { AmbassadorPayout } from "@/types/ambassador";

export function PayoutHistory() {
  const { data, isLoading } = useAmbassadorPayouts();

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <Skeleton className="h-5 w-32" />
        </CardHeader>
        <CardContent className="space-y-3">
          {[1, 2, 3].map((i) => (
            <Skeleton key={i} className="h-16 w-full" />
          ))}
        </CardContent>
      </Card>
    );
  }

  const payouts = (data ?? []) as AmbassadorPayout[];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Payout History</CardTitle>
      </CardHeader>
      <CardContent>
        {payouts.length === 0 ? (
          <EmptyState
            icon={DollarSign}
            title="No payouts yet"
            description="Your payout history will appear here once you earn commissions."
          />
        ) : (
          <div className="space-y-3">
            {payouts.map((payout) => (
              <div
                key={payout.id}
                className="flex items-center justify-between gap-3 rounded-md border p-3"
              >
                <div className="min-w-0">
                  <p className="text-sm font-medium">
                    {formatCurrency(payout.amount)}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {payout.created_at
                      ? format(new Date(payout.created_at), "MMM d, yyyy")
                      : "N/A"}
                  </p>
                </div>
                <Badge
                  variant={
                    payout.status === "paid"
                      ? "default"
                      : payout.status === "pending"
                        ? "outline"
                        : "secondary"
                  }
                >
                  {payout.status}
                </Badge>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
