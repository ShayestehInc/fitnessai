"use client";

import { useRouter } from "next/navigation";
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
  const router = useRouter();

  return (
    <DataTable
      columns={traineeColumns}
      data={trainees}
      totalCount={totalCount}
      page={page}
      onPageChange={onPageChange}
      onRowClick={(row) => router.push(`/trainees/${row.id}`)}
      keyExtractor={(row) => row.id}
    />
  );
}
