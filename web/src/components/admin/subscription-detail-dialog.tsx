"use client";

import { useState } from "react";
import { format } from "date-fns";
import { Loader2 } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  useAdminSubscription,
  usePaymentHistory,
  useChangeHistory,
  useChangeTier,
  useChangeStatus,
  useRecordPayment,
  useUpdateNotes,
} from "@/hooks/use-admin-subscriptions";
import { DataTable } from "@/components/shared/data-table";
import type { Column } from "@/components/shared/data-table";
import { toast } from "sonner";
import { getErrorMessage } from "@/lib/error-utils";
import type { AdminPaymentHistory, AdminSubscriptionChange } from "@/types/admin";

interface SubscriptionDetailDialogProps {
  subscriptionId: number | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

function formatCurrency(value: string): string {
  const num = parseFloat(value);
  if (isNaN(num)) return "$0.00";
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(num);
}

const TIERS = ["FREE", "STARTER", "PRO", "ENTERPRISE"];
const STATUSES = ["active", "past_due", "canceled", "trialing", "suspended"];

const paymentColumns: Column<AdminPaymentHistory>[] = [
  {
    key: "date",
    header: "Date",
    cell: (row) => format(new Date(row.payment_date), "MMM d, yyyy"),
  },
  {
    key: "amount",
    header: "Amount",
    cell: (row) => formatCurrency(row.amount),
  },
  {
    key: "status",
    header: "Status",
    cell: (row) => (
      <Badge variant={row.status === "succeeded" ? "default" : "destructive"}>
        {row.status}
      </Badge>
    ),
  },
  {
    key: "description",
    header: "Description",
    cell: (row) => row.description || "--",
  },
];

const changeColumns: Column<AdminSubscriptionChange>[] = [
  {
    key: "date",
    header: "Date",
    cell: (row) => format(new Date(row.created_at), "MMM d, yyyy HH:mm"),
  },
  {
    key: "type",
    header: "Type",
    cell: (row) => <Badge variant="outline">{row.change_type}</Badge>,
  },
  {
    key: "details",
    header: "Details",
    cell: (row) => {
      if (row.from_tier && row.to_tier)
        return `${row.from_tier} -> ${row.to_tier}`;
      if (row.from_status && row.to_status)
        return `${row.from_status} -> ${row.to_status}`;
      return "--";
    },
  },
  {
    key: "by",
    header: "By",
    cell: (row) => row.changed_by_email || "System",
  },
  {
    key: "reason",
    header: "Reason",
    cell: (row) => row.reason || "--",
  },
];

export function SubscriptionDetailDialog({
  subscriptionId,
  open,
  onOpenChange,
}: SubscriptionDetailDialogProps) {
  const subscription = useAdminSubscription(subscriptionId ?? 0);
  const payments = usePaymentHistory(subscriptionId ?? 0);
  const changes = useChangeHistory(subscriptionId ?? 0);
  const changeTier = useChangeTier();
  const changeStatus = useChangeStatus();
  const recordPayment = useRecordPayment();
  const updateNotes = useUpdateNotes();

  const [actionMode, setActionMode] = useState<
    "none" | "tier" | "status" | "payment" | "notes"
  >("none");
  const [newTier, setNewTier] = useState("");
  const [newStatus, setNewStatus] = useState("");
  const [reason, setReason] = useState("");
  const [paymentAmount, setPaymentAmount] = useState("");
  const [paymentDescription, setPaymentDescription] = useState("");
  const [notesValue, setNotesValue] = useState("");
  const [notesCharCount, setNotesCharCount] = useState(0);

  const data = subscription.data;

  function resetAction() {
    setActionMode("none");
    setNewTier("");
    setNewStatus("");
    setReason("");
    setPaymentAmount("");
    setPaymentDescription("");
  }

  async function handleChangeTier() {
    if (!data || !newTier) return;
    try {
      await changeTier.mutateAsync({
        subscriptionId: data.id,
        new_tier: newTier,
        reason,
      });
      toast.success(`Tier changed to ${newTier}`);
      resetAction();
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  async function handleChangeStatus() {
    if (!data || !newStatus) return;
    try {
      await changeStatus.mutateAsync({
        subscriptionId: data.id,
        new_status: newStatus,
        reason,
      });
      toast.success(`Status changed to ${newStatus}`);
      resetAction();
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  async function handleRecordPayment() {
    if (!data || !paymentAmount) return;
    const amount = parseFloat(paymentAmount);
    if (isNaN(amount) || amount <= 0) {
      toast.error("Amount must be a positive number");
      return;
    }
    try {
      await recordPayment.mutateAsync({
        subscriptionId: data.id,
        amount: amount.toFixed(2),
        description: paymentDescription.trim() || "Manual payment",
      });
      toast.success(`Payment recorded (${formatCurrency(amount.toFixed(2))})`);
      resetAction();
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  async function handleSaveNotes() {
    if (!data) return;
    try {
      await updateNotes.mutateAsync({
        subscriptionId: data.id,
        admin_notes: notesValue,
      });
      toast.success("Notes saved");
      setActionMode("none");
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  }

  if (!subscriptionId) return null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>
            Subscription Detail
            {data && ` - ${data.trainer.email}`}
          </DialogTitle>
          <DialogDescription>
            {data ? `${data.tier} plan - ${data.status}` : "Loading..."}
          </DialogDescription>
        </DialogHeader>

        {subscription.isLoading && (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
          </div>
        )}

        {data && (
          <Tabs defaultValue="overview">
            <TabsList>
              <TabsTrigger value="overview">Overview</TabsTrigger>
              <TabsTrigger value="payments">Payments</TabsTrigger>
              <TabsTrigger value="changes">Changes</TabsTrigger>
            </TabsList>

            <TabsContent value="overview" className="space-y-4">
              <div className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-3">
                <div>
                  <p className="text-muted-foreground">Trainer</p>
                  <p className="font-medium">
                    {`${data.trainer.first_name} ${data.trainer.last_name}`.trim() ||
                      data.trainer.email}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Tier</p>
                  <p className="font-medium">{data.tier}</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Status</p>
                  <p className="font-medium capitalize">
                    {data.status.replace("_", " ")}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Monthly Price</p>
                  <p className="font-medium">
                    {formatCurrency(data.monthly_price)}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Next Payment</p>
                  <p className="font-medium">
                    {data.next_payment_date
                      ? format(
                          new Date(data.next_payment_date),
                          "MMM d, yyyy",
                        )
                      : "N/A"}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Past Due</p>
                  <p className="font-medium">
                    {formatCurrency(data.past_due_amount)}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Trainees</p>
                  <p className="font-medium">
                    {data.trainee_count} /{" "}
                    {data.max_trainees === -1 ? "Unlimited" : data.max_trainees}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Created</p>
                  <p className="font-medium">
                    {format(new Date(data.created_at), "MMM d, yyyy")}
                  </p>
                </div>
              </div>

              <Separator />

              {/* Action buttons */}
              <div className="flex flex-wrap gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    setActionMode("tier");
                    setNewTier(data.tier);
                  }}
                >
                  Change Tier
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    setActionMode("status");
                    setNewStatus(data.status);
                  }}
                >
                  Change Status
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setActionMode("payment")}
                >
                  Record Payment
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    setActionMode("notes");
                    setNotesValue(data.admin_notes);
                    setNotesCharCount(data.admin_notes.length);
                  }}
                >
                  Edit Notes
                </Button>
              </div>

              {/* Inline Action Forms */}
              {actionMode === "tier" && (
                <div className="rounded-md border p-3 space-y-3">
                  <Label htmlFor="new-tier">New Tier</Label>
                  <select
                    id="new-tier"
                    value={newTier}
                    onChange={(e) => setNewTier(e.target.value)}
                    className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm"
                  >
                    {TIERS.map((t) => (
                      <option key={t} value={t}>
                        {t}
                      </option>
                    ))}
                  </select>
                  <Label htmlFor="tier-reason">Reason</Label>
                  <Input
                    id="tier-reason"
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    placeholder="Reason for change"
                  />
                  <div className="flex gap-2">
                    <Button
                      size="sm"
                      onClick={handleChangeTier}
                      disabled={changeTier.isPending}
                    >
                      {changeTier.isPending && (
                        <Loader2
                          className="mr-1 h-3 w-3 animate-spin"
                          aria-hidden="true"
                        />
                      )}
                      Confirm
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={resetAction}
                    >
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
                    className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm"
                  >
                    {STATUSES.map((s) => (
                      <option key={s} value={s}>
                        {s.replace("_", " ")}
                      </option>
                    ))}
                  </select>
                  <Label htmlFor="status-reason">Reason</Label>
                  <Input
                    id="status-reason"
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    placeholder="Reason for change"
                  />
                  <div className="flex gap-2">
                    <Button
                      size="sm"
                      onClick={handleChangeStatus}
                      disabled={changeStatus.isPending}
                    >
                      {changeStatus.isPending && (
                        <Loader2
                          className="mr-1 h-3 w-3 animate-spin"
                          aria-hidden="true"
                        />
                      )}
                      Confirm
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={resetAction}
                    >
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
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={resetAction}
                    >
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
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setActionMode("none")}
                    >
                      Cancel
                    </Button>
                  </div>
                </div>
              )}

              {/* Admin Notes Display */}
              {actionMode !== "notes" && data.admin_notes && (
                <div className="rounded-md bg-muted/50 p-3">
                  <p className="mb-1 text-xs font-medium text-muted-foreground">
                    Admin Notes
                  </p>
                  <p className="text-sm whitespace-pre-wrap">
                    {data.admin_notes}
                  </p>
                </div>
              )}
            </TabsContent>

            <TabsContent value="payments" className="space-y-4">
              {payments.isLoading && (
                <div className="flex items-center justify-center py-4">
                  <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
                </div>
              )}
              {payments.data && payments.data.length === 0 && (
                <p className="text-sm text-muted-foreground">
                  No payment history
                </p>
              )}
              {payments.data && payments.data.length > 0 && (
                <DataTable
                  columns={paymentColumns}
                  data={payments.data}
                  keyExtractor={(row) => row.id}
                />
              )}
            </TabsContent>

            <TabsContent value="changes" className="space-y-4">
              {changes.isLoading && (
                <div className="flex items-center justify-center py-4">
                  <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
                </div>
              )}
              {changes.data && changes.data.length === 0 && (
                <p className="text-sm text-muted-foreground">
                  No change history
                </p>
              )}
              {changes.data && changes.data.length > 0 && (
                <DataTable
                  columns={changeColumns}
                  data={changes.data}
                  keyExtractor={(row) => row.id}
                />
              )}
            </TabsContent>
          </Tabs>
        )}
      </DialogContent>
    </Dialog>
  );
}
