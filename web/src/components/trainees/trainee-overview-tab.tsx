"use client";

import { format } from "date-fns";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { MacroPresetsSection } from "./macro-presets-section";
import type { TraineeDetail } from "@/types/trainer";

interface TraineeOverviewTabProps {
  trainee: TraineeDetail;
}

export function TraineeOverviewTab({ trainee }: TraineeOverviewTabProps) {
  const { profile, nutrition_goal, programs } = trainee;
  const displayName =
    `${trainee.first_name} ${trainee.last_name}`.trim() || trainee.email;

  return (
    <div className="space-y-6">
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Profile Info */}
        <Card>
          <CardHeader>
            <CardTitle>Profile</CardTitle>
            <CardDescription>Personal information and goals</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <InfoRow label="Email" value={trainee.email} />
            <InfoRow label="Phone" value={trainee.phone_number ?? "Not set"} />
            {profile ? (
              <>
                <Separator />
                <InfoRow label="Sex" value={profile.sex ?? "Not set"} />
                <InfoRow
                  label="Age"
                  value={profile.age ? `${profile.age} years` : "Not set"}
                />
                <InfoRow
                  label="Height"
                  value={
                    profile.height_cm ? `${profile.height_cm} cm` : "Not set"
                  }
                />
                <InfoRow
                  label="Weight"
                  value={
                    profile.weight_kg ? `${profile.weight_kg} kg` : "Not set"
                  }
                />
                <Separator />
                <InfoRow label="Goal" value={formatLabel(profile.goal)} />
                <InfoRow
                  label="Activity Level"
                  value={formatLabel(profile.activity_level)}
                />
                <InfoRow label="Diet Type" value={formatLabel(profile.diet_type)} />
                <InfoRow
                  label="Meals/Day"
                  value={String(profile.meals_per_day)}
                />
              </>
            ) : (
              <p className="text-sm text-muted-foreground">
                Profile not completed
              </p>
            )}
          </CardContent>
        </Card>

        {/* Nutrition Goals + Programs */}
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Nutrition Goals</CardTitle>
              <CardDescription>
                {nutrition_goal?.is_trainer_adjusted
                  ? "Adjusted by trainer"
                  : "Auto-calculated"}
              </CardDescription>
            </CardHeader>
            <CardContent>
              {nutrition_goal ? (
                <div className="grid grid-cols-2 gap-4">
                  <MacroCard
                    label="Calories"
                    value={nutrition_goal.calories_goal}
                    unit="kcal"
                  />
                  <MacroCard
                    label="Protein"
                    value={nutrition_goal.protein_goal}
                    unit="g"
                  />
                  <MacroCard
                    label="Carbs"
                    value={nutrition_goal.carbs_goal}
                    unit="g"
                  />
                  <MacroCard
                    label="Fat"
                    value={nutrition_goal.fat_goal}
                    unit="g"
                  />
                </div>
              ) : (
                <p className="text-sm text-muted-foreground">
                  Goals not set yet
                </p>
              )}
            </CardContent>
          </Card>

          {/* Programs */}
          <Card>
            <CardHeader>
              <CardTitle>Programs</CardTitle>
            </CardHeader>
            <CardContent>
              {programs.length === 0 ? (
                <p className="text-sm text-muted-foreground">
                  No programs assigned
                </p>
              ) : (
                <div className="space-y-3">
                  {programs.map((p) => (
                    <div
                      key={p.id}
                      className="flex items-center justify-between gap-2 rounded-md border p-3"
                    >
                      <div className="min-w-0">
                        <p className="truncate text-sm font-medium" title={p.name}>{p.name}</p>
                        <p className="text-xs text-muted-foreground">
                          {format(new Date(p.start_date), "MMM d, yyyy")}
                          {p.end_date &&
                            ` — ${format(new Date(p.end_date), "MMM d, yyyy")}`}
                        </p>
                      </div>
                      <Badge variant={p.is_active ? "default" : "secondary"}>
                        {p.is_active ? "Active" : "Ended"}
                      </Badge>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Macro Presets — full-width below the 2-column grid */}
      <MacroPresetsSection traineeId={trainee.id} traineeName={displayName} />
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between gap-2 text-sm">
      <span className="shrink-0 text-muted-foreground">{label}</span>
      <span className="truncate font-medium capitalize" title={value}>{value}</span>
    </div>
  );
}

function MacroCard({
  label,
  value,
  unit,
}: {
  label: string;
  value: number;
  unit: string;
}) {
  return (
    <div className="rounded-md border p-3 text-center">
      <p className="text-xs text-muted-foreground">{label}</p>
      <p className="text-lg font-bold">
        {Math.round(value)}
        <span className="text-xs font-normal text-muted-foreground">
          {" "}
          {unit}
        </span>
      </p>
    </div>
  );
}

function formatLabel(value: string | null | undefined): string {
  if (!value) return "Not set";
  return value.replace(/_/g, " ");
}
