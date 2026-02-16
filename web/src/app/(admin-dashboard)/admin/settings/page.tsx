"use client";

import { Settings } from "lucide-react";
import { PageHeader } from "@/components/shared/page-header";
import { EmptyState } from "@/components/shared/empty-state";

export default function AdminSettingsPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        title="Settings"
        description="Platform configuration"
      />
      <EmptyState
        icon={Settings}
        title="Coming soon"
        description="Admin settings will be available in a future update."
      />
    </div>
  );
}
