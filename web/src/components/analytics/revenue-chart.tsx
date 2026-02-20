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
import { DollarSign } from "lucide-react";
import { tooltipContentStyle } from "@/lib/chart-utils";
import type { MonthlyRevenuePoint } from "@/types/analytics";

interface RevenueChartProps {
  data: MonthlyRevenuePoint[];
}

function formatMonthLabel(monthStr: string): string {
  const [year, month] = monthStr.split("-");
  const date = new Date(parseInt(year, 10), parseInt(month, 10) - 1);
  // Show abbreviated year on January to clarify year boundaries
  if (month === "01") {
    return date.toLocaleDateString(undefined, {
      month: "short",
      year: "2-digit",
    });
  }
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

function formatDollarAxis(value: number): string {
  if (value >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `$${(value / 1_000).toFixed(1)}K`;
  return `$${value.toFixed(0)}`;
}

function formatExactAmount(value: number): string {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(value);
}

export function RevenueChart({ data }: RevenueChartProps) {
  const hasAnyRevenue = data.some((d) => {
    const parsed = parseFloat(d.amount);
    return !Number.isNaN(parsed) && parsed > 0;
  });

  if (!data.length || !hasAnyRevenue) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Monthly Revenue</CardTitle>
        </CardHeader>
        <CardContent>
          <EmptyState
            icon={DollarSign}
            title="No revenue data yet"
            description="Monthly revenue will appear here once you receive payments."
          />
        </CardContent>
      </Card>
    );
  }

  const now = new Date();
  const currentMonthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;

  const chartData = data.map((d) => {
    const parsed = parseFloat(d.amount);
    return {
      month: d.month,
      label: formatMonthLabel(d.month),
      amount: Number.isNaN(parsed) ? 0 : parsed,
      isCurrent: d.month === currentMonthKey,
    };
  });

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Monthly Revenue</CardTitle>
      </CardHeader>
      <CardContent>
        <div
          style={{ height: 240 }}
          role="img"
          aria-label={`Bar chart showing monthly revenue for the last ${chartData.length} months`}
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
                interval="preserveStartEnd"
              />
              <YAxis
                tick={{
                  fill: "hsl(var(--muted-foreground))",
                  fontSize: 12,
                }}
                tickFormatter={formatDollarAxis}
                tickLine={false}
                axisLine={false}
                width={65}
              />
              <Tooltip
                contentStyle={tooltipContentStyle}
                formatter={(value: number | string | undefined) => [
                  formatExactAmount(
                    typeof value === "number"
                      ? value
                      : parseFloat(String(value ?? "0")),
                  ),
                  "Revenue",
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
              <Bar dataKey="amount" name="Revenue" radius={[4, 4, 0, 0]}>
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
        <ul className="sr-only" aria-label="Monthly revenue data">
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
