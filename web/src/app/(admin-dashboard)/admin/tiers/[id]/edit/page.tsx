"use client";

import { use } from "react";
import { Loader2 } from "lucide-react";
import { useAdminTiers } from "@/hooks/use-admin-tiers";
import { ErrorState } from "@/components/shared/error-state";
import { TierWizardForm } from "@/components/admin/tier-wizard-form";

interface EditTierPageProps {
  params: Promise<{ id: string }>;
}

export default function EditTierPage({ params }: EditTierPageProps) {
  const { id } = use(params);
  const tierId = parseInt(id, 10);
  const tiers = useAdminTiers();
  const tier = tiers.data?.find((t) => t.id === tierId) ?? null;

  if (tiers.isLoading) {
    return (
      <div className="flex items-center justify-center py-20" role="status">
        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" aria-hidden="true" />
        <span className="sr-only">Loading tier...</span>
      </div>
    );
  }

  if (tiers.isError || !tier) {
    return (
      <ErrorState
        message="Failed to load tier"
        onRetry={() => tiers.refetch()}
      />
    );
  }

  return (
    <div className="py-6">
      <TierWizardForm tier={tier} />
    </div>
  );
}
