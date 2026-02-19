import { Skeleton } from "@/components/ui/skeleton";

export function AmbassadorDashboardSkeleton() {
  return (
    <div className="space-y-6">
      {/* Stat Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="rounded-lg border p-6">
            <div className="flex items-center justify-between">
              <Skeleton className="h-4 w-24" />
              <Skeleton className="h-4 w-4" />
            </div>
            <Skeleton className="mt-2 h-8 w-20" />
            <Skeleton className="mt-1 h-3 w-32" />
          </div>
        ))}
      </div>

      {/* Referral Code Card */}
      <div className="rounded-lg border p-6">
        <Skeleton className="h-5 w-32" />
        <Skeleton className="mt-4 h-12 w-full" />
      </div>

      {/* Chart */}
      <div className="rounded-lg border p-6">
        <Skeleton className="h-5 w-40" />
        <Skeleton className="mt-4 h-48 w-full" />
      </div>

      {/* Recent Referrals */}
      <div className="rounded-lg border p-6">
        <Skeleton className="h-5 w-36" />
        {[1, 2, 3].map((i) => (
          <Skeleton key={i} className="mt-3 h-14 w-full" />
        ))}
      </div>
    </div>
  );
}
