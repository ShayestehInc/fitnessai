import { cn } from "@/lib/utils";
import { Progress } from "@/components/ui/progress";

export interface MacroBarProps {
  label: string;
  consumed: number;
  goal: number;
  color: string;
  unit?: string;
}

export function MacroBar({ label, consumed, goal, color, unit = " g" }: MacroBarProps) {
  const percentage = goal > 0 ? Math.min((consumed / goal) * 100, 100) : 0;
  const isOverGoal = goal > 0 && consumed > goal;
  const roundedConsumed = Math.round(consumed);
  const roundedGoal = Math.round(goal);

  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between text-sm">
        <span className="font-medium">{label}</span>
        <span
          className={cn(
            "tabular-nums",
            isOverGoal
              ? "font-medium text-amber-600 dark:text-amber-400"
              : "text-muted-foreground",
          )}
        >
          {roundedConsumed} / {roundedGoal}
          {unit}
          {isOverGoal && (
            <span className="ml-1 text-xs">
              (+{Math.round(consumed - goal)})
            </span>
          )}
        </span>
      </div>
      <Progress
        value={percentage}
        className={cn("h-2", isOverGoal && "[--progress-color:hsl(var(--chart-5,38_92%_50%))]")}
        aria-label={`${label}: ${roundedConsumed} of ${roundedGoal}${unit}`}
        aria-valuetext={`${label}: ${roundedConsumed} of ${roundedGoal}${unit}${isOverGoal ? `, exceeded by ${Math.round(consumed - goal)}` : ""}`}
        style={
          isOverGoal ? undefined : ({ "--progress-color": color } as React.CSSProperties)
        }
      />
    </div>
  );
}
