"use client";

import { useMemo } from "react";
import Link from "next/link";
import { MoreHorizontal, Pencil, Trash2, UserPlus } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { DataTable, type Column } from "@/components/shared/data-table";
import { DeleteProgramDialog } from "./delete-program-dialog";
import { AssignProgramDialog } from "./assign-program-dialog";
import { useAuth } from "@/hooks/use-auth";
import {
  DIFFICULTY_LABELS,
  GOAL_LABELS,
  type ProgramTemplate,
  type DifficultyLevel,
  type GoalType,
} from "@/types/program";

function getDifficultyVariant(
  level: DifficultyLevel | null,
): "default" | "secondary" | "destructive" | "outline" {
  if (!level) return "outline";
  switch (level) {
    case "beginner":
      return "secondary";
    case "intermediate":
      return "default";
    case "advanced":
      return "destructive";
    default:
      return "outline";
  }
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

function makeColumns(currentUserId: number | null): Column<ProgramTemplate>[] {
  return [
    {
      key: "name",
      header: "Name",
      cell: (row) => {
        const canEdit = currentUserId !== null && row.created_by === currentUserId;
        return canEdit ? (
          <Link
            href={`/programs/${row.id}/edit`}
            className="block max-w-[300px] truncate font-medium text-foreground underline-offset-4 hover:underline"
            title={row.name}
          >
            {row.name}
          </Link>
        ) : (
          <span
            className="block max-w-[300px] truncate font-medium"
            title={row.name}
          >
            {row.name}
          </span>
        );
      },
    },
    {
      key: "difficulty_level",
      header: "Difficulty",
      cell: (row) =>
        row.difficulty_level ? (
          <Badge variant={getDifficultyVariant(row.difficulty_level)}>
            {DIFFICULTY_LABELS[row.difficulty_level] ?? row.difficulty_level}
          </Badge>
        ) : (
          <span className="text-muted-foreground" aria-label="Not set">
            —
          </span>
        ),
    },
    {
      key: "goal_type",
      header: "Goal",
      cell: (row) =>
        row.goal_type ? (
          <span>
            {GOAL_LABELS[row.goal_type as GoalType] ?? row.goal_type}
          </span>
        ) : (
          <span className="text-muted-foreground" aria-label="Not set">
            —
          </span>
        ),
    },
    {
      key: "duration_weeks",
      header: "Duration",
      cell: (row) => (
        <span>
          {row.duration_weeks} week{row.duration_weeks !== 1 ? "s" : ""}
        </span>
      ),
    },
    {
      key: "times_used",
      header: "Used",
      cell: (row) => (
        <span>
          {row.times_used} time{row.times_used !== 1 ? "s" : ""}
        </span>
      ),
    },
    {
      key: "created_at",
      header: "Created",
      cell: (row) => (
        <span className="text-muted-foreground">
          {formatDate(row.created_at)}
        </span>
      ),
    },
    {
      key: "actions",
      header: "",
      cell: (row) => (
        <ProgramActions
          program={row}
          isOwner={currentUserId !== null && row.created_by === currentUserId}
        />
      ),
      className: "w-12",
    },
  ];
}

function ProgramActions({
  program,
  isOwner,
}: {
  program: ProgramTemplate;
  isOwner: boolean;
}) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="h-8 w-8"
          aria-label={`Actions for ${program.name}`}
        >
          <MoreHorizontal className="h-4 w-4" aria-hidden="true" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        {isOwner && (
          <DropdownMenuItem asChild>
            <Link href={`/programs/${program.id}/edit`} className="gap-2">
              <Pencil className="h-4 w-4" aria-hidden="true" />
              Edit
            </Link>
          </DropdownMenuItem>
        )}

        <AssignProgramDialog
          program={program}
          trigger={
            <DropdownMenuItem
              onSelect={(e) => e.preventDefault()}
              className="gap-2"
            >
              <UserPlus className="h-4 w-4" aria-hidden="true" />
              Assign to Trainee
            </DropdownMenuItem>
          }
        />

        {isOwner && (
          <DeleteProgramDialog
            program={program}
            trigger={
              <DropdownMenuItem
                onSelect={(e) => e.preventDefault()}
                className="gap-2 text-destructive focus:text-destructive"
              >
                <Trash2 className="h-4 w-4" aria-hidden="true" />
                Delete
              </DropdownMenuItem>
            }
          />
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

interface ProgramListProps {
  programs: ProgramTemplate[];
  totalCount?: number;
  page?: number;
  onPageChange?: (page: number) => void;
}

export function ProgramList({
  programs,
  totalCount,
  page,
  onPageChange,
}: ProgramListProps) {
  const { user } = useAuth();
  const currentUserId = user?.id ?? null;
  const columns = useMemo(() => makeColumns(currentUserId), [currentUserId]);

  return (
    <DataTable
      columns={columns}
      data={programs}
      totalCount={totalCount}
      page={page}
      onPageChange={onPageChange}
      keyExtractor={(row) => row.id}
    />
  );
}
