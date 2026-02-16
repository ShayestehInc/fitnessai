"use client";

import { useRouter } from "next/navigation";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from "recharts";
import type { TraineeAdherence } from "@/types/analytics";

function getAdherenceColor(rate: number): string {
  if (rate >= 80) return "hsl(var(--chart-2))"; // green
  if (rate >= 50) return "hsl(32 95% 44%)"; // amber
  return "hsl(var(--destructive))"; // red
}

/** Shared tooltip styling that follows the design system theme */
const tooltipContentStyle: React.CSSProperties = {
  backgroundColor: "hsl(var(--card))",
  border: "1px solid hsl(var(--border))",
  borderRadius: "var(--radius)",
  color: "hsl(var(--card-foreground))",
};

interface AdherenceBarChartProps {
  data: TraineeAdherence[];
}

export function AdherenceBarChart({ data }: AdherenceBarChartProps) {
  const router = useRouter();

  const sorted = [...data].sort((a, b) => b.adherence_rate - a.adherence_rate);
  const barHeight = 36;
  const chartHeight = Math.max(sorted.length * barHeight + 40, 120);

  return (
    <div style={{ height: chartHeight }}>
      <ResponsiveContainer width="100%" height="100%">
        <BarChart
          data={sorted}
          layout="vertical"
          margin={{ top: 0, right: 20, bottom: 0, left: 0 }}
        >
          <XAxis
            type="number"
            domain={[0, 100]}
            tick={{ fill: "hsl(var(--muted-foreground))", fontSize: 12 }}
            tickFormatter={(v: number) => `${v}%`}
          />
          <YAxis
            type="category"
            dataKey="trainee_name"
            width={120}
            tick={({ x, y, payload }: { x: string | number; y: string | number; payload: { value: string } }) => {
              const name = payload.value;
              const display =
                name.length > 15 ? `${name.slice(0, 15)}...` : name;
              return (
                <text
                  x={x}
                  y={y}
                  textAnchor="end"
                  fill="hsl(var(--muted-foreground))"
                  fontSize={12}
                  dominantBaseline="central"
                >
                  <title>{name}</title>
                  {display}
                </text>
              );
            }}
          />
          <Tooltip
            contentStyle={tooltipContentStyle}
            formatter={(value: number | undefined) => [
              value !== undefined ? `${value.toFixed(1)}%` : "—",
              "Adherence",
            ]}
          />
          <Bar
            dataKey="adherence_rate"
            name="Adherence"
            radius={[0, 4, 4, 0]}
            cursor="pointer"
            onClick={(_entry, index) => {
              const trainee = sorted[index];
              if (trainee) {
                router.push(`/trainees/${trainee.trainee_id}`);
              }
            }}
          >
            {sorted.map((entry) => (
              <Cell
                key={entry.trainee_id}
                fill={getAdherenceColor(entry.adherence_rate)}
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
