"use client";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

interface TierBreakdownProps {
  tierBreakdown: Record<string, number>;
}

const TIER_COLORS: Record<string, string> = {
  FREE: "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300",
  STARTER: "bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300",
  PRO: "bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-300",
  ENTERPRISE:
    "bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-300",
};

const TIER_ORDER = ["FREE", "STARTER", "PRO", "ENTERPRISE"];

export function TierBreakdown({ tierBreakdown }: TierBreakdownProps) {
  const total = Object.values(tierBreakdown).reduce(
    (sum, count) => sum + count,
    0,
  );

  const sortedTiers = TIER_ORDER.filter(
    (tier) => tierBreakdown[tier] !== undefined,
  );

  // Include any unexpected tiers at the end
  const unexpectedTiers = Object.keys(tierBreakdown).filter(
    (tier) => !TIER_ORDER.includes(tier),
  );
  const allTiers = [...sortedTiers, ...unexpectedTiers];

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Tier Breakdown</CardTitle>
        <CardDescription>
          Trainer distribution across subscription tiers
        </CardDescription>
      </CardHeader>
      <CardContent>
        {allTiers.length === 0 ? (
          <p className="text-sm text-muted-foreground">No subscription data</p>
        ) : (
          <div className="space-y-3">
            {allTiers.map((tier) => {
              const count = tierBreakdown[tier] ?? 0;
              const percentage = total > 0 ? (count / total) * 100 : 0;
              return (
                <div key={tier} className="space-y-1">
                  <div className="flex items-center justify-between">
                    <Badge
                      variant="secondary"
                      className={TIER_COLORS[tier] ?? ""}
                    >
                      {tier}
                      <span className="sr-only"> tier</span>
                    </Badge>
                    <span className="text-sm font-medium">
                      {count}{" "}
                      <span className="text-muted-foreground">
                        ({Math.round(percentage)}%)
                      </span>
                    </span>
                  </div>
                  <div className="h-2 overflow-hidden rounded-full bg-muted">
                    <div
                      className="h-full rounded-full bg-primary transition-all"
                      style={{ width: `${percentage}%` }}
                      role="progressbar"
                      aria-valuenow={percentage}
                      aria-valuemin={0}
                      aria-valuemax={100}
                      aria-label={`${tier}: ${count} trainers (${Math.round(percentage)}%)`}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
