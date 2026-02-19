"use client";

import { useCallback } from "react";
import { Loader2, ExternalLink, CheckCircle, AlertCircle } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useAmbassadorConnectStatus, useAmbassadorConnectOnboard } from "@/hooks/use-ambassador";
import { getErrorMessage } from "@/lib/error-utils";
import { Skeleton } from "@/components/ui/skeleton";

export function StripeConnectSetup() {
  const { data, isLoading } = useAmbassadorConnectStatus();
  const onboardMutation = useAmbassadorConnectOnboard();

  const status = data as {
    is_connected?: boolean;
    charges_enabled?: boolean;
    payouts_enabled?: boolean;
    details_submitted?: boolean;
  } | undefined;

  const handleOnboard = useCallback(() => {
    onboardMutation.mutate(undefined, {
      onSuccess: (res) => {
        const url = (res as { url?: string })?.url;
        if (url) {
          window.location.href = url;
        }
      },
      onError: (err) => toast.error(getErrorMessage(err)),
    });
  }, [onboardMutation]);

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <Skeleton className="h-5 w-40" />
          <Skeleton className="h-4 w-56" />
        </CardHeader>
        <CardContent>
          <Skeleton className="h-20 w-full" />
        </CardContent>
      </Card>
    );
  }

  const isConnected = status?.is_connected;
  const payoutsEnabled = status?.payouts_enabled;

  return (
    <Card>
      <CardHeader>
        <CardTitle>Payout Account</CardTitle>
        <CardDescription>
          Connect your Stripe account to receive payouts
        </CardDescription>
      </CardHeader>
      <CardContent>
        {isConnected && payoutsEnabled ? (
          <div className="flex items-center gap-3 rounded-md bg-green-50 p-4 dark:bg-green-950/30">
            <CheckCircle className="h-5 w-5 text-green-600" />
            <div>
              <p className="text-sm font-medium text-green-800 dark:text-green-300">
                Stripe Connected
              </p>
              <p className="text-xs text-green-600 dark:text-green-400">
                Your account is set up to receive payouts
              </p>
            </div>
          </div>
        ) : isConnected && !payoutsEnabled ? (
          <div className="space-y-3">
            <div className="flex items-center gap-3 rounded-md bg-yellow-50 p-4 dark:bg-yellow-950/30">
              <AlertCircle className="h-5 w-5 text-yellow-600" />
              <div>
                <p className="text-sm font-medium text-yellow-800 dark:text-yellow-300">
                  Setup Incomplete
                </p>
                <p className="text-xs text-yellow-600 dark:text-yellow-400">
                  Your account needs additional information to enable payouts
                </p>
              </div>
            </div>
            <Button onClick={handleOnboard} disabled={onboardMutation.isPending}>
              {onboardMutation.isPending ? (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              ) : (
                <ExternalLink className="mr-2 h-4 w-4" />
              )}
              Complete Setup
            </Button>
          </div>
        ) : (
          <div className="space-y-3">
            <p className="text-sm text-muted-foreground">
              Connect your Stripe account to receive commission payouts directly
              to your bank account. This is required before you can receive any
              earnings.
            </p>
            <Button onClick={handleOnboard} disabled={onboardMutation.isPending}>
              {onboardMutation.isPending ? (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              ) : (
                <ExternalLink className="mr-2 h-4 w-4" />
              )}
              Connect Stripe Account
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
