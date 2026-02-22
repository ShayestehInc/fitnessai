import type {
  TraineeViewSchedule,
  TraineeViewScheduleDay,
} from "@/types/trainee-view";

export function getTodaysDayNumber(): number {
  // JavaScript: Sunday = 0, Monday = 1 ... Saturday = 6
  // Schedule: day_number 1 = Monday ... 7 = Sunday
  const jsDay = new Date().getDay();
  return jsDay === 0 ? 7 : jsDay;
}

export const DAY_NAMES: Record<number, string> = {
  1: "Monday",
  2: "Tuesday",
  3: "Wednesday",
  4: "Thursday",
  5: "Friday",
  6: "Saturday",
  7: "Sunday",
};

export function findTodaysWorkout(
  schedule: TraineeViewSchedule | null,
): TraineeViewScheduleDay | null {
  if (!schedule?.weeks?.length) return null;
  // Use the first week as the current template
  const week = schedule.weeks[0];
  if (!week?.days?.length) return null;
  const todayNum = getTodaysDayNumber();
  const todayName = DAY_NAMES[todayNum] ?? "";
  // Match by day string (could be "1" or "Monday")
  return (
    week.days.find(
      (d) => d.day === String(todayNum) || d.day === todayName,
    ) ?? null
  );
}

export function getTodayString(): string {
  const d = new Date();
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function formatDuration(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
}
