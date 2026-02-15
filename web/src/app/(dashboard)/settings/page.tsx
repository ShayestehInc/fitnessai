"use client";

import { Settings } from "lucide-react";
import { PageHeader } from "@/components/shared/page-header";
import { EmptyState } from "@/components/shared/empty-state";

export default function SettingsPage() {
  return (
    <div className="space-y-6">
      <PageHeader title="Settings" description="Manage your account" />
      <EmptyState
        icon={Settings}
        title="Coming soon"
        description="Profile settings, theme preferences, and notification settings will be available here."
      />
    </div>
  );
}
