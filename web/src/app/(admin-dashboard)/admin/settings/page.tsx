"use client";

import { useAuth } from "@/hooks/use-auth";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ErrorState } from "@/components/shared/error-state";
import { ProfileSection } from "@/components/settings/profile-section";
import { AppearanceSection } from "@/components/settings/appearance-section";
import { SecuritySection } from "@/components/settings/security-section";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";

function AdminSettingsSkeleton() {
  return (
    <div className="space-y-6">
      {[1, 2, 3, 4].map((i) => (
        <div key={i} className="rounded-lg border p-6">
          <Skeleton className="mb-2 h-5 w-32" />
          <Skeleton className="mb-6 h-4 w-48" />
          <div className="space-y-4">
            <Skeleton className="h-10 w-full" />
            <Skeleton className="h-10 w-full" />
          </div>
        </div>
      ))}
    </div>
  );
}

export default function AdminSettingsPage() {
  const { user, isLoading, refreshUser } = useAuth();

  if (isLoading) {
    return (
      <div className="max-w-2xl space-y-6">
        <PageHeader title="Admin Settings" description="Platform configuration and account" />
        <AdminSettingsSkeleton />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="max-w-2xl space-y-6">
        <PageHeader title="Admin Settings" description="Platform configuration and account" />
        <ErrorState
          message="Failed to load settings"
          onRetry={() => refreshUser()}
        />
      </div>
    );
  }

  return (
    <PageTransition>
      <div className="max-w-2xl space-y-6">
        <PageHeader title="Admin Settings" description="Platform configuration and account" />

        {/* Platform Config */}
        <Card>
          <CardHeader>
            <CardTitle>Platform Configuration</CardTitle>
            <CardDescription>
              Global settings that affect all trainers and trainees
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Platform Name</Label>
              <Input defaultValue="FitnessAI" disabled placeholder="FitnessAI" />
              <p className="text-xs text-muted-foreground">
                Contact support to change the platform name
              </p>
            </div>
            <div className="space-y-2">
              <Label>Support Email</Label>
              <Input defaultValue="support@fitnessai.com" disabled />
            </div>
          </CardContent>
        </Card>

        {/* Security Notice */}
        <Card>
          <CardHeader>
            <CardTitle>Security</CardTitle>
            <CardDescription>
              Admin security and audit settings
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="rounded-md bg-muted p-4">
              <p className="text-sm">
                All admin actions are logged for audit purposes. Impersonation
                sessions are tracked with start/end timestamps and are visible
                in the audit log.
              </p>
            </div>
          </CardContent>
        </Card>

        <ProfileSection />
        <AppearanceSection />
        <SecuritySection />
      </div>
    </PageTransition>
  );
}
