import { TrendingUp, TrendingDown, Minus } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { cn } from "@/lib/utils";

interface StatCardProps {
  title: string;
  value: string | number;
  description?: string;
  icon: LucideIcon;
  /** Optional extra classes applied to the value text (e.g. color indicators) */
  valueClassName?: string;
  /** Optional trend indicator: positive = up, negative = down, 0 = flat */
  trend?: number;
  /** Optional label for the trend (e.g. "vs last week") */
  trendLabel?: string;
}

function TrendIndicator({ trend, label }: { trend: number; label?: string }) {
  if (trend === 0) {
    return (
      <span className="inline-flex items-center gap-1 text-xs text-muted-foreground">
        <Minus className="h-3 w-3" aria-hidden="true" />
        {label ?? "No change"}
      </span>
    );
  }

  const isPositive = trend > 0;
  const Icon = isPositive ? TrendingUp : TrendingDown;

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 text-xs font-medium",
        isPositive ? "text-green-600" : "text-red-500",
      )}
    >
      <Icon className="h-3 w-3" aria-hidden="true" />
      {isPositive ? "+" : ""}
      {trend}%
      {label && (
        <span className="font-normal text-muted-foreground"> {label}</span>
      )}
    </span>
  );
}

export function StatCard({
  title,
  value,
  description,
  icon: Icon,
  valueClassName,
  trend,
  trendLabel,
}: StatCardProps) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{title}</CardTitle>
        <Icon className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
      </CardHeader>
      <CardContent>
        <div className={cn("truncate text-2xl font-bold", valueClassName)} title={String(value)}>{value}</div>
        {trend !== undefined && (
          <TrendIndicator trend={trend} label={trendLabel} />
        )}
        {description && (
          <p className="text-xs text-muted-foreground">{description}</p>
        )}
      </CardContent>
    </Card>
  );
}
