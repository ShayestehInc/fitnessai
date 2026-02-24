"use client";

import { useState } from "react";
import { format } from "date-fns";
import { Loader2, Shield, UserX } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import {
  useImpersonateTrainer,
  useActivateDeactivateTrainer,
} from "@/hooks/use-admin-trainers";
import {
  setImpersonationState,
} from "@/components/layout/impersonation-banner";
import { getAccessToken, getRefreshToken, setTokens } from "@/lib/token-manager";
import { toast } from "sonner";
import { getErrorMessage } from "@/lib/error-utils";
import { formatCurrency } from "@/lib/format-utils";
import type { AdminTrainerListItem } from "@/types/admin";

interface TrainerDetailDialogProps {
  trainer: AdminTrainerListItem | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function TrainerDetailDialog({
  trainer,
  open,
  onOpenChange,
}: TrainerDetailDialogProps) {
  const impersonate = useImpersonateTrainer();
  const toggleActive = useActivateDeactivateTrainer();
  const [showSuspendConfirm, setShowSuspendConfirm] = useState(false);

  if (!trainer) return null;

  const name =
    `${trainer.first_name} ${trainer.last_name}`.trim() || trainer.email;
  const sub = trainer.subscription;

  async function handleImpersonate() {
    if (!trainer) return;
    const currentAccess = getAccessToken();
    const currentRefresh = getRefreshToken();

    if (!currentAccess || !currentRefresh) {
      toast.error("Cannot impersonate: no active session");
      return;
    }

    try {
      const result = await impersonate.mutateAsync(trainer.id);
      setImpersonationState({
        adminAccessToken: currentAccess,
        adminRefreshToken: currentRefresh,
        trainerEmail: trainer.email,
      });
      setTokens(result.access, result.refresh, "TRAINER");
      onOpenChange(false);
      toast.success(`Now viewing as ${trainer.email}`);
      window.location.href = "/dashboard";
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  async function handleToggleActive() {
    if (!trainer) return;
    try {
      await toggleActive.mutateAsync({
        userId: trainer.id,
        isActive: !trainer.is_active,
      });
      toast.success(
        trainer.is_active
          ? `${name} has been suspended`
          : `${name} has been activated`,
      );
      setShowSuspendConfirm(false);
      onOpenChange(false);
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] max-w-md overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{name}</DialogTitle>
          <DialogDescription className="truncate">{trainer.email}</DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="flex items-center gap-2">
            <Badge variant={trainer.is_active ? "default" : "secondary"}>
              {trainer.is_active ? "Active" : "Inactive"}
            </Badge>
            {sub?.tier && (
              <Badge variant="outline">{sub.tier}</Badge>
            )}
          </div>

          <div className="grid grid-cols-2 gap-3 text-sm">
            <div>
              <p className="text-muted-foreground">Trainees</p>
              <p className="font-medium">{trainer.trainee_count}</p>
            </div>
            <div>
              <p className="text-muted-foreground">Joined</p>
              <p className="font-medium">
                {format(new Date(trainer.created_at), "MMM d, yyyy")}
              </p>
            </div>
          </div>

          {sub && (
            <>
              <Separator />
              <div className="space-y-2">
                <h4 className="text-sm font-semibold">Subscription</h4>
                <div className="grid grid-cols-2 gap-3 text-sm">
                  <div>
                    <p className="text-muted-foreground">Status</p>
                    <p className="font-medium capitalize">
                      {sub.status?.replace(/_/g, " ") ?? "N/A"}
                    </p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Next Payment</p>
                    <p className="font-medium">
                      {sub.next_payment_date
                        ? format(
                            new Date(sub.next_payment_date),
                            "MMM d, yyyy",
                          )
                        : "N/A"}
                    </p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Past Due</p>
                    <p className="font-medium">
                      {formatCurrency(sub.past_due_amount)}
                    </p>
                  </div>
                </div>
              </div>
            </>
          )}

          <Separator />

          <div className="flex flex-col gap-2">
            <Button
              onClick={handleImpersonate}
              disabled={impersonate.isPending}
              className="w-full"
            >
              {impersonate.isPending ? (
                <Loader2
                  className="mr-2 h-4 w-4 animate-spin"
                  aria-hidden="true"
                />
              ) : (
                <Shield className="mr-2 h-4 w-4" aria-hidden="true" />
              )}
              Impersonate Trainer
            </Button>

            {!showSuspendConfirm ? (
              <Button
                variant={trainer.is_active ? "destructive" : "outline"}
                onClick={() => {
                  if (trainer.is_active) {
                    setShowSuspendConfirm(true);
                  } else {
                    handleToggleActive();
                  }
                }}
                disabled={toggleActive.isPending}
                className="w-full"
              >
                {toggleActive.isPending ? (
                  <Loader2
                    className="mr-2 h-4 w-4 animate-spin"
                    aria-hidden="true"
                  />
                ) : (
                  <UserX className="mr-2 h-4 w-4" aria-hidden="true" />
                )}
                {trainer.is_active ? "Suspend Trainer" : "Activate Trainer"}
              </Button>
            ) : (
              <div className="rounded-md border border-destructive/20 bg-destructive/5 p-3">
                <p className="mb-2 text-sm text-destructive">
                  Are you sure you want to suspend {name}? They will lose
                  access to their dashboard.
                </p>
                <div className="flex flex-col gap-2 sm:flex-row">
                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={handleToggleActive}
                    disabled={toggleActive.isPending}
                  >
                    {toggleActive.isPending && (
                      <Loader2
                        className="mr-1 h-3 w-3 animate-spin"
                        aria-hidden="true"
                      />
                    )}
                    Confirm Suspend
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setShowSuspendConfirm(false)}
                  >
                    Cancel
                  </Button>
                </div>
              </div>
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
