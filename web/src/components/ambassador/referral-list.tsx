"use client";

import { useState } from "react";
import { format } from "date-fns";
import { Search, Users } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { useAmbassadorReferrals } from "@/hooks/use-ambassador";
import { formatCurrency } from "@/lib/format-utils";
import type { AmbassadorSelfReferral } from "@/types/ambassador";

export function ReferralList() {
  const [search, setSearch] = useState("");
  const { data, isLoading } = useAmbassadorReferrals();

  const referrals = data?.results ?? [];
  const filtered = search
    ? referrals.filter(
        (r) =>
          `${r.trainer.first_name} ${r.trainer.last_name}`.toLowerCase().includes(search.toLowerCase()) ||
          r.trainer.email.toLowerCase().includes(search.toLowerCase()),
      )
    : referrals;

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-10 w-full sm:max-w-sm" />
        {[1, 2, 3, 4].map((i) => (
          <Skeleton key={i} className="h-16 w-full" />
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="relative sm:max-w-sm">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search referrals..."
          className="pl-9"
        />
      </div>

      {filtered.length === 0 ? (
        <EmptyState
          icon={Users}
          title={search ? "No referrals match your search" : "No referrals yet"}
          description={
            search
              ? "Try adjusting your search."
              : "Share your referral code to start earning commissions."
          }
        />
      ) : (
        <div className="space-y-3">
          {filtered.map((ref) => (
            <div
              key={ref.id}
              className="flex items-center justify-between gap-4 rounded-lg border p-4"
            >
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium">
                  {`${ref.trainer.first_name} ${ref.trainer.last_name}`.trim() || ref.trainer.email}
                </p>
                <div className="mt-1 flex items-center gap-3 text-xs text-muted-foreground">
                  <span>{ref.trainer.email}</span>
                  {ref.referred_at && (
                    <span>
                      {format(new Date(ref.referred_at), "MMM d, yyyy")}
                    </span>
                  )}
                </div>
              </div>
              <div className="flex items-center gap-3">
                {ref.total_commission_earned !== undefined && (
                  <span className="text-sm font-medium text-green-600">
                    {formatCurrency(ref.total_commission_earned)}
                  </span>
                )}
                <Badge
                  variant={ref.status === "active" ? "default" : "secondary"}
                >
                  {ref.status}
                </Badge>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
