"use client";

import { DayEditor } from "./day-editor";
import type { ScheduleWeek, ScheduleDay } from "@/types/program";

interface WeekEditorProps {
  week: ScheduleWeek;
  onUpdate: (updated: ScheduleWeek) => void;
}

export function WeekEditor({ week, onUpdate }: WeekEditorProps) {
  const updateDay = (dayIndex: number, updatedDay: ScheduleDay) => {
    const days = [...week.days];
    days[dayIndex] = updatedDay;
    onUpdate({ ...week, days });
  };

  return (
    <div className="space-y-3">
      {week.days.map((day, idx) => (
        <DayEditor
          key={day.day}
          day={day}
          dayIndex={idx}
          onUpdate={(updated) => updateDay(idx, updated)}
        />
      ))}
    </div>
  );
}
