"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

interface ReferralStatusBreakdownProps {
  active: number;
  pending: number;
  churned: number;
}

export function ReferralStatusBreakdown({
  active,
  pending,
  churned,
}: ReferralStatusBreakdownProps) {
  const total = active + pending + churned;

  if (total === 0) return null;

  const segments = [
    {
      label: "Active",
      count: active,
      color: "bg-green-500",
      textColor: "text-green-600 dark:text-green-400",
    },
    {
      label: "Pending",
      count: pending,
      color: "bg-amber-500",
      textColor: "text-amber-600 dark:text-amber-400",
    },
    {
      label: "Churned",
      count: churned,
      color: "bg-muted-foreground/40",
      textColor: "text-muted-foreground",
    },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle>Referral Status</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Stacked bar */}
        <div
          className="flex h-3 w-full overflow-hidden rounded-full"
          role="img"
          aria-label={`Referral breakdown: ${active} active, ${pending} pending, ${churned} churned out of ${total} total`}
        >
          {segments.map(
            (seg) =>
              seg.count > 0 && (
                <div
                  key={seg.label}
                  className={`${seg.color} transition-all`}
                  style={{ width: `${(seg.count / total) * 100}%` }}
                />
              ),
          )}
        </div>

        {/* Legend */}
        <div className="flex flex-wrap gap-4">
          {segments.map((seg) => (
            <div key={seg.label} className="flex items-center gap-2">
              <div className={`h-2.5 w-2.5 rounded-full ${seg.color}`} />
              <span className="text-sm text-muted-foreground">
                {seg.label}
              </span>
              <span className={`text-sm font-medium ${seg.textColor}`}>
                {seg.count}
              </span>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
