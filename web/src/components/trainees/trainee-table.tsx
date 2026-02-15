"use client";

import { DataTable } from "@/components/shared/data-table";
import { traineeColumns } from "./trainee-columns";
import type { TraineeListItem } from "@/types/trainer";

interface TraineeTableProps {
  trainees: TraineeListItem[];
  totalCount: number;
  page: number;
  onPageChange: (page: number) => void;
}

export function TraineeTable({
  trainees,
  totalCount,
  page,
  onPageChange,
}: TraineeTableProps) {
  return (
    <DataTable
      columns={traineeColumns}
      data={trainees}
      totalCount={totalCount}
      page={page}
      onPageChange={onPageChange}
      keyExtractor={(row) => row.id}
    />
  );
}
