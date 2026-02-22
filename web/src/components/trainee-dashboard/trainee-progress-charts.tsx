"use client";

import { format, parseISO, isValid } from "date-fns";
import { Scale, Dumbbell, CalendarCheck, Plus } from "lucide-react";
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { tooltipContentStyle, CHART_COLORS } from "@/lib/chart-utils";
import {
  useTraineeWeightHistory,
  useTraineeWorkoutHistory,
  useTraineeWeeklyProgress,
} from "@/hooks/use-trainee-dashboard";

function formatDate(dateStr: string): string {
  const d = parseISO(dateStr);
  return isValid(d) ? format(d, "MMM d") : dateStr;
}

function formatNumber(value: number): string {
  return new Intl.NumberFormat("en-US").format(value);
}

function ChartSkeleton() {
  return (
    <Card>
      <CardHeader>
        <Skeleton className="h-5 w-32" />
        <Skeleton className="h-4 w-48" />
      </CardHeader>
      <CardContent>
        <Skeleton className="h-[250px] w-full" />
      </CardContent>
    </Card>
  );
}

interface WeightTrendChartProps {
  onOpenLogWeight: () => void;
}

export function WeightTrendChart({ onOpenLogWeight }: WeightTrendChartProps) {
  const { data: checkIns, isLoading, isError, refetch } =
    useTraineeWeightHistory();

  if (isLoading) return <ChartSkeleton />;

  if (isError) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Weight Trend</CardTitle>
        </CardHeader>
        <CardContent>
          <ErrorState
            message="Failed to load weight data"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  if (!checkIns?.length) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Weight Trend</CardTitle>
          <CardDescription>Track your body weight over time</CardDescription>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={Scale}
            title="No weight data yet"
            description="Log your first weight check-in to see your trend."
            action={
              <Button size="sm" onClick={onOpenLogWeight}>
                <Plus className="mr-1.5 h-4 w-4" />
                Log Weight
              </Button>
            }
          />
        </CardContent>
      </Card>
    );
  }

  // Limit to 30 most recent entries, then reverse for chronological display
  const recentCheckIns = checkIns.slice(0, 30);
  const chartData = [...recentCheckIns].reverse().map((entry) => ({
    date: formatDate(entry.date),
    weight: Number(entry.weight_kg),
  }));

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Weight Trend</CardTitle>
        <CardDescription>
          Last {recentCheckIns.length} check-in{recentCheckIns.length !== 1 ? "s" : ""}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="h-[250px]" role="img" aria-label="Weight trend chart">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
              <XAxis
                dataKey="date"
                className="text-xs"
                tick={{ fill: "hsl(var(--muted-foreground))" }}
              />
              <YAxis
                className="text-xs"
                tick={{ fill: "hsl(var(--muted-foreground))" }}
                domain={["dataMin - 2", "dataMax + 2"]}
                unit=" kg"
              />
              <Tooltip contentStyle={tooltipContentStyle} />
              <Line
                type="monotone"
                dataKey="weight"
                stroke={CHART_COLORS.weight}
                strokeWidth={2}
                dot={{ r: 3, fill: CHART_COLORS.weight }}
                name="Weight (kg)"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
        {/* Screen reader fallback */}
        <ul className="sr-only">
          {chartData.map((d) => (
            <li key={d.date}>
              {d.date}: {d.weight} kg
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}

export function WorkoutVolumeChart() {
  const { data, isLoading, isError, refetch } = useTraineeWorkoutHistory(1);

  if (isLoading) return <ChartSkeleton />;

  if (isError) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Workout Volume</CardTitle>
        </CardHeader>
        <CardContent>
          <ErrorState
            message="Failed to load workout data"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  const results = data?.results ?? [];
  if (results.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Workout Volume</CardTitle>
          <CardDescription>Total training volume per session</CardDescription>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={Dumbbell}
            title="No workout data yet"
            description="Complete your first workout to see volume trends."
          />
        </CardContent>
      </Card>
    );
  }

  // Reverse for chronological order (API returns newest first)
  const chartData = [...results].reverse().map((entry) => ({
    date: formatDate(entry.date),
    volume: Math.round(entry.total_volume_lbs),
  }));

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Workout Volume</CardTitle>
        <CardDescription>
          Total volume per session (last {results.length} workouts)
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="h-[250px]" role="img" aria-label="Workout volume chart">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
              <XAxis
                dataKey="date"
                className="text-xs"
                tick={{ fill: "hsl(var(--muted-foreground))" }}
              />
              <YAxis
                className="text-xs"
                tick={{ fill: "hsl(var(--muted-foreground))" }}
              />
              <Tooltip
                contentStyle={tooltipContentStyle}
                formatter={(value: number | undefined) => [
                  value !== undefined ? formatNumber(value) : "0",
                  "Volume (lbs)",
                ]}
              />
              <Bar
                dataKey="volume"
                fill={CHART_COLORS.workout}
                radius={[4, 4, 0, 0]}
                name="Volume"
              />
            </BarChart>
          </ResponsiveContainer>
        </div>
        <ul className="sr-only">
          {chartData.map((d) => (
            <li key={d.date}>
              {d.date}: {formatNumber(d.volume)} lbs
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}

export function WeeklyAdherenceCard() {
  const { data, isLoading, isError, refetch } = useTraineeWeeklyProgress();

  if (isLoading) return <ChartSkeleton />;

  if (isError) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Weekly Adherence</CardTitle>
        </CardHeader>
        <CardContent>
          <ErrorState
            message="Failed to load progress data"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  if (!data || data.total_days === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Weekly Adherence</CardTitle>
          <CardDescription>
            How consistently you follow your program
          </CardDescription>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={CalendarCheck}
            title="No training schedule"
            description="Your weekly adherence will appear here once you have an assigned program."
          />
        </CardContent>
      </Card>
    );
  }

  const percentage = data.percentage;
  const barColor =
    percentage >= 80
      ? "bg-green-500"
      : percentage >= 50
        ? "bg-amber-500"
        : "bg-red-500";

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Weekly Adherence</CardTitle>
        <CardDescription>This week&apos;s workout completion</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-baseline gap-2">
          <span className="text-3xl font-bold">{percentage}%</span>
          <span className="text-sm text-muted-foreground">
            {data.completed_days} of {data.total_days} days
          </span>
        </div>
        <div
          className="h-3 overflow-hidden rounded-full bg-muted"
          role="progressbar"
          aria-valuenow={percentage}
          aria-valuemin={0}
          aria-valuemax={100}
          aria-label={`Weekly adherence: ${percentage}%, ${data.completed_days} of ${data.total_days} days`}
        >
          <div
            className={`h-full rounded-full transition-all duration-300 ${barColor}`}
            style={{ width: `${Math.min(100, percentage)}%` }}
          />
        </div>
        <p className="text-xs text-muted-foreground">
          {percentage >= 80
            ? "Great work! You're staying on track."
            : percentage >= 50
              ? "Good effort! Try to hit all your scheduled days."
              : "Consistency is key. Every workout counts!"}
        </p>
      </CardContent>
    </Card>
  );
}
