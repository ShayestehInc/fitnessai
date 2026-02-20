"use client";

import { User, Mail, Target } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/shared/error-state";
import { useTraineeProfile } from "@/hooks/use-trainee-view";

export function ProfileCard() {
  const { data: profile, isLoading, isError, refetch } = useTraineeProfile();

  if (isLoading) {
    return <ProfileCardSkeleton />;
  }

  if (isError || !profile) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <User className="h-4 w-4" aria-hidden="true" />
            Profile Summary
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ErrorState
            message="Failed to load profile"
            onRetry={() => refetch()}
          />
        </CardContent>
      </Card>
    );
  }

  const displayName =
    `${profile.first_name} ${profile.last_name}`.trim() || "No name set";

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-base">
          <User className="h-4 w-4" aria-hidden="true" />
          Profile Summary
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-muted">
            <User className="h-5 w-5 text-muted-foreground" aria-hidden="true" />
          </div>
          <div className="min-w-0">
            <p className="truncate font-medium">{displayName}</p>
            <p className="flex items-center gap-1 truncate text-sm text-muted-foreground">
              <Mail className="h-3 w-3 shrink-0" aria-hidden="true" />
              {profile.email}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-1.5 text-sm text-muted-foreground">
          <Target className="h-3.5 w-3.5 shrink-0" aria-hidden="true" />
          <span>
            {profile.onboarding_completed
              ? "Onboarding complete"
              : "Onboarding not completed"}
          </span>
        </div>
      </CardContent>
    </Card>
  );
}

function ProfileCardSkeleton() {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-base">
          <User className="h-4 w-4" aria-hidden="true" />
          Profile Summary
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="flex items-center gap-3">
          <Skeleton className="h-10 w-10 rounded-full" />
          <div className="space-y-2">
            <Skeleton className="h-4 w-32" />
            <Skeleton className="h-3 w-48" />
          </div>
        </div>
        <Skeleton className="h-3 w-40" />
      </CardContent>
    </Card>
  );
}
