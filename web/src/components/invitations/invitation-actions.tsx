"use client";

import { useState } from "react";
import { toast } from "sonner";
import { Copy, Loader2, MoreHorizontal, RefreshCw, XCircle } from "lucide-react";
import {
  useResendInvitation,
  useCancelInvitation,
} from "@/hooks/use-invitations";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { Invitation } from "@/types/invitation";
import { useLocale } from "@/providers/locale-provider";

interface InvitationActionsProps {
  invitation: Invitation;
}

export function InvitationActions({ invitation }: InvitationActionsProps) {
  const { t } = useLocale();
  const resend = useResendInvitation();
  const cancel = useCancelInvitation();
  const [showCancelDialog, setShowCancelDialog] = useState(false);
  const [dropdownOpen, setDropdownOpen] = useState(false);

  // Backend keeps status=PENDING even after expiration; is_expired flag distinguishes
  const status = invitation.is_expired && invitation.status === "PENDING"
    ? "EXPIRED"
    : invitation.status;

  const canResend = status === "PENDING" || status === "EXPIRED";
  const canCancel = status === "PENDING";

  const handleCopy = () => {
    setDropdownOpen(false);
    try {
      navigator.clipboard.writeText(invitation.invitation_code).then(
        () => toast.success(t("invitations.codeCopied")),
        () => toast.error(t("invitations.failedToCopyCode")),
      );
    } catch {
      toast.error(t("invitations.failedToCopyCode"));
    }
  };

  const handleResend = () => {
    setDropdownOpen(false);
    resend.mutate(invitation.id, {
      onSuccess: () => toast.success(t("invitations.resent")),
      onError: () => toast.error(t("invitations.failedToResend")),
    });
  };

  const handleCancel = () => {
    cancel.mutate(invitation.id, {
      onSuccess: () => {
        toast.success(t("invitations.cancelled"));
        setShowCancelDialog(false);
      },
      onError: () => toast.error(t("invitations.failedToCancel")),
    });
  };

  return (
    <>
      <DropdownMenu open={dropdownOpen} onOpenChange={setDropdownOpen}>
        <DropdownMenuTrigger asChild>
          <Button
            variant="ghost"
            size="sm"
            className="h-8 w-8 p-0"
            aria-label="Invitation actions"
          >
            <MoreHorizontal className="h-4 w-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem onClick={handleCopy}>
            <Copy className="mr-2 h-4 w-4" aria-hidden="true" />
            Copy Code
          </DropdownMenuItem>
          {canResend && (
            <DropdownMenuItem
              onClick={handleResend}
              disabled={resend.isPending}
            >
              <RefreshCw className="mr-2 h-4 w-4" aria-hidden="true" />
              Resend
            </DropdownMenuItem>
          )}
          {canCancel && (
            <DropdownMenuItem
              onClick={() => {
                setDropdownOpen(false);
                setShowCancelDialog(true);
              }}
              className="text-destructive focus:text-destructive"
            >
              <XCircle className="mr-2 h-4 w-4" aria-hidden="true" />
              Cancel
            </DropdownMenuItem>
          )}
        </DropdownMenuContent>
      </DropdownMenu>

      <Dialog open={showCancelDialog} onOpenChange={setShowCancelDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Cancel invitation?</DialogTitle>
            <DialogDescription>
              This will cancel the invitation sent to{" "}
              <strong>{invitation.email}</strong>. They will no longer be able
              to use this invitation code to sign up.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowCancelDialog(false)}
            >
              Keep invitation
            </Button>
            <Button
              variant="destructive"
              onClick={handleCancel}
              disabled={cancel.isPending}
            >
              {cancel.isPending && (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
              )}
              Cancel invitation
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
