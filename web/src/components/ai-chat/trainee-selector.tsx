"use client";

import { useAllTrainees } from "@/hooks/use-trainees";

interface TraineeSelectorProps {
  value: number | undefined;
  onChange: (traineeId: number | undefined) => void;
}

export function TraineeSelector({ value, onChange }: TraineeSelectorProps) {
  const { data: trainees, isLoading } = useAllTrainees();

  return (
    <select
      value={value ?? ""}
      onChange={(e) => {
        const val = e.target.value;
        onChange(val ? Number(val) : undefined);
      }}
      className="h-9 rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-xs focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]"
      aria-label="Select trainee for context"
      disabled={isLoading}
    >
      <option value="">All trainees</option>
      {trainees?.map((t) => (
        <option key={t.id} value={t.id}>
          {`${t.first_name} ${t.last_name}`.trim() || t.email}
        </option>
      ))}
    </select>
  );
}
