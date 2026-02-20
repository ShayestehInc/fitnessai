"use client";

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/shared/empty-state";
import { TrendingUp } from "lucide-react";
import { tooltipContentStyle } from "@/lib/chart-utils";

interface EarningsChartProps {
  data: { month: string; amount: string }[];
}

function formatMonthLabel(monthStr: string): string {
  const [year, month] = monthStr.split("-");
  const date = new Date(parseInt(year, 10), parseInt(month, 10) - 1);
  return date.toLocaleDateString(undefined, { month: "short" });
}

function formatFullMonth(monthStr: string): string {
  const [year, month] = monthStr.split("-");
  const date = new Date(parseInt(year, 10), parseInt(month, 10) - 1);
  return date.toLocaleDateString(undefined, {
    month: "long",
    year: "numeric",
  });
}

function formatDollarAmount(value: number): string {
  if (value >= 10_000) return `$${(value / 1000).toFixed(1)}K`;
  if (value >= 1_000) return `$${(value / 1000).toFixed(1)}K`;
  return `$${value.toFixed(0)}`;
}

function formatExactAmount(value: number): string {
  return `$${value.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })}`;
}

export function EarningsChart({ data }: EarningsChartProps) {
  const hasAnyEarnings = data.some((d) => parseFloat(d.amount) > 0);

  if (!data.length || !hasAnyEarnings) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Monthly Earnings</CardTitle>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={TrendingUp}
            title="No earnings data yet"
            description="Your monthly commission earnings will appear here once you start earning."
          />
        </CardContent>
      </Card>
    );
  }

  // Determine current month key for highlighting
  const now = new Date();
  const currentMonthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;

  const chartData = data.map((d) => ({
    month: d.month,
    label: formatMonthLabel(d.month),
    amount: parseFloat(d.amount),
    isCurrent: d.month === currentMonthKey,
  }));

  return (
    <Card>
      <CardHeader>
        <CardTitle>Monthly Earnings</CardTitle>
      </CardHeader>
      <CardContent>
        <div
          style={{ height: 240 }}
          role="img"
          aria-label={`Bar chart showing monthly earnings for the last ${chartData.length} months`}
        >
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              data={chartData}
              margin={{ top: 8, right: 8, bottom: 0, left: 0 }}
            >
              <XAxis
                dataKey="label"
                tick={{
                  fill: "hsl(var(--muted-foreground))",
                  fontSize: 12,
                }}
                tickLine={false}
                axisLine={false}
              />
              <YAxis
                tick={{
                  fill: "hsl(var(--muted-foreground))",
                  fontSize: 12,
                }}
                tickFormatter={formatDollarAmount}
                tickLine={false}
                axisLine={false}
                width={60}
              />
              <Tooltip
                contentStyle={tooltipContentStyle}
                formatter={(value: number | string | undefined) => [
                  formatExactAmount(
                    typeof value === "number"
                      ? value
                      : parseFloat(String(value ?? "0")),
                  ),
                  "Earnings",
                ]}
                labelFormatter={(_label, payload) => {
                  if (payload?.[0]?.payload?.month) {
                    return formatFullMonth(
                      payload[0].payload.month as string,
                    );
                  }
                  return String(_label ?? "");
                }}
              />
              <Bar dataKey="amount" name="Earnings" radius={[4, 4, 0, 0]}>
                {chartData.map((entry) => (
                  <Cell
                    key={entry.month}
                    fill={
                      entry.isCurrent
                        ? "hsl(var(--chart-1))"
                        : "hsl(var(--chart-2))"
                    }
                  />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
        {/* Screen-reader accessible data */}
        <ul className="sr-only" aria-label="Monthly earnings data">
          {chartData.map((entry) => (
            <li key={entry.month}>
              {formatFullMonth(entry.month)}: {formatExactAmount(entry.amount)}
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}
