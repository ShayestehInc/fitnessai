"use client";

import { useCallback } from "react";
import { CreditCard, CheckCircle, AlertCircle, ExternalLink } from "lucide-react";
import { toast } from "sonner";
import {
  useStripeConnectStatus,
  useStripeConnectOnboard,
  useTrainerPricing,
} from "@/hooks/use-subscription";
import { PageHeader } from "@/components/shared/page-header";
import { PageTransition } from "@/components/shared/page-transition";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { SubscriptionSkeleton } from "@/components/subscription/subscription-skeleton";
import { getErrorMessage } from "@/lib/error-utils";
import { formatCurrency } from "@/lib/format-utils";
import { useLocale } from "@/providers/locale-provider";

export default function SubscriptionPage() {
  const { t } = useLocale();
  const connectStatus = useStripeConnectStatus();
  const pricing = useTrainerPricing();
  const onboardMutation = useStripeConnectOnboard();

  const isLoading = connectStatus.isLoading || pricing.isLoading;
  const isError = connectStatus.isError || pricing.isError;

  const handleConnect = useCallback(() => {
    onboardMutation.mutate(undefined, {
      onSuccess: (data) => {
        window.open(data.url, "_blank");
      },
      onError: (err) => toast.error(getErrorMessage(err)),
    });
  }, [onboardMutation]);

  if (isLoading) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader title={t("nav.subscription")} description={t("subscription.description")} />
          <SubscriptionSkeleton />
        </div>
      </PageTransition>
    );
  }

  if (isError) {
    return (
      <PageTransition>
        <div className="space-y-6">
          <PageHeader title={t("nav.subscription")} description={t("subscription.description")} />
          <ErrorState
            message="Failed to load subscription data"
            onRetry={() => {
              connectStatus.refetch();
              pricing.refetch();
            }}
          />
        </div>
      </PageTransition>
    );
  }

  const status = connectStatus.data;
  const plan = pricing.data;
  const isConnected = status?.charges_enabled && status?.payouts_enabled;
  const isPending = status?.has_account && !status?.charges_enabled;

  return (
    <PageTransition>
      <div className="space-y-6">
        <PageHeader title={t("nav.subscription")} description={t("subscription.description")} />

        <div className="grid gap-6 lg:grid-cols-2">
          {/* Plan overview */}
          <Card>
            <CardHeader>
              <CardTitle>{t("subscription.currentPlan")}</CardTitle>
              <CardDescription>{t("subscription.details")}</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {plan ? (
                <>
                  <div className="flex items-baseline gap-2">
                    <span className="text-2xl font-bold">{plan.tier_name}</span>
                    <span className="text-lg text-muted-foreground">
                      {formatCurrency(plan.price)}/mo
                    </span>
                  </div>
                  {plan.next_payment_date && (
                    <p className="text-sm text-muted-foreground">
                      Next payment: {plan.next_payment_date}
                    </p>
                  )}
                  {Array.isArray(plan.features) && plan.features.length > 0 && (
                    <div className="space-y-1">
                      {plan.features.map((f) => (
                        <div key={f} className="flex items-center gap-2 text-sm">
                          <CheckCircle className="h-4 w-4 text-green-500" />
                          <span>{f}</span>
                        </div>
                      ))}
                    </div>
                  )}
                </>
              ) : (
                <EmptyState
                  icon={CreditCard}
                  title={t("subscription.noSubscription")}
                  description={t("subscription.noSubscriptionDesc")}
                />
              )}
            </CardContent>
          </Card>

          {/* Stripe Connect */}
          <Card>
            <CardHeader>
              <CardTitle>{t("subscription.stripeConnect")}</CardTitle>
              <CardDescription>{t("subscription.acceptPayments")}</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {isConnected ? (
                <div className="flex items-center gap-2">
                  <Badge className="bg-green-500 text-white">Connected</Badge>
                  <span className="text-sm text-muted-foreground">
                    Payments enabled
                  </span>
                </div>
              ) : isPending ? (
                <div className="flex items-center gap-2">
                  <Badge variant="secondary" className="bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-200">
                    Pending
                  </Badge>
                  <span className="text-sm text-muted-foreground">
                    Complete your Stripe verification
                  </span>
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  <AlertCircle className="h-5 w-5 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">
                    Set up Stripe to accept payments from trainees
                  </span>
                </div>
              )}

              <Button
                onClick={handleConnect}
                disabled={onboardMutation.isPending}
                variant={isConnected ? "outline" : "default"}
              >
                <ExternalLink className="mr-2 h-4 w-4" />
                {isConnected
                  ? "Open Stripe Dashboard"
                  : isPending
                    ? "Continue Setup"
                    : "Connect Stripe"}
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </PageTransition>
  );
}
