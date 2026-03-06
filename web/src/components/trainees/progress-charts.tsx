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
import { tooltipContentStyle, CHART_COLORS } from "@/lib/chart-utils";
import type { WeightEntry, VolumeEntry, AdherenceEntry } from "@/types/progress";
import { useLocale } from "@/providers/locale-provider";

function formatDate(dateStr: string): string {
  const d = parseISO(dateStr);
  return isValid(d) ? format(d, "MMM d") : dateStr;
}

function formatNumber(value: number): string {
  return new Intl.NumberFormat("en-US").format(value);
}

interface WeightChartProps {
  data: WeightEntry[];
}

export function WeightChart({ data }: WeightChartProps) {
  const { t } = useLocale();
  if (data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t("trainees.weightTrend")}</CardTitle>
          <CardDescription>{t("trainees.weightTrendDesc")}</CardDescription>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={Scale}
            title={t("trainees.noWeightData")}
            description={t("trainees.weightCheckInsAppear")}
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
        <CardTitle className="text-base">{t("trainees.weightTrend")}</CardTitle>
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
                tick={{ fill: "hsl(var(--muted-foreground))", fontSize: 11 }}
                interval="preserveStartEnd"
              />
              <YAxis
                className="text-xs"
                tick={{ fill: "hsl(var(--muted-foreground))" }}
                domain={["dataMin - 2", "dataMax + 2"]}
                unit=" kg"
                width={50}
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
  const { t } = useLocale();
  if (data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t("trainees.workoutVolume")}</CardTitle>
          <CardDescription>{t("trainees.workoutVolumeDesc")}</CardDescription>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={Dumbbell}
            title={t("trainees.noWorkoutData")}
            description={t("trainees.workoutVolumeAppear")}
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
        <CardTitle className="text-base">{t("trainees.workoutVolume")}</CardTitle>
        <CardDescription>{t("trainees.workoutVolumeDaily")}</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="h-[250px]">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
              <XAxis
                dataKey="date"
                className="text-xs"
                tick={{ fill: "hsl(var(--muted-foreground))", fontSize: 11 }}
                interval="preserveStartEnd"
              />
              <YAxis
                className="text-xs"
                tick={{ fill: "hsl(var(--muted-foreground))" }}
                width={50}
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
  const { t } = useLocale();
  if (data.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t("trainees.adherence")}</CardTitle>
          <CardDescription>{t("trainees.adherenceDesc")}</CardDescription>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={CalendarCheck}
            title={t("trainees.noActivityData")}
            description={t("trainees.adherenceAppear")}
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
        <CardTitle className="text-base">{t("trainees.adherence")}</CardTitle>
        <CardDescription>{t("trainees.adherenceDaily")}</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="h-[250px]">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
              <XAxis
                dataKey="date"
                className="text-xs"
                tick={{ fill: "hsl(var(--muted-foreground))", fontSize: 11 }}
                interval="preserveStartEnd"
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
