"use client";

import { format } from "date-fns";
import { CalendarClock } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import { formatCurrency } from "@/lib/format-utils";

interface UpcomingPayment {
  id: number;
  trainer_email: string;
  trainer_name: string;
  amount: number;
  currency: string;
  due_date: string;
  tier_name: string;
  status: string;
}

export function UpcomingPaymentsList() {
  const { data, isLoading } = useQuery<UpcomingPayment[]>({
    queryKey: ["admin-upcoming-payments"],
    queryFn: () =>
      apiClient.get<UpcomingPayment[]>(API_URLS.ADMIN_UPCOMING_PAYMENTS),
  });

  if (isLoading) {
    return (
      <div className="space-y-3">
        {[1, 2, 3, 4, 5].map((i) => (
          <Skeleton key={i} className="h-16 w-full" />
        ))}
      </div>
    );
  }

  const payments = data ?? [];

  if (payments.length === 0) {
    return (
      <EmptyState
        icon={CalendarClock}
        title="No upcoming payments"
        description="All subscription payments are up to date."
      />
    );
  }

  return (
    <div className="space-y-3">
      {payments.map((payment) => (
        <div
          key={payment.id}
          className="flex items-center justify-between gap-4 rounded-lg border p-4"
        >
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-medium">
              {payment.trainer_name || payment.trainer_email}
            </p>
            <div className="mt-1 flex items-center gap-3 text-xs text-muted-foreground">
              <span>{payment.tier_name}</span>
              <span>
                Due: {format(new Date(payment.due_date), "MMM d, yyyy")}
              </span>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-sm font-medium">
              {formatCurrency(payment.amount)}
            </span>
            <Badge variant="outline">{payment.status}</Badge>
          </div>
        </div>
      ))}
    </div>
  );
}
