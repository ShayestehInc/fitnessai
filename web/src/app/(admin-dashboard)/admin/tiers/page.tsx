"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Layers, Loader2, Plus } from "lucide-react";
import {
  useAdminTiers,
  useToggleTierActive,
  useDeleteTier,
  useSeedDefaultTiers,
} from "@/hooks/use-admin-tiers";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { TierList } from "@/components/admin/tier-list";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { toast } from "sonner";
import { getErrorMessage } from "@/lib/error-utils";
import type { AdminSubscriptionTier } from "@/types/admin";
import { useLocale } from "@/providers/locale-provider";

export default function AdminTiersPage() {
  const { t } = useLocale();
  const router = useRouter();
  const tiers = useAdminTiers();
  const toggleActive = useToggleTierActive();
  const deleteTier = useDeleteTier();
  const seedDefaults = useSeedDefaultTiers();

  const [deleteTarget, setDeleteTarget] =
    useState<AdminSubscriptionTier | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [togglingId, setTogglingId] = useState<number | null>(null);

  function handleCreate() {
    router.push("/admin/tiers/new");
  }

  function handleEdit(tier: AdminSubscriptionTier) {
    router.push(`/admin/tiers/${tier.id}/edit`);
  }

  async function handleToggleActive(id: number) {
    setTogglingId(id);
    try {
      await toggleActive.mutateAsync(id);
      toast.success(t("admin.tierStatusUpdated"));
    } catch (error) {
      toast.error(getErrorMessage(error));
    } finally {
      setTogglingId(null);
    }
  }

  async function handleDelete() {
    if (!deleteTarget) return;
    setDeleteError(null);
    try {
      await deleteTier.mutateAsync(deleteTarget.id);
      toast.success(`Tier "${deleteTarget.display_name}" deleted`);
      setDeleteTarget(null);
    } catch (error) {
      setDeleteError(getErrorMessage(error));
    }
  }

  async function handleSeedDefaults() {
    try {
      await seedDefaults.mutateAsync();
      toast.success(t("admin.defaultTiersCreated"));
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={t("admin.tiers")}
        description={t("admin.tiersDesc")}
        actions={
          <Button onClick={handleCreate}>
            <Plus className="mr-2 h-4 w-4" aria-hidden="true" />
            Create Tier
          </Button>
        }
      />

      {tiers.isLoading && (
        <div className="space-y-2" role="status" aria-label="Loading tiers">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-16 w-full" />
          ))}
          <span className="sr-only">Loading tiers...</span>
        </div>
      )}

      {tiers.isError && (
        <ErrorState
          message="Failed to load tiers"
          onRetry={() => tiers.refetch()}
        />
      )}

      {tiers.data && tiers.data.length === 0 && (
        <EmptyState
          icon={Layers}
          title={t("admin.noTiers")}
          description={t("admin.noTiersDesc")}
          action={
            <Button onClick={handleSeedDefaults} disabled={seedDefaults.isPending}>
              {seedDefaults.isPending && (
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
              )}
              Seed Defaults
            </Button>
          }
        />
      )}

      {tiers.data && tiers.data.length > 0 && (
        <TierList
          tiers={tiers.data}
          onEdit={handleEdit}
          onToggleActive={handleToggleActive}
          onDelete={setDeleteTarget}
          togglingId={togglingId}
        />
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={deleteTarget !== null}
        onOpenChange={(open) => {
          if (!open) {
            setDeleteTarget(null);
            setDeleteError(null);
          }
        }}
      >
        <DialogContent className="max-h-[90dvh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{t("admin.deleteTier")}</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete &quot;{deleteTarget?.display_name}&quot;?
              This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          {deleteError && (
            <div
              className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive"
              role="alert"
            >
              {deleteError}
            </div>
          )}
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => {
                setDeleteTarget(null);
                setDeleteError(null);
              }}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleDelete}
              disabled={deleteTier.isPending}
            >
              {deleteTier.isPending && (
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
              )}
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
