"use client";

import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  Legend,
  CartesianGrid,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { TrendingUp } from "lucide-react";
import { tooltipContentStyle, CHART_COLORS } from "@/lib/chart-utils";
import { useAdherenceTrends } from "@/hooks/use-analytics";
import type { AdherencePeriod, AdherenceTrendPoint } from "@/types/analytics";

interface AdherenceTrendChartProps {
  days: AdherencePeriod;
}

function formatDateLabel(dateStr: string, periodDays: number): string {
  const date = new Date(dateStr + "T00:00:00");
  if (periodDays <= 14) {
    return date.toLocaleDateString(undefined, { month: "short", day: "numeric" });
  }
  return date.toLocaleDateString(undefined, { day: "numeric" });
}

function formatFullDate(dateStr: string): string {
  const date = new Date(dateStr + "T00:00:00");
  return date.toLocaleDateString(undefined, {
    weekday: "short",
    month: "long",
    day: "numeric",
  });
}

function formatRate(value: number): string {
  return `${value.toFixed(1)}%`;
}

const METRICS = [
  { key: "food_logged_rate", name: "Food Logged", color: CHART_COLORS.food },
  { key: "workout_logged_rate", name: "Workouts Logged", color: CHART_COLORS.workout },
  { key: "protein_goal_rate", name: "Protein Goal", color: CHART_COLORS.protein },
  { key: "calorie_goal_rate", name: "Calorie Goal", color: CHART_COLORS.calorie },
] as const;

function CustomTooltip({
  active,
  payload,
  label,
}: {
  active?: boolean;
  payload?: Array<{ name: string; value: number; color: string; payload?: AdherenceTrendPoint }>;
  label?: string;
}) {
  if (!active || !payload?.length || !label) return null;

  const point = payload[0]?.payload;

  return (
    <div style={tooltipContentStyle} className="px-3 py-2 text-sm shadow-lg">
      <p className="mb-1 font-medium">{formatFullDate(String(label))}</p>
      {payload.map((entry) => (
        <div key={entry.name} className="flex items-center gap-2">
          <div
            className="h-2 w-2 rounded-full"
            style={{ backgroundColor: entry.color }}
          />
          <span className="text-muted-foreground">{entry.name}:</span>
          <span className="font-medium">{formatRate(entry.value)}</span>
        </div>
      ))}
      {point && (
        <p className="mt-1 text-xs text-muted-foreground">
          {point.trainee_count} trainee{point.trainee_count !== 1 ? "s" : ""} tracked
        </p>
      )}
    </div>
  );
}

function TrendChartSkeleton() {
  return (
    <Card>
      <div role="status" aria-label="Loading adherence trends">
        <span className="sr-only">Loading adherence trends...</span>
        <CardHeader>
          <Skeleton className="h-5 w-48" />
        </CardHeader>
        <CardContent>
          <Skeleton className="h-[240px] w-full" />
        </CardContent>
      </div>
    </Card>
  );
}

export function AdherenceTrendChart({ days }: AdherenceTrendChartProps) {
  const { data, isLoading, isError, isFetching, refetch } =
    useAdherenceTrends(days);

  if (isLoading) return <TrendChartSkeleton />;

  if (isError) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Adherence Trends</CardTitle>
        </CardHeader>
        <CardContent>
          <ErrorState
            message="Failed to load trend data"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  const trends = data?.trends ?? [];

  if (trends.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Adherence Trends</CardTitle>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={TrendingUp}
            title="No trend data yet"
            description="Daily adherence trends will appear here once trainees start logging."
          />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">
          Adherence Trends ({days}-day)
          <span className="ml-2 text-sm font-normal text-muted-foreground">
            Daily rates across all trainees
          </span>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div aria-busy={isFetching}>
          <div
            style={{ height: 240 }}
            role="img"
            aria-label={`Area chart showing daily adherence trends over the last ${days} days`}
          >
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart
                data={trends}
                margin={{ top: 8, right: 8, bottom: 0, left: 0 }}
              >
                <CartesianGrid
                  strokeDasharray="3 3"
                  stroke="hsl(var(--border))"
                  vertical={false}
                />
                <XAxis
                  dataKey="date"
                  tick={{ fill: "hsl(var(--muted-foreground))", fontSize: 12 }}
                  tickLine={false}
                  axisLine={false}
                  tickFormatter={(value: string) => formatDateLabel(value, days)}
                  interval="preserveStartEnd"
                />
                <YAxis
                  tick={{ fill: "hsl(var(--muted-foreground))", fontSize: 12 }}
                  tickLine={false}
                  axisLine={false}
                  width={45}
                  domain={[0, 100]}
                  tickFormatter={(value: number) => `${value}%`}
                />
                <Tooltip content={<CustomTooltip />} />
                <Legend
                  iconType="circle"
                  iconSize={8}
                  wrapperStyle={{ fontSize: 12, paddingTop: 8 }}
                />
                {METRICS.map((metric) => (
                  <Area
                    key={metric.key}
                    type="monotone"
                    dataKey={metric.key}
                    name={metric.name}
                    stroke={metric.color}
                    fill={metric.color}
                    fillOpacity={0.1}
                    strokeWidth={2}
                    dot={false}
                    activeDot={{ r: 4, strokeWidth: 0 }}
                  />
                ))}
              </AreaChart>
            </ResponsiveContainer>
          </div>
          {/* Screen-reader accessible data */}
          <ul className="sr-only" aria-label="Daily adherence trend data">
            {trends.map((point) => (
              <li key={point.date}>
                {formatFullDate(point.date)}: Food {formatRate(point.food_logged_rate)},
                Workout {formatRate(point.workout_logged_rate)},
                Protein {formatRate(point.protein_goal_rate)},
                Calorie {formatRate(point.calorie_goal_rate)}
                ({point.trainee_count} trainees)
              </li>
            ))}
          </ul>
        </div>
      </CardContent>
    </Card>
  );
}
