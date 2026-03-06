"use client";

import { useAuth } from "@/hooks/use-auth";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ErrorState } from "@/components/shared/error-state";
import { ProfileSection } from "@/components/settings/profile-section";
import { AppearanceSection } from "@/components/settings/appearance-section";
import { LanguageSelector } from "@/components/settings/language-selector";
import { SecuritySection } from "@/components/settings/security-section";
import { Skeleton } from "@/components/ui/skeleton";
import { useLocale } from "@/providers/locale-provider";

function SettingsSkeleton() {
  return (
    <div className="space-y-6">
      {[1, 2, 3].map((i) => (
        <div key={i} className="rounded-lg border p-6">
          <Skeleton className="mb-2 h-5 w-24" />
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

export default function AmbassadorSettingsPage() {
  const { t } = useLocale();
  const { user, isLoading, refreshUser } = useAuth();

  if (isLoading) {
    return (
      <div className="max-w-2xl space-y-6">
        <PageHeader title={t("nav.settings")} description={t("settings.manageAccount")} />
        <SettingsSkeleton />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="max-w-2xl space-y-6">
        <PageHeader title={t("nav.settings")} description={t("settings.manageAccount")} />
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
        <PageHeader title={t("nav.settings")} description={t("settings.manageAccount")} />
        <ProfileSection />
        <AppearanceSection />
        <LanguageSelector />
        <SecuritySection />
      </div>
    </PageTransition>
  );
}
