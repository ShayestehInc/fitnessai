"use client";

import { format } from "date-fns";
import { Users } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/shared/empty-state";
import type { AmbassadorSelfReferral } from "@/types/ambassador";
import { useLocale } from "@/providers/locale-provider";

interface RecentReferralsListProps {
  referrals: AmbassadorSelfReferral[];
}

export function RecentReferralsList({ referrals }: RecentReferralsListProps) {
  const { t } = useLocale();
  if (referrals.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Recent Referrals</CardTitle>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={Users}
            title={t("ambassador.noReferrals")}
            description={t("ambassador.noReferralsDesc")}
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
                {`${ref.trainer.first_name} ${ref.trainer.last_name}`.trim() || ref.trainer.email}
              </p>
              <p className="text-xs text-muted-foreground">
                {ref.referred_at
                  ? format(new Date(ref.referred_at), "MMM d, yyyy")
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
