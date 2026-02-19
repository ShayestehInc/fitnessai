import { DollarSign, TrendingUp, Users, Percent } from "lucide-react";
import { StatCard } from "@/components/dashboard/stat-card";
import type { AmbassadorDashboardData } from "@/types/ambassador";

interface DashboardEarningsCardProps {
  data: AmbassadorDashboardData;
}

function formatEarnings(value: string | number): string {
  const num = typeof value === "string" ? parseFloat(value) : value;
  if (isNaN(num)) return "$0.00";
  return `$${num.toFixed(2)}`;
}

function computeCurrentMonthEarnings(
  monthlyEarnings: { month: string; amount: string }[] | undefined,
): string {
  if (!monthlyEarnings || monthlyEarnings.length === 0) return "$0.00";
  const latest = monthlyEarnings[monthlyEarnings.length - 1];
  const num = parseFloat(latest.amount);
  if (isNaN(num)) return "$0.00";
  return `$${num.toFixed(2)}`;
}

export function DashboardEarningsCard({ data }: DashboardEarningsCardProps) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard
        title="Total Earnings"
        value={formatEarnings(data.total_earnings)}
        description="Lifetime commissions"
        icon={DollarSign}
        valueClassName="text-green-600"
      />
      <StatCard
        title="This Month"
        value={computeCurrentMonthEarnings(data.monthly_earnings)}
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
