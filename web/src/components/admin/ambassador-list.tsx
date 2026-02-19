"use client";

import { useState } from "react";
import { format } from "date-fns";
import { Plus, Search, DollarSign, Users, Eye } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/shared/empty-state";
import { Skeleton } from "@/components/ui/skeleton";
import { useAdminAmbassadors } from "@/hooks/use-admin-ambassadors";
import { formatCurrency } from "@/lib/format-utils";
import { CreateAmbassadorDialog } from "./create-ambassador-dialog";
import { AmbassadorDetailDialog } from "./ambassador-detail-dialog";
import type { Ambassador } from "@/types/ambassador";

export function AmbassadorList() {
  const [search, setSearch] = useState("");
  const [createOpen, setCreateOpen] = useState(false);
  const [selectedAmbassador, setSelectedAmbassador] = useState<Ambassador | null>(null);
  const [detailOpen, setDetailOpen] = useState(false);

  const { data, isLoading } = useAdminAmbassadors();

  const ambassadors = (data ?? []) as Ambassador[];
  const filtered = search
    ? ambassadors.filter(
        (a) =>
          a.user_email.toLowerCase().includes(search.toLowerCase()) ||
          (a.referral_code ?? "").toLowerCase().includes(search.toLowerCase()),
      )
    : ambassadors;

  if (isLoading) {
    return (
      <div className="space-y-4">
        <div className="flex items-center justify-between gap-3">
          <Skeleton className="h-10 w-64" />
          <Skeleton className="h-10 w-36" />
        </div>
        {[1, 2, 3].map((i) => (
          <Skeleton key={i} className="h-20 w-full" />
        ))}
      </div>
    );
  }

  return (
    <>
      <div className="space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="relative flex-1 sm:max-w-sm">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search ambassadors..."
              className="pl-9"
            />
          </div>
          <Button onClick={() => setCreateOpen(true)}>
            <Plus className="mr-2 h-4 w-4" />
            Add Ambassador
          </Button>
        </div>

        {filtered.length === 0 ? (
          <EmptyState
            icon={Users}
            title={search ? "No ambassadors match your search" : "No ambassadors yet"}
            description={
              search
                ? "Try adjusting your search."
                : "Add your first ambassador to start a referral program."
            }
            action={
              !search ? (
                <Button onClick={() => setCreateOpen(true)}>
                  <Plus className="mr-2 h-4 w-4" />
                  Add Ambassador
                </Button>
              ) : undefined
            }
          />
        ) : (
          <div className="space-y-3">
            {filtered.map((ambassador) => (
              <div
                key={ambassador.id}
                className="flex items-center justify-between gap-4 rounded-lg border p-4 transition-colors hover:bg-accent/50"
              >
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <p className="truncate text-sm font-medium">
                      {ambassador.user_email}
                    </p>
                    <Badge
                      variant={ambassador.is_active ? "default" : "secondary"}
                    >
                      {ambassador.is_active ? "Active" : "Inactive"}
                    </Badge>
                  </div>
                  <div className="mt-1 flex items-center gap-4 text-xs text-muted-foreground">
                    <span>Code: {ambassador.referral_code ?? "N/A"}</span>
                    <span>
                      Commission: {ambassador.commission_rate ?? 10}%
                    </span>
                    <span>
                      Referrals: {ambassador.total_referrals ?? 0}
                    </span>
                    {ambassador.created_at && (
                      <span>
                        Since{" "}
                        {format(new Date(ambassador.created_at), "MMM d, yyyy")}
                      </span>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-sm font-medium text-green-600">
                    {formatCurrency(ambassador.total_earnings ?? 0)}
                  </span>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => {
                      setSelectedAmbassador(ambassador);
                      setDetailOpen(true);
                    }}
                  >
                    <Eye className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <CreateAmbassadorDialog open={createOpen} onOpenChange={setCreateOpen} />
      <AmbassadorDetailDialog
        ambassador={selectedAmbassador}
        open={detailOpen}
        onOpenChange={setDetailOpen}
      />
    </>
  );
}
