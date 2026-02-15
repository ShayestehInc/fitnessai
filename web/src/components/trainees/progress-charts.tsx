"use client";

import { format, parseISO, isValid } from "date-fns";
import { Scale, Dumbbell, CalendarCheck } from "lucide-react";
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
  Legend,
} from "recharts";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { EmptyState } from "@/components/shared/empty-state";
import type { WeightEntry, VolumeEntry, AdherenceEntry } from "@/types/progress";

function formatDate(dateStr: string): string {
  const d = parseISO(dateStr);
  return isValid(d) ? format(d, "MMM d") : dateStr;
}

function formatNumber(value: number): string {
  return new Intl.NumberFormat("en-US").format(value);
}

/** Shared tooltip styling that follows the design system theme */
const tooltipContentStyle: React.CSSProperties = {
  backgroundColor: "hsl(var(--card))",
  border: "1px solid hsl(var(--border))",
  borderRadius: "var(--radius)",
  color: "hsl(var(--card-foreground))",
};

/** Theme-aware chart colors mapped to --chart-N CSS custom properties */
const CHART_COLORS = {
  food: "hsl(var(--chart-2))",
  workout: "hsl(var(--chart-1))",
  protein: "hsl(var(--chart-4))",
} as const;

interface WeightChartProps {
  data: WeightEntry[];
}

export function WeightChart({ data }: WeightChartProps) {
  if (data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Weight Trend</CardTitle>
          <CardDescription>Body weight over time</CardDescription>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={Scale}
            title="No weight data"
            description="Weight check-ins will appear here once the trainee logs them."
          />
        </CardContent>
      </Card>
    );
  }

  const chartData = data.map((entry) => ({
    date: formatDate(entry.date),
    weight: entry.weight_kg,
  }));

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Weight Trend</CardTitle>
        <CardDescription>
          Last {data.length} check-in{data.length !== 1 ? "s" : ""}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="h-[250px]">
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
                stroke="hsl(var(--primary))"
                strokeWidth={2}
                dot={{ r: 3, fill: "hsl(var(--primary))" }}
                name="Weight (kg)"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}

interface VolumeChartProps {
  data: VolumeEntry[];
}

export function VolumeChart({ data }: VolumeChartProps) {
  if (data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Workout Volume</CardTitle>
          <CardDescription>Total training volume over time</CardDescription>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={Dumbbell}
            title="No workout data"
            description="Workout volume will appear here once the trainee logs workouts."
          />
        </CardContent>
      </Card>
    );
  }

  const chartData = data.map((entry) => ({
    date: formatDate(entry.date),
    volume: Math.round(entry.volume),
  }));

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Workout Volume</CardTitle>
        <CardDescription>Daily total volume (last 4 weeks)</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="h-[250px]">
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
                  value !== undefined ? formatNumber(value) : "—",
                  "Volume",
                ]}
              />
              <Bar
                dataKey="volume"
                fill="hsl(var(--primary))"
                radius={[4, 4, 0, 0]}
                name="Volume"
              />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}

interface AdherenceChartProps {
  data: AdherenceEntry[];
}

export function AdherenceChart({ data }: AdherenceChartProps) {
  if (data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Adherence</CardTitle>
          <CardDescription>Daily tracking compliance</CardDescription>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={CalendarCheck}
            title="No activity data"
            description="Adherence data will appear here once the trainee starts tracking."
          />
        </CardContent>
      </Card>
    );
  }

  const chartData = data.map((entry) => ({
    date: formatDate(entry.date),
    food: entry.logged_food ? 1 : 0,
    workout: entry.logged_workout ? 1 : 0,
    protein: entry.hit_protein ? 1 : 0,
  }));

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Adherence</CardTitle>
        <CardDescription>Daily tracking (last 4 weeks)</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="h-[250px]">
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
                domain={[0, 3]}
                ticks={[0, 1, 2, 3]}
                tick={false}
                axisLine={false}
                width={8}
              />
              <Tooltip
                contentStyle={tooltipContentStyle}
                formatter={(
                  value: number | undefined,
                  name: string | undefined,
                ) => [value === 1 ? "Yes" : "No", name ?? ""]}
              />
              <Legend />
              <Bar
                dataKey="food"
                stackId="adherence"
                fill={CHART_COLORS.food}
                name="Food Logged"
              />
              <Bar
                dataKey="workout"
                stackId="adherence"
                fill={CHART_COLORS.workout}
                name="Workout Logged"
              />
              <Bar
                dataKey="protein"
                stackId="adherence"
                fill={CHART_COLORS.protein}
                name="Protein Goal"
                radius={[2, 2, 0, 0]}
              />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}
