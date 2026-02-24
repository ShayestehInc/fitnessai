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

  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between text-sm">
        <span className="font-medium">{label}</span>
        <span className="text-muted-foreground">
          {Math.round(consumed)} / {Math.round(goal)}
          {unit}
        </span>
      </div>
      <Progress
        value={percentage}
        className="h-2"
        aria-label={`${label}: ${Math.round(consumed)} of ${Math.round(goal)}${unit}`}
        style={
          { "--progress-color": color } as React.CSSProperties
        }
      />
    </div>
  );
}
