"use client";

import { format } from "date-fns";
import { Users } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/shared/empty-state";
import type { AmbassadorSelfReferral } from "@/types/ambassador";

interface RecentReferralsListProps {
  referrals: AmbassadorSelfReferral[];
}

export function RecentReferralsList({ referrals }: RecentReferralsListProps) {
  if (referrals.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Recent Referrals</CardTitle>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={Users}
            title="No referrals yet"
            description="Share your referral code to start earning commissions."
          />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Referrals</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {referrals.slice(0, 5).map((ref) => (
          <div
            key={ref.id}
            className="flex items-center justify-between gap-3 rounded-md border p-3"
          >
            <div className="min-w-0">
              <p className="truncate text-sm font-medium">
                {ref.trainer_name || ref.trainer_email}
              </p>
              <p className="text-xs text-muted-foreground">
                {ref.created_at
                  ? format(new Date(ref.created_at), "MMM d, yyyy")
                  : "N/A"}
              </p>
            </div>
            <Badge
              variant={ref.status === "active" ? "default" : "secondary"}
            >
              {ref.status}
            </Badge>
          </div>
        ))}
      </CardContent>
    </Card>
  );
}
