"use client";

import { useState, useDeferredValue } from "react";
import { Search, Dumbbell } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { ScrollArea } from "@/components/ui/scroll-area";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { useExercises } from "@/hooks/use-exercises";
import {
  MuscleGroup,
  MUSCLE_GROUP_LABELS,
  type Exercise,
  type ScheduleExercise,
} from "@/types/program";

interface ExercisePickerDialogProps {
  onSelect: (exercise: ScheduleExercise) => void;
  trigger: React.ReactNode;
}

const MUSCLE_GROUPS = Object.values(MuscleGroup);

export function ExercisePickerDialog({
  onSelect,
  trigger,
}: ExercisePickerDialogProps) {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [selectedGroup, setSelectedGroup] = useState<MuscleGroup | "">("");

  const deferredSearch = useDeferredValue(search);
  const { data, isLoading, isError, refetch } = useExercises(
    deferredSearch,
    selectedGroup,
  );

  const handleSelect = (exercise: Exercise) => {
    const scheduleExercise: ScheduleExercise = {
      exercise_id: exercise.id,
      exercise_name: exercise.name,
      sets: 3,
      reps: 10,
      weight: 0,
      unit: "lbs",
      rest_seconds: 60,
    };
    onSelect(scheduleExercise);
    setOpen(false);
    setSearch("");
    setSelectedGroup("");
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent className="max-h-[80vh] sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Add Exercise</DialogTitle>
        </DialogHeader>

        <div className="space-y-3">
          <div className="relative">
            <Search
              className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground"
              aria-hidden="true"
            />
            <Input
              placeholder="Search exercises..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9"
              maxLength={100}
              aria-label="Search exercises"
            />
          </div>

          <div className="flex flex-wrap gap-1.5">
            <Button
              type="button"
              variant={selectedGroup === "" ? "default" : "outline"}
              size="sm"
              className="h-7 text-xs"
              onClick={() => setSelectedGroup("")}
            >
              All
            </Button>
            {MUSCLE_GROUPS.map((group) => (
              <Button
                key={group}
                type="button"
                variant={selectedGroup === group ? "default" : "outline"}
                size="sm"
                className="h-7 text-xs"
                onClick={() =>
                  setSelectedGroup(selectedGroup === group ? "" : group)
                }
              >
                {MUSCLE_GROUP_LABELS[group]}
              </Button>
            ))}
          </div>

          {isLoading ? (
            <div
              className="space-y-2"
              role="status"
              aria-label="Loading exercises"
            >
              <span className="sr-only">Loading exercises...</span>
              {[0, 1, 2, 3, 4].map((i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : isError ? (
            <ErrorState
              message="Failed to load exercises"
              onRetry={() => refetch()}
            />
          ) : data && data.results.length === 0 ? (
            <EmptyState
              icon={Dumbbell}
              title="No exercises found"
              description={
                search || selectedGroup
                  ? "Try adjusting your search or filter."
                  : "No exercises available yet."
              }
            />
          ) : data ? (
            <ScrollArea className="h-[40vh]">
              <ul className="space-y-1" aria-label="Exercise list">
                {data.results.map((exercise) => (
                  <li key={exercise.id}>
                    <button
                      type="button"
                      onClick={() => handleSelect(exercise)}
                      className="flex w-full items-center justify-between rounded-md px-3 py-2.5 text-left transition-colors hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    >
                      <span className="text-sm font-medium">
                        {exercise.name}
                      </span>
                      <Badge variant="secondary" className="text-xs">
                        {MUSCLE_GROUP_LABELS[exercise.muscle_group]}
                      </Badge>
                    </button>
                  </li>
                ))}
              </ul>
            </ScrollArea>
          ) : null}
        </div>
      </DialogContent>
    </Dialog>
  );
}
