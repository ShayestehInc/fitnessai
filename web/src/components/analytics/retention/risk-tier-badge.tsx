"use client";

import { cn } from "@/lib/utils";
import type { RiskTier } from "@/types/retention";

const TIER_STYLES: Record<RiskTier, string> = {
  critical: "bg-red-500/15 text-red-500 border-red-500/25",
  high: "bg-orange-500/15 text-orange-500 border-orange-500/25",
  medium: "bg-yellow-500/15 text-yellow-500 border-yellow-500/25",
  low: "bg-green-500/15 text-green-500 border-green-500/25",
};

const TIER_LABELS: Record<RiskTier, string> = {
  critical: "Critical",
  high: "High",
  medium: "Medium",
  low: "Low",
};

interface RiskTierBadgeProps {
  tier: RiskTier;
  className?: string;
}

export function RiskTierBadge({ tier, className }: RiskTierBadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full border px-2 py-0.5 text-xs font-medium",
        TIER_STYLES[tier],
        className,
      )}
    >
      {TIER_LABELS[tier]}
    </span>
  );
}
