import type React from "react";

/** Shared tooltip styling that follows the design system theme.
 *  Used by all recharts Tooltip components across the app. */
export const tooltipContentStyle: React.CSSProperties = {
  backgroundColor: "hsl(var(--card))",
  border: "1px solid hsl(var(--border))",
  borderRadius: "var(--radius)",
  color: "hsl(var(--card-foreground))",
};

/** Theme-aware chart colors mapped to --chart-N CSS custom properties */
export const CHART_COLORS = {
  food: "hsl(var(--chart-2))",
  workout: "hsl(var(--chart-1))",
  protein: "hsl(var(--chart-4))",
} as const;
