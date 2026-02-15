import { Users, Activity, Target, UserPlus } from "lucide-react";
import type { DashboardStats } from "@/types/trainer";
import { StatCard } from "./stat-card";

interface StatsCardsProps {
  stats: DashboardStats;
}

export function StatsCards({ stats }: StatsCardsProps) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard
        title="Total Trainees"
        value={stats.total_trainees}
        description={`${stats.max_trainees === -1 ? "Unlimited" : stats.max_trainees} max on ${stats.subscription_tier === "NONE" ? "Free" : stats.subscription_tier} plan`}
        icon={Users}
      />
      <StatCard
        title="Active Today"
        value={stats.trainees_logged_today}
        description={`${stats.active_trainees} active overall`}
        icon={Activity}
      />
      <StatCard
        title="On Track"
        value={stats.trainees_on_track}
        description={`${Math.round(stats.avg_adherence_rate)}% avg adherence`}
        icon={Target}
      />
      <StatCard
        title="Pending Onboarding"
        value={stats.trainees_pending_onboarding}
        description="Awaiting profile completion"
        icon={UserPlus}
      />
    </div>
  );
}
