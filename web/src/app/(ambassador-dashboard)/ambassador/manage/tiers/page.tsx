"use client";

import { Layers } from "lucide-react";
import { useAmbassadorAdminTiers } from "@/hooks/use-ambassador-admin-tiers";
import { PageHeader } from "@/components/shared/page-header";
import { ErrorState } from "@/components/shared/error-state";
import { EmptyState } from "@/components/shared/empty-state";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { TIER_COLORS } from "@/lib/admin-constants";
import type { AdminSubscriptionTier } from "@/types/admin";

function formatPrice(price: string | number): string {
  const num = typeof price === "string" ? parseFloat(price) : price;
  return num === 0 ? "Free" : `$${num.toFixed(2)}/mo`;
}

export default function AmbassadorTiersPage() {
  const tiers = useAmbassadorAdminTiers();

  return (
    <div className="space-y-6">
      <PageHeader
        title="Subscription Tiers"
        description="Available platform subscription tiers (read-only)"
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
          title="No tiers available"
          description="No subscription tiers have been configured yet."
        />
      )}

      {tiers.data && tiers.data.length > 0 && (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Price</TableHead>
                <TableHead>Trainee Limit</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Features</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {tiers.data.map((tier: AdminSubscriptionTier) => (
                <TableRow key={tier.id}>
                  <TableCell>
                    <Badge
                      variant="secondary"
                      className={
                        TIER_COLORS[
                          tier.name as keyof typeof TIER_COLORS
                        ] ?? ""
                      }
                    >
                      {tier.display_name}
                    </Badge>
                  </TableCell>
                  <TableCell>{formatPrice(tier.price)}</TableCell>
                  <TableCell>{tier.trainee_limit_display}</TableCell>
                  <TableCell>
                    <Badge
                      variant={tier.is_active ? "default" : "secondary"}
                    >
                      {tier.is_active ? "Active" : "Inactive"}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex flex-wrap gap-1">
                      {tier.features.slice(0, 3).map((f: string) => (
                        <span
                          key={f}
                          className="text-xs text-muted-foreground"
                        >
                          {f}
                          {tier.features.indexOf(f) < 2 &&
                          tier.features.indexOf(f) <
                            tier.features.length - 1
                            ? ","
                            : ""}
                        </span>
                      ))}
                      {tier.features.length > 3 && (
                        <span className="text-xs text-muted-foreground">
                          +{tier.features.length - 3} more
                        </span>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  );
}
