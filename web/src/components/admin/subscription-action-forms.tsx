"use client";

import { useState } from "react";
import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  useChangeTier,
  useChangeStatus,
  useRecordPayment,
  useUpdateNotes,
} from "@/hooks/use-admin-subscriptions";
import { toast } from "sonner";
import { getErrorMessage } from "@/lib/error-utils";
import { formatCurrency } from "@/lib/format-utils";
import { SELECT_CLASSES_FULL_WIDTH } from "@/lib/admin-constants";
import type { AdminSubscription } from "@/types/admin";

const TIERS = ["FREE", "STARTER", "PRO", "ENTERPRISE"];
const STATUSES = ["active", "past_due", "canceled", "trialing", "suspended"];

export type ActionMode = "none" | "tier" | "status" | "payment" | "notes";

interface ActionFormsProps {
  subscription: AdminSubscription;
  actionMode: ActionMode;
  onActionChange: (mode: ActionMode) => void;
}

export function SubscriptionActionForms({
  subscription,
  actionMode,
  onActionChange,
}: ActionFormsProps) {
  const changeTier = useChangeTier();
  const changeStatus = useChangeStatus();
  const recordPayment = useRecordPayment();
  const updateNotes = useUpdateNotes();

  const [newTier, setNewTier] = useState(subscription.tier);
  const [newStatus, setNewStatus] = useState(subscription.status);
  const [reason, setReason] = useState("");
  const [paymentAmount, setPaymentAmount] = useState("");
  const [paymentDescription, setPaymentDescription] = useState("");
  const [notesValue, setNotesValue] = useState(subscription.admin_notes);
  const [notesCharCount, setNotesCharCount] = useState(
    subscription.admin_notes.length,
  );

  function resetAndClose() {
    setNewTier(subscription.tier);
    setNewStatus(subscription.status);
    setReason("");
    setPaymentAmount("");
    setPaymentDescription("");
    setNotesValue(subscription.admin_notes);
    setNotesCharCount(subscription.admin_notes.length);
    onActionChange("none");
  }

  function openAction(mode: ActionMode) {
    resetAndClose();
    if (mode === "tier") setNewTier(subscription.tier);
    if (mode === "status") setNewStatus(subscription.status);
    if (mode === "notes") {
      setNotesValue(subscription.admin_notes);
      setNotesCharCount(subscription.admin_notes.length);
    }
    onActionChange(mode);
  }

  async function handleChangeTier() {
    if (!newTier) return;
    if (newTier === subscription.tier) {
      toast.error("Please select a different tier");
      return;
    }
    try {
      await changeTier.mutateAsync({
        subscriptionId: subscription.id,
        new_tier: newTier,
        reason,
      });
      toast.success(`Tier changed to ${newTier}`);
      resetAndClose();
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  async function handleChangeStatus() {
    if (!newStatus) return;
    if (newStatus === subscription.status) {
      toast.error("Please select a different status");
      return;
    }
    try {
      await changeStatus.mutateAsync({
        subscriptionId: subscription.id,
        new_status: newStatus,
        reason,
      });
      toast.success(`Status changed to ${newStatus}`);
      resetAndClose();
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  async function handleRecordPayment() {
    if (!paymentAmount) return;
    const amount = parseFloat(paymentAmount);
    if (isNaN(amount) || amount <= 0) {
      toast.error("Amount must be a positive number");
      return;
    }
    try {
      await recordPayment.mutateAsync({
        subscriptionId: subscription.id,
        amount: amount.toFixed(2),
        description: paymentDescription.trim() || "Manual payment",
      });
      toast.success(`Payment recorded (${formatCurrency(amount.toFixed(2))})`);
      resetAndClose();
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  async function handleSaveNotes() {
    try {
      await updateNotes.mutateAsync({
        subscriptionId: subscription.id,
        admin_notes: notesValue,
      });
      toast.success("Notes saved");
      resetAndClose();
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  return (
    <>
      <div className="flex flex-wrap gap-2">
        <Button
          variant="outline"
          size="sm"
          onClick={() => openAction("tier")}
        >
          Change Tier
        </Button>
        <Button
          variant="outline"
          size="sm"
          onClick={() => openAction("status")}
        >
          Change Status
        </Button>
        <Button
          variant="outline"
          size="sm"
          onClick={() => openAction("payment")}
        >
          Record Payment
        </Button>
        <Button
          variant="outline"
          size="sm"
          onClick={() => openAction("notes")}
        >
          Edit Notes
        </Button>
      </div>

      {actionMode === "tier" && (
        <div className="rounded-md border p-3 space-y-3">
          <Label htmlFor="new-tier">New Tier</Label>
          <select
            id="new-tier"
            value={newTier}
            onChange={(e) => setNewTier(e.target.value)}
            className={SELECT_CLASSES_FULL_WIDTH}
          >
            {TIERS.map((t) => (
              <option key={t} value={t}>
                {t}{t === subscription.tier ? " (current)" : ""}
              </option>
            ))}
          </select>
          {newTier === subscription.tier && (
            <p className="text-xs text-muted-foreground">
              Select a different tier to make a change.
            </p>
          )}
          <Label htmlFor="tier-reason">Reason</Label>
          <textarea
            id="tier-reason"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="Reason for change"
            rows={2}
            className="flex w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          />
          <div className="flex gap-2">
            <Button
              size="sm"
              onClick={handleChangeTier}
              disabled={changeTier.isPending || newTier === subscription.tier}
            >
              {changeTier.isPending && (
                <Loader2
                  className="mr-1 h-3 w-3 animate-spin"
                  aria-hidden="true"
                />
              )}
              Confirm
            </Button>
            <Button variant="outline" size="sm" onClick={resetAndClose}>
              Cancel
            </Button>
          </div>
        </div>
      )}

      {actionMode === "status" && (
        <div className="rounded-md border p-3 space-y-3">
          <Label htmlFor="new-status">New Status</Label>
          <select
            id="new-status"
            value={newStatus}
            onChange={(e) => setNewStatus(e.target.value)}
            className={SELECT_CLASSES_FULL_WIDTH}
          >
            {STATUSES.map((s) => (
              <option key={s} value={s}>
                {s.replace(/_/g, " ")}{s === subscription.status ? " (current)" : ""}
              </option>
            ))}
          </select>
          {newStatus === subscription.status && (
            <p className="text-xs text-muted-foreground">
              Select a different status to make a change.
            </p>
          )}
          <Label htmlFor="status-reason">Reason</Label>
          <textarea
            id="status-reason"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="Reason for change"
            rows={2}
            className="flex w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          />
          <div className="flex gap-2">
            <Button
              size="sm"
              onClick={handleChangeStatus}
              disabled={changeStatus.isPending || newStatus === subscription.status}
            >
              {changeStatus.isPending && (
                <Loader2
                  className="mr-1 h-3 w-3 animate-spin"
                  aria-hidden="true"
                />
              )}
              Confirm
            </Button>
            <Button variant="outline" size="sm" onClick={resetAndClose}>
              Cancel
            </Button>
          </div>
        </div>
      )}

      {actionMode === "payment" && (
        <div className="rounded-md border p-3 space-y-3">
          <Label htmlFor="payment-amount">Amount ($)</Label>
          <Input
            id="payment-amount"
            type="number"
            min="0.01"
            step="0.01"
            value={paymentAmount}
            onChange={(e) => setPaymentAmount(e.target.value)}
            placeholder="79.00"
          />
          <Label htmlFor="payment-desc">Description</Label>
          <Input
            id="payment-desc"
            value={paymentDescription}
            onChange={(e) => setPaymentDescription(e.target.value)}
            placeholder="Manual payment"
          />
          <div className="flex gap-2">
            <Button
              size="sm"
              onClick={handleRecordPayment}
              disabled={recordPayment.isPending}
            >
              {recordPayment.isPending && (
                <Loader2
                  className="mr-1 h-3 w-3 animate-spin"
                  aria-hidden="true"
                />
              )}
              Record
            </Button>
            <Button variant="outline" size="sm" onClick={resetAndClose}>
              Cancel
            </Button>
          </div>
        </div>
      )}

      {actionMode === "notes" && (
        <div className="rounded-md border p-3 space-y-3">
          <Label htmlFor="admin-notes">Admin Notes</Label>
          <textarea
            id="admin-notes"
            value={notesValue}
            onChange={(e) => {
              const value = e.target.value.slice(0, 2000);
              setNotesValue(value);
              setNotesCharCount(value.length);
            }}
            maxLength={2000}
            rows={4}
            className="flex w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            placeholder="Internal notes about this subscription..."
          />
          <p className="text-xs text-muted-foreground">
            {notesCharCount}/2000
          </p>
          <div className="flex gap-2">
            <Button
              size="sm"
              onClick={handleSaveNotes}
              disabled={updateNotes.isPending}
            >
              {updateNotes.isPending && (
                <Loader2
                  className="mr-1 h-3 w-3 animate-spin"
                  aria-hidden="true"
                />
              )}
              Save Notes
            </Button>
            <Button variant="outline" size="sm" onClick={resetAndClose}>
              Cancel
            </Button>
          </div>
        </div>
      )}

      {actionMode !== "notes" && subscription.admin_notes && (
        <div className="rounded-md bg-muted/50 p-3">
          <p className="mb-1 text-xs font-medium text-muted-foreground">
            Admin Notes
          </p>
          <p className="text-sm whitespace-pre-wrap">
            {subscription.admin_notes}
          </p>
        </div>
      )}
    </>
  );
}
