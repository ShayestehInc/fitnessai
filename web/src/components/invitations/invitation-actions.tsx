"use client";

import { useState } from "react";
import { toast } from "sonner";
import { Copy, MoreHorizontal, RefreshCw, XCircle } from "lucide-react";
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

interface InvitationActionsProps {
  invitation: Invitation;
}

export function InvitationActions({ invitation }: InvitationActionsProps) {
  const resend = useResendInvitation();
  const cancel = useCancelInvitation();
  const [showCancelDialog, setShowCancelDialog] = useState(false);

  const status = invitation.is_expired && invitation.status === "PENDING"
    ? "EXPIRED"
    : invitation.status;

  const canResend = status === "PENDING" || status === "EXPIRED";
  const canCancel = status === "PENDING";

  const handleCopy = () => {
    navigator.clipboard.writeText(invitation.invitation_code).then(
      () => toast.success("Invitation code copied"),
      () => toast.error("Failed to copy code"),
    );
  };

  const handleResend = () => {
    resend.mutate(invitation.id, {
      onSuccess: () => toast.success("Invitation resent"),
      onError: () => toast.error("Failed to resend invitation"),
    });
  };

  const handleCancel = () => {
    cancel.mutate(invitation.id, {
      onSuccess: () => {
        toast.success("Invitation cancelled");
        setShowCancelDialog(false);
      },
      onError: () => toast.error("Failed to cancel invitation"),
    });
  };

  return (
    <>
      <DropdownMenu>
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
              onClick={() => setShowCancelDialog(true)}
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
              Cancel invitation
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
