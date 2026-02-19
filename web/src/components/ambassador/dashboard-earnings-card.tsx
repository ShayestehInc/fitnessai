import { DollarSign, TrendingUp, Users, Percent } from "lucide-react";
import { StatCard } from "@/components/dashboard/stat-card";
import type { AmbassadorDashboardData } from "@/types/ambassador";

interface DashboardEarningsCardProps {
  data: AmbassadorDashboardData;
}

export function DashboardEarningsCard({ data }: DashboardEarningsCardProps) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard
        title="Total Earnings"
        value={`$${(data.total_earnings ?? 0).toFixed(2)}`}
        description="Lifetime commissions"
        icon={DollarSign}
        valueClassName="text-green-600"
      />
      <StatCard
        title="This Month"
        value={`$${(data.monthly_earnings ?? 0).toFixed(2)}`}
        description="Earnings this month"
        icon={TrendingUp}
      />
      <StatCard
        title="Total Referrals"
        value={data.total_referrals ?? 0}
        description="Trainers referred"
        icon={Users}
      />
      <StatCard
        title="Commission Rate"
        value={`${data.commission_rate ?? 10}%`}
        description="Per referral"
        icon={Percent}
      />
    </div>
  );
}
