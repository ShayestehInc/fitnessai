"use client";

import { format } from "date-fns";
import { AlertTriangle, Mail } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { useQuery } from "@tanstack/react-query";
import { apiClient } from "@/lib/api-client";
import { API_URLS } from "@/lib/constants";
import { formatCurrency } from "@/lib/format-utils";
import { cn } from "@/lib/utils";

interface PastDueItem {
  id: number;
  trainer_email: string;
  trainer_name: string;
  amount: number;
  currency: string;
  due_date: string;
  days_overdue: number;
  tier_name: string;
  status: string;
}

function getSeverityColor(daysOverdue: number): string {
  if (daysOverdue >= 30) return "text-destructive";
  if (daysOverdue >= 14) return "text-orange-500";
  return "text-yellow-600";
}

function getSeverityBadge(daysOverdue: number): string {
  if (daysOverdue >= 30) return "Critical";
  if (daysOverdue >= 14) return "Warning";
  return "Overdue";
}

export function PastDueFullList() {
  const { data, isLoading } = useQuery<PastDueItem[]>({
    queryKey: ["admin-past-due"],
    queryFn: () => apiClient.get<PastDueItem[]>(API_URLS.ADMIN_PAST_DUE),
  });

  if (isLoading) {
    return (
      <div className="space-y-3">
        {[1, 2, 3, 4].map((i) => (
          <Skeleton key={i} className="h-20 w-full" />
        ))}
      </div>
    );
  }

  const items = data ?? [];

  if (items.length === 0) {
    return (
      <EmptyState
        icon={AlertTriangle}
        title="No past due payments"
        description="All trainers are current with their subscriptions."
      />
    );
  }

  const sorted = [...items].sort((a, b) => b.days_overdue - a.days_overdue);

  return (
    <div className="space-y-3">
      {sorted.map((item) => (
        <div
          key={item.id}
          className="flex items-center justify-between gap-4 rounded-lg border p-4"
        >
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <p className="truncate text-sm font-medium">
                {item.trainer_name || item.trainer_email}
              </p>
              <Badge
                variant={item.days_overdue >= 30 ? "destructive" : "outline"}
              >
                {getSeverityBadge(item.days_overdue)}
              </Badge>
            </div>
            <div className="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground">
              <span>{item.tier_name}</span>
              <span>
                Due: {format(new Date(item.due_date), "MMM d, yyyy")}
              </span>
              <span className={cn("font-medium", getSeverityColor(item.days_overdue))}>
                {item.days_overdue} days overdue
              </span>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-sm font-medium">
              {formatCurrency(item.amount)}
            </span>
            <Button
              variant="ghost"
              size="sm"
              onClick={() =>
                toast.info(`Reminder email would be sent to ${item.trainer_email}`)
              }
            >
              <Mail className="h-4 w-4" />
            </Button>
          </div>
        </div>
      ))}
    </div>
  );
}
