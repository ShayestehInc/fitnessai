"use client";

import { useState } from "react";
import { format } from "date-fns";
import { Loader2 } from "lucide-react";
import { SlideOverPanel } from "@/components/ui/slide-over-panel";
import { Separator } from "@/components/ui/separator";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  useAdminSubscription,
  usePaymentHistory,
  useChangeHistory,
} from "@/hooks/use-admin-subscriptions";
import { formatCurrency } from "@/lib/format-utils";
import {
  SubscriptionActionForms,
  type ActionMode,
} from "@/components/admin/subscription-action-forms";
import {
  PaymentHistoryTab,
  ChangeHistoryTab,
} from "@/components/admin/subscription-history-tabs";

interface SubscriptionDetailPanelProps {
  subscriptionId: number | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function SubscriptionDetailPanel({
  subscriptionId,
  open,
  onOpenChange,
}: SubscriptionDetailPanelProps) {
  const subscription = useAdminSubscription(subscriptionId ?? 0);
  const payments = usePaymentHistory(subscriptionId ?? 0);
  const changes = useChangeHistory(subscriptionId ?? 0);
  const [actionMode, setActionMode] = useState<ActionMode>("none");

  const data = subscription.data;

  if (!subscriptionId) return null;

  return (
    <SlideOverPanel
      open={open}
      onOpenChange={onOpenChange}
      title={
        data
          ? `Subscription Detail - ${data.trainer.email}`
          : "Subscription Detail"
      }
      description={data ? `${data.tier} plan - ${data.status}` : "Loading..."}
      width="lg"
    >
      {subscription.isLoading && (
        <div className="flex items-center justify-center py-8" role="status" aria-label="Loading subscription details">
          <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" aria-hidden="true" />
          <span className="sr-only">Loading subscription details...</span>
        </div>
      )}

      {subscription.isError && (
        <div className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive" role="alert">
          Failed to load subscription details.{" "}
          <button
            onClick={() => subscription.refetch()}
            className="underline hover:no-underline"
          >
            Retry
          </button>
        </div>
      )}

      {data && (
        <Tabs defaultValue="overview">
          <div className="overflow-x-auto">
            <TabsList>
              <TabsTrigger value="overview">Overview</TabsTrigger>
              <TabsTrigger value="payments">Payments</TabsTrigger>
              <TabsTrigger value="changes">Changes</TabsTrigger>
            </TabsList>
          </div>

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
                  {data.status.replace(/_/g, " ")}
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
                  {data.max_trainees <= 0 ? "Unlimited" : data.max_trainees}
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

            <SubscriptionActionForms
              subscription={data}
              actionMode={actionMode}
              onActionChange={setActionMode}
            />
          </TabsContent>

          <TabsContent value="payments" className="space-y-4">
            <PaymentHistoryTab
              payments={payments.data}
              isLoading={payments.isLoading}
            />
          </TabsContent>

          <TabsContent value="changes" className="space-y-4">
            <ChangeHistoryTab
              changes={changes.data}
              isLoading={changes.isLoading}
            />
          </TabsContent>
        </Tabs>
      )}
    </SlideOverPanel>
  );
}
